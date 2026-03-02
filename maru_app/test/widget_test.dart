// test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:maru_app/main.dart'; 

void main() {
  testWidgets('App execution smoke test', (WidgetTester tester) async {
    // 1. MaruApp을 ProviderScope로 감싸서 실행합니다.
    await tester.pumpWidget(const ProviderScope(child: MaruApp()));

    // 2. 앱의 핵심 뼈대인 GetMaterialApp이 정상적으로 그려졌는지 확인합니다.
    expect(find.byType(GetMaterialApp), findsOneWidget);
  });
}