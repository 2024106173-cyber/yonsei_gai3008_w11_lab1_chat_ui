import 'dart:math' as math;

import 'package:flutter/material.dart';

// GAI3008 · 11주차 개인 과제: 실습 1(채팅 UI) + 실습 4(오류와 재시도)
// 1) 기존 스타터의 reverse ListView와 예시 대화를 활용한다.
// 2) TODO 2~5: 좌우 말풍선, 전송, 빈 상태, 키보드 대응을 구현한다.
// 3) 실습 4: 오류 메시지와 다시 시도 버튼을 AnimatedSwitcher로 표시한다.
// 4) 원본 스타터에는 실제 AI API가 없으므로 모의 응답 클라이언트를 사용한다.
//    API 키를 앱 안에 넣지 않는다. 테스트용 /401, /429, /500, /timeout 명령 제공.
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

// 학습용 모의 응답. 실제 인터넷 통신이나 LLM 호출을 하지 않는다.
class DemoChatException implements Exception {
  const DemoChatException(this.status);
  final int status; // 401, 429, 500, 408(timeout)
}

class DemoAiClient {
  Future<String> chat(String text, {bool isRetry = false}) async {
    // 기다리는 동안 로딩(타이핑 점) 상태를 확인할 수 있도록 지연한다.
    await Future<void>.delayed(const Duration(milliseconds: 850));
    final input = text.trim().toLowerCase();
    if (input == '/401') throw const DemoChatException(401);
    if (!isRetry && input == '/429') throw const DemoChatException(429);
    if (!isRetry && input == '/500') throw const DemoChatException(500);
    if (!isRetry && input == '/timeout') throw const DemoChatException(408);

    if (input.startsWith('/')) {
      return '다시 시도에 성공했습니다. 오류 상태에서 정상 상태로 전환되었습니다.';
    }
    if (input.contains('안녕')) {
      return '안녕하세요! 11주차 Flutter 채팅 UI 실습입니다.';
    }
    if (input.contains('배워') || input.contains('flutter')) {
      return '채팅 말풍선, 메시지 전송, 오류 처리와 다시 시도를 연습합니다.';
    }
    return '메시지를 받았습니다: $text\n(이 응답은 서버가 아닌 실습용 모의 응답입니다.)';
  }
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final DemoAiClient _ai = DemoAiClient();

  // 원본 스타터에 포함된 초기 예시 대화를 유지한다.
  final List<ChatMessage> _messages = [
    const ChatMessage(text: '오늘 뭐 배워?', isUser: true),
    const ChatMessage(text: 'AI 챗봇에 움직이는 응답을 붙입니다.', isUser: false),
    const ChatMessage(text: '타이핑 점은 왜 필요해요?', isUser: true),
    const ChatMessage(
      text: '응답이 1초를 넘으면 앱이 멈춘 것처럼 보이기 때문입니다.',
      isUser: false,
    ),
  ];

  bool _sending = false;
  bool _typing = false;
  String? _error;
  String? _failedText;
  int? _failedStatus;
  int _retryCount = 0;

  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final reduceMotion = MediaQuery.disableAnimationsOf(context);
      if (reduceMotion) {
        _scroll.jumpTo(0);
      } else {
        _scroll.animateTo(
          0, // reverse: true에서 최신 메시지가 있는 위치
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send([String? example]) {
    if (_sending) return; // 연타로 중복 전송되지 않도록 잠근다.
    final text = (example ?? _controller.text).trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _controller.clear();
      _sending = true;
      _typing = true;
      _error = null;
      _failedText = null;
      _failedStatus = null;
      _retryCount = 0;
    });
    _scrollToLatest();
    _request(text, isRetry: false);
  }

  Future<void> _request(String text, {required bool isRetry}) async {
    try {
      final answer = await _ai.chat(text, isRetry: isRetry);
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(text: answer, isUser: false));
        _typing = false;
        _error = null;
        _failedText = null;
      });
    } on DemoChatException catch (failure) {
      if (!mounted) return;
      final message = switch (failure.status) {
        401 => '키/권한을 확인해 주세요 (401)',
        429 => '잠시 후 다시 시도해 주세요 (429)',
        500 => '응답을 받지 못했습니다 (500)',
        408 => '연결 시간이 초과되었습니다 (timeout)',
        _ => '네트워크를 확인해 주세요',
      };
      setState(() {
        _typing = false;
        _error = message;
        _failedText = text;
        _failedStatus = failure.status;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _typing = false;
        _error = '알 수 없는 오류가 발생했습니다';
        _failedText = text;
        _failedStatus = null;
      });
    } finally {
      if (mounted) {
        setState(() => _sending = false);
        _scrollToLatest();
      }
    }
  }

  Future<void> _retry() async {
    final text = _failedText;
    if (_sending || text == null) return;
    final wasRateLimited = _failedStatus == 429;
    setState(() {
      _sending = true;
      _typing = true;
      _error = null;
      _retryCount += 1;
    });
    // PDF 실습 4의 429 지수 백오프: 1초 → 2초 (최대 2초).
    if (wasRateLimited) {
      final seconds = math.min(1 << (_retryCount - 1), 2);
      await Future<void>.delayed(Duration(seconds: seconds));
      if (!mounted) return;
    }
    await _request(text, isRetry: true);
  }

  void _clearChat() {
    if (_sending) return;
    setState(() {
      _messages.clear();
      _error = null;
      _failedText = null;
      _failedStatus = null;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      // TODO 5: 키보드가 올라오면 본문이 축소된다.
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: const Text('AI Chat — 실습 1'),
        actions: [
          PopupMenuButton<String>(
            tooltip: '오류 시연',
            icon: const Icon(Icons.bug_report_outlined),
            enabled: !_sending,
            onSelected: _send,
            itemBuilder: (context) => const [
              PopupMenuItem(value: '/401', child: Text('401 · 권한 오류')),
              PopupMenuItem(value: '/429', child: Text('429 · 요청 제한')),
              PopupMenuItem(value: '/500', child: Text('500 · 서버 오류')),
              PopupMenuItem(value: '/timeout', child: Text('timeout · 시간 초과')),
            ],
          ),
          IconButton(
            tooltip: '대화 지우기 / 빈 상태 확인',
            onPressed: _sending ? null : _clearChat,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              // TODO 4: 빈 상태에 안내 문구 표시.
              child: Stack(
                children: [
                  // 스타터의 기존 ListView.builder(reverse:true) 유지.
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
            // 실습 4: 오류 말풍선 ↔ 타이핑 점을 AnimatedSwitcher로 전환.
            AnimatedSwitcher(
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 250),
              child: _error != null
                  ? _ErrorBubble(
                      key: const ValueKey('error'),
                      message: _error!,
                      onRetry: _retry,
                    )
                  : _typing
                      ? _TypingDots(
                          key: const ValueKey('typing'),
                          reduceMotion: reduceMotion,
                        )
                      : const SizedBox(key: ValueKey('idle')),
            ),
            // TODO 3: 입력창 + 전송 버튼. 요청 대기 중에는 중복 전송 금지.
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      enabled: !_sending,
                      textInputAction: TextInputAction.send,
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: '메시지를 입력하세요',
                        border: const OutlineInputBorder(),
                        isDense: true,
                        suffixIcon: _sending
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: '전송',
                    onPressed: _sending || _controller.text.trim().isEmpty
                        ? null
                        : _send,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '실습용 모의 응답 · 실제 AI API 미연결',
                style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// TODO 2: 사용자 오른쪽, AI 왼쪽의 서로 다른 말풍선.
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

// 실습 4: 사용자에게 실패 원인과 다시 시도 동작을 함께 제공한다.
class _ErrorBubble extends StatelessWidget {
  const _ErrorBubble({super.key, required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 6, 12, 4),
        constraints: const BoxConstraints(maxWidth: 360),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
        decoration: BoxDecoration(
          color: colors.errorContainer,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, style: TextStyle(color: colors.onErrorContainer)),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }
}

// 응답 대기 중 3개의 점이 순서대로 움직인다.
// Reduce Motion 설정에서는 움직임 없이 점만 표시한다.
class _TypingDots extends StatefulWidget {
  const _TypingDots({super.key, required this.reduceMotion});
  final bool reduceMotion;

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
  );

  @override
  void initState() {
    super.initState();
    if (!widget.reduceMotion) _animation.repeat();
  }

  @override
  void didUpdateWidget(covariant _TypingDots oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reduceMotion != widget.reduceMotion) {
      if (widget.reduceMotion) {
        _animation.stop();
      } else {
        _animation.repeat();
      }
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 6, 12, 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
        ),
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) => Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (index) {
              final wave = 0.5 +
                  0.5 * math.sin(2 * math.pi * (_animation.value - index / 3));
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Opacity(
                  opacity: widget.reduceMotion ? 0.65 : 0.3 + 0.7 * wave,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.primary,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
