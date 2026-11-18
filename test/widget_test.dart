import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lab1_chat_ui/main.dart';

void main() {
  testWidgets('실습 1: 대화와 입력 UI 표시', (tester) async {
    await tester.pumpWidget(const ChatLabApp());
    expect(find.text('AI Chat — 실습 1'), findsOneWidget);
    expect(find.byType(ListView), findsOneWidget);
    expect(find.text('오늘 뭐 배워?'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.textContaining('TODO 3'), findsNothing);
  });

  testWidgets('실습 1: 빈 상태', (tester) async {
    await tester.pumpWidget(const ChatLabApp());
    await tester.tap(find.byTooltip('대화 지우기 / 빈 상태 확인'));
    await tester.pump();
    expect(find.text('무엇이든 물어보세요'), findsOneWidget);
  });
}
