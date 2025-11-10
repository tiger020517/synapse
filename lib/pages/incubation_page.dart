import 'dart:math';
import 'package:flutter/material.dart';

class IncubationPage extends StatefulWidget {
  @override
  _IncubationPageState createState() => _IncubationPageState();
}

class _IncubationPageState extends State<IncubationPage> {
  final List<String> _sampleTexts = [
    "The quick brown fox jumps over the lazy dog.",
    "Flutter makes app development fast and beautiful.",
    "Incubation helps solve complex problems.",
    "This is a simple typing test for your mind.",
    "Just keep typing without thinking too much.",
  ];

  late String _currentText;
  final TextEditingController _controller = TextEditingController();
  String _inputText = "";

  @override
  void initState() {
    super.initState();
    _loadNextText();
    _controller.addListener(() {
      _onInputChanged(_controller.text);
    });
  }

  void _loadNextText() {
    setState(() {
      _currentText = _sampleTexts[Random().nextInt(_sampleTexts.length)];
      _inputText = "";
      _controller.clear();
    });
  }

  void _onInputChanged(String value) {
    setState(() {
      _inputText = value;
    });
    if (value == _currentText) {
      Future.delayed(Duration(milliseconds: 500), () {
        _loadNextText();
      });
    }
  }

  Widget _buildProblemText() {
    List<TextSpan> spans = [];
    for (int i = 0; i < _currentText.length; i++) {
      Color color = Colors.grey;
      if (i < _inputText.length) {
        color = (_inputText[i] == _currentText[i]) ? Colors.green : Colors.red;
      }
      spans.add(TextSpan(
        text: _currentText[i],
        style: TextStyle(color: color, fontSize: 22, fontFamily: 'monospace'),
      ));
    }
    return RichText(
      text: TextSpan(
        style: DefaultTextStyle.of(context).style,
        children: spans,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('집중 휴식 (타자연습)'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadNextText,
            tooltip: '다음 문장',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildProblemText(),
            SizedBox(height: 24),
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: '여기에 입력하세요...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}