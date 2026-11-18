import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lab1_chat_ui/main.dart';

// 11주차: 실습 1(채팅 UI), 실습 4(오류 및 재시도) 위젯 테스트.
// 타이핑 점은 반복 애니메이션이므로 응답이 오기 전에는
// pumpAndSettle()로 기다리지 않고 100ms씩 진행하며 상태를 확인한다.
Future<void> pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 60; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
  // 제한 시간(테스트 시간 기준 6초) 내에 해당 화면이 나타나야 한다.
  expect(finder, findsOneWidget);
}

void main() {
  testWidgets('앱 시작 시 대화 및 전송 UI가 표시된다', (tester) async {
    await tester.pumpWidget(const ChatLabApp());

    expect(find.text('AI Chat — 실습 1'), findsOneWidget);
    expect(find.byType(ListView), findsOneWidget);
    expect(find.text('오늘 뭐 배워?'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.byTooltip('전송'), findsOneWidget);
    expect(find.textContaining('TODO 3'), findsNothing);
  });

  testWidgets('채팅을 지우면 빈 상태가 보인다', (tester) async {
    await tester.pumpWidget(const ChatLabApp());
    await tester.tap(find.byTooltip('대화 지우기 / 빈 상태 확인'));
    await tester.pump();

    expect(find.text('무엇이든 물어보세요'), findsOneWidget);
  });

  testWidgets('메시지 전송 후 모의 응답이 도착한다', (tester) async {
    await tester.pumpWidget(const ChatLabApp());
    await tester.enterText(find.byType(TextField), '안녕하세요');
    // 입력 후 onChanged가 반영되어 전송 버튼이 활성화되도록 프레임을 갱신한다.
    await tester.pump();
    await tester.tap(find.byTooltip('전송'));
    await tester.pump();

    expect(find.text('안녕하세요'), findsOneWidget);
    await pumpUntilFound(tester, find.textContaining('안녕하세요! 11주차'));
    expect(find.textContaining('안녕하세요! 11주차'), findsOneWidget);
  });

  testWidgets('429 오류를 표시하고 재시도에 성공한다', (tester) async {
    await tester.pumpWidget(const ChatLabApp());
    await tester.enterText(find.byType(TextField), '/429');
    // 입력 직후에는 버튼이 아직 비활성화된 상태일 수 있다.
    await tester.pump();
    await tester.tap(find.byTooltip('전송'));
    await tester.pump();

    final errorMessage = find.text('잠시 후 다시 시도해 주세요 (429)');
    await pumpUntilFound(tester, errorMessage);
    expect(errorMessage, findsOneWidget);

    // AnimatedSwitcher 전환이 완료된 뒤 재시도 버튼을 누른다.
    await tester.pump(const Duration(milliseconds: 350));
    await tester.tap(find.text('다시 시도'));
    await tester.pump();

    // 429 백오프(1초) + 모의 API 응답(850ms)을 기다린다.
    final successMessage = find.textContaining('재시도에 성공했습니다');
    await pumpUntilFound(tester, successMessage);
    await tester.pump(const Duration(milliseconds: 350));

    expect(successMessage, findsOneWidget);
    expect(find.text('다시 시도'), findsNothing);
  });
}
