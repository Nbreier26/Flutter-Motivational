import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:convert';
import 'dart:async';

void main() => runApp(const MotivacionalApp());

class MotivacionalApp extends StatelessWidget {
  const MotivacionalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
      ),
      home: const FrasesScreen(),
    );
  }
}

class FrasesScreen extends StatefulWidget {
  const FrasesScreen({super.key});

  @override
  State<FrasesScreen> createState() => _FrasesScreenState();
}

class _FrasesScreenState extends State<FrasesScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _mensagens = [];
  bool _modoMotivacional = true;
  late Timer _colorTimer;
  double _hue = 0.0;
  late AnimationController _animationController;
  bool _carregando = false;

  // Reconhecimento de voz
  late stt.SpeechToText _speech;
  bool _isListening = false;

  // 👈 Substitua pela sua chave de API
  final String _apiKey = '';

  @override
  void initState() {
    super.initState();
    // Animação de título
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Timer para mudar cor
    _colorTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      setState(() => _hue = (_hue + 3) % 360);
    });

    // Inicializa o SpeechToText
    _speech = stt.SpeechToText();
  }

  Color get _currentColor =>
      HSLColor.fromAHSL(1, _hue, 1, 0.5).toColor();
  Color get _complementaryColor =>
      HSLColor.fromAHSL(1, (_hue + 180) % 360, 1, 0.5).toColor();

  void _toggleModo() {
    setState(() => _modoMotivacional = !_modoMotivacional);
  }

  Future<String> _getGeminiResponse(String input) async {
    setState(() => _carregando = true);
    try {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=$_apiKey',
      );
      final systemPrompt = _modoMotivacional
          ? "Crie uma frase MOTIVACIONAL ultra exagerada com: 🔥 EMOJIS BRILHANTES a cada 3 palavras • 🌟 METÁFORAS EPICAS • 🚀 FRASES EM CAPSLOCK • TON POSITIVO EXTREMO!"
          : "Crie uma frase DESMOTIVACIONAL com: 💀 HUMOR NEGRO • ☠️ EMOJIS MACABROS • 🌧️ COMPARAÇÕES DEPRESSIVAS • TON CÍNICO E IRÔNICO!";
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": "$systemPrompt\nInput: $input"}
              ]
            }
          ],
          "generationConfig": {
            "temperature": _modoMotivacional ? 1.0 : 1.5,
            "maxOutputTokens": 150
          }
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'] ?? '...';
      } else {
        return 'ERRO: ${response.statusCode}';
      }
    } catch (e) {
      return 'FALHA NA CONEXÃO!';
    } finally {
      setState(() => _carregando = false);
    }
  }

  void _enviarMensagem() async {
    if (_controller.text.isEmpty || _carregando) return;
    final mensagem = _controller.text;
    _controller.clear();
    setState(() => _mensagens.add({'texto': mensagem, 'isUser': true}));
    final resposta = await _getGeminiResponse(mensagem);
    setState(() => _mensagens.add({'texto': resposta, 'isUser': false}));
  }

  /// Lógica de “falar para digitar”
  Future<void> _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) => print('onStatus: $val'),
        onError: (val) => print('onError: $val'),
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) {
            setState(() {
              _controller.text = val.recognizedWords;
            });
          },
          localeId: 'pt_BR',
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  @override
  void dispose() {
    _colorTimer.cancel();
    _animationController.dispose();
    _controller.dispose();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reversedMessages = _mensagens.reversed.toList();
    return Scaffold(
      appBar: AppBar(
        title: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) => Text(
            _modoMotivacional
                ? '💥 SUPER MOTIVAÇÃO 💥'
                : '☠️ DESMOTIVAÇÃO TOTAL ☠️',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              foreground: Paint()
                ..shader = LinearGradient(
                  colors: [_currentColor, _complementaryColor],
                ).createShader(const Rect.fromLTWH(0, 0, 300, 20)),
            ),
          ),
        ),
        backgroundColor: Colors.black,
        centerTitle: true,
        actions: [
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: _modoMotivacional
                  ? Text(
                      '🌈',
                      key: const ValueKey('motivacional'),
                      style: TextStyle(
                        fontSize: 30,
                        shadows: [Shadow(color: _currentColor, blurRadius: 20)],
                      ),
                    )
                  : Text(
                      '⚰️',
                      key: const ValueKey('desmotivacional'),
                      style: TextStyle(
                        fontSize: 30,
                        shadows: [Shadow(color: _complementaryColor, blurRadius: 20)],
                      ),
                    ),
            ),
            onPressed: _toggleModo,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [Colors.black, _currentColor.withOpacity(0.1)],
            stops: const [0.5, 1.0],
            radius: 1.5,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                reverse: true,
                itemCount: reversedMessages.length,
                itemBuilder: (context, index) {
                  final msg = reversedMessages[index];
                  return _ChatBubble(
                    text: msg['texto'],
                    isUser: msg['isUser'],
                    color: _currentColor,
                  );
                },
              ),
            ),
            if (_carregando)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
              ),
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: LinearGradient(
                  colors: [
                    _currentColor.withOpacity(0.3),
                    _complementaryColor.withOpacity(0.3)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _currentColor.withOpacity(0.5),
                    blurRadius: 15,
                    spreadRadius: 2,
                  )
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: Colors.white,
                    ),
                    onPressed: _listen,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: _modoMotivacional
                            ? 'Digite algo para HIPER MOTIVAR... 🚀'
                            : 'Escreva algo para DESANIMAR... 💀',
                        hintStyle: const TextStyle(color: Colors.white70),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.only(left: 0, right: 10),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _enviarMensagem,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final Color color;

  const _ChatBubble({
    required this.text,
    required this.isUser,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUser ? Colors.transparent : color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: isUser ? Border.all(color: color, width: 2) : null,
        boxShadow: [
          if (!isUser)
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              spreadRadius: 2,
            )
        ],
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          color: isUser ? color : Colors.white,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: color.withOpacity(0.5), blurRadius: 10)],
        ),
      ),
    );
  }
}
