import 'package:flutter/material.dart';

import 'chat_service.dart';

const appTitle = 'On-Device LLM';

final service = ChatService();

/// メッセージ
class _MessageEntry {
  const _MessageEntry(this.text, {required this.isUser});

  final bool isUser;
  final String text;
}

/// アプリケーションエントリ
void main() {
  runApp(const AppWidget());
}

/// メインウィジェット
class AppWidget extends StatefulWidget {
  const AppWidget({super.key});

  @override
  State<AppWidget> createState() => _AppWidgetState();
}

class _AppWidgetState extends State<AppWidget> {
  bool _initializing = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  /// 初期化
  Future<void> _initialize() async {
    await service.initialize();
    setState(() => _initializing = false);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appTitle,
      home: Scaffold(
        appBar: AppBar(title: const Text(appTitle)),
        body: _initializing
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(child: _Chat()),
      ),
    );
  }
}

/// チャット画面
class _Chat extends StatefulWidget {
  const _Chat();

  @override
  State<_Chat> createState() => _ChatState();
}

class _ChatState extends State<_Chat> {
  /// メッセージ一覧
  final List<_MessageEntry> _messages = [];

  /// 応答中かどうか
  bool _responding = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final color = index & 1 == 0
                    ? Colors.blue[50]
                    : Colors.green[50];

                final msg = _messages[index];
                final respondingMessage =
                    _responding && index == _messages.length - 1;

                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: respondingMessage
                      ? Center(child: CircularProgressIndicator())
                      : Text(
                          msg.text,
                          textAlign: msg.isUser
                              ? TextAlign.right
                              : TextAlign.left,
                        ),
                );
              },
            ),
          ),

          _Form(enabled: !_responding, onSubmit: _sendMessage),
        ],
      ),
    );
  }

  /// メッセージ送信
  Future<void> _sendMessage(String text) async {
    final validMessage = text.trim();
    if (validMessage.isEmpty) {
      return;
    }

    setState(() => _responding = true);

    _messages.add(_MessageEntry(validMessage, isUser: true));
    _messages.add(_MessageEntry('', isUser: false));

    final buffer = StringBuffer();

    await for (final res in service.sendMessage(validMessage)) {
      buffer.write(res);
      setState(() {
        final index = _messages.length - 1;
        _messages[index] = _MessageEntry(buffer.toString(), isUser: false);
      });
    }
    setState(() => _responding = false);
  }
}

/// メッセージ入力フォーム
class _Form extends StatefulWidget {
  const _Form({required this.enabled, required this.onSubmit});

  final bool enabled;
  final ValueChanged<String> onSubmit;

  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(enabled: widget.enabled, controller: _controller),
        ),
        IconButton(
          icon: const Icon(Icons.send),
          onPressed: !widget.enabled
              ? null
              : () {
                  final text = _controller.text;
                  if (text.isEmpty) return;
                  widget.onSubmit(text);
                  _controller.clear();
                },
        ),
      ],
    );
  }
}
