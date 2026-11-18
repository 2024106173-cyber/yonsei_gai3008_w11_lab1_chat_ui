import 'dart:math' as math;

import 'package:flutter/material.dart';

// GAI3008 11주차 · 실습 1: 채팅 UI (TODO 2~5)
// 기존 스타터의 ListView.builder(reverse: true)를 유지하고
// 말풍선·입력·빈 상태·키보드 대응 기능을 구현한다.
// 이 단계에서는 실제 AI API를 사용하지 않고 화면만 만든다.
void main() => runApp(const ChatLabApp());

class ChatLabApp extends StatelessWidget {
  const ChatLabApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Chat — 실습 1',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2F6FE4)),
        useMaterial3: true,
      ),
      home: const ChatPage(),
    );
  }
}

class ChatMessage {
  const ChatMessage({required this.text, required this.isUser});

  final String text;
  final bool isUser;
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();

  // 원본 스타터에 포함된 예시 대화. 지우기 버튼으로 빈 상태를 확인한다.
  final List<ChatMessage> _messages = [
    const ChatMessage(text: '오늘 뭐 배워?', isUser: true),
    const ChatMessage(text: 'AI 챗봇에 움직이는 응답을 붙입니다.', isUser: false),
    const ChatMessage(text: '타이핑 점은 왜 필요해요?', isUser: true),
    const ChatMessage(
      text: '응답이 1초를 넘으면 앱이 멈춘 것처럼 보이기 때문입니다.',
      isUser: false,
    ),
  ];

  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _controller.clear();
    });
    _scrollToLatest();
  }

  void _clearChat() {
    setState(_messages.clear);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // TODO 5 완료: 키보드가 올라오면 본문 크기를 줄인다.
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('AI Chat — 실습 1'),
        actions: [
          IconButton(
            tooltip: '대화 지우기 / 빈 상태 확인',
            onPressed: _clearChat,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              // TODO 4 완료: 대화가 없을 때 안내 문구를 겹쳐 표시한다.
              child: Stack(
                children: [
                  // 기존 완료 항목 1: reverse:true인 ListView.builder.
                  ListView.builder(
                    controller: _scroll,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[_messages.length - 1 - index];
                      return _Bubble(message: message);
                    },
                  ),
                  if (_messages.isEmpty)
                    const Center(
                      child: Text(
                        '무엇이든 물어보세요',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                ],
              ),
            ),
            // TODO 3 완료: TextField, 전송 버튼, Enter 전송.
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: '메시지를 입력하세요',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: '전송',
                    onPressed: _controller.text.trim().isEmpty ? null : _send,
                    icon: const Icon(Icons.send),
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

// TODO 2 완료: 사용자 말풍선은 오른쪽, AI 말풍선은 왼쪽.
class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        constraints: BoxConstraints(
          maxWidth: math.min(420.0, MediaQuery.sizeOf(context).width * 0.78),
        ),
        decoration: BoxDecoration(
          color: message.isUser
              ? colors.primaryContainer
              : colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(message.text),
      ),
    );
  }
}
