import 'package:chatbot/chat_screen.dart';
import 'package:chatbot/component/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('chatbot bubble uses accent avatar color in dark mode', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await AppThemeController.instance.updateDarkMode(true);

    await tester.pumpWidget(const MaterialApp(home: ChatDetailPage()));
    await tester.pump();

    final introFinder = find.textContaining('Halo! Saya Academic Assistant');
    final bubble = tester.widget<Container>(
      find.ancestor(of: introFinder, matching: find.byType(Container)).first,
    );
    final decoration = bubble.decoration! as BoxDecoration;

    expect(decoration.color, AppThemePalette.accentAvatar);
  });

  testWidgets('chatbot header uses custom bot image icon', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await AppThemeController.instance.updateDarkMode(false);

    await tester.pumpWidget(const MaterialApp(home: ChatDetailPage()));
    await tester.pump();

    final icon = tester.widget<ImageIcon>(find.byType(ImageIcon).first);
    final image = icon.image as AssetImage;

    expect(image.assetName, 'assets/images/sis_bot_icon.png');
  });

  testWidgets('chatbot menu uses accent avatar color in dark mode', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await AppThemeController.instance.updateDarkMode(true);

    await tester.pumpWidget(const MaterialApp(home: ChatDetailPage()));
    await tester.pump();

    final state = tester.state<ChatDetailPageState>(
      find.byType(ChatDetailPage),
    );
    final menu = state.buildBotMenuForTest([
      {'title': 'Hasil KRS', 'payload': 'Hasil KRS'},
    ]);

    await tester.pumpWidget(MaterialApp(home: Scaffold(body: menu)));

    final menuContainer = tester.widget<Container>(
      find
          .ancestor(
            of: find.text('Hasil KRS'),
            matching: find.byType(Container),
          )
          .first,
    );
    final decoration = menuContainer.decoration! as BoxDecoration;

    expect(decoration.color, AppThemePalette.accentAvatar);
  });

  testWidgets('chatbot menu text is white in dark mode', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await AppThemeController.instance.updateDarkMode(true);

    await tester.pumpWidget(const MaterialApp(home: ChatDetailPage()));
    await tester.pump();

    final state = tester.state<ChatDetailPageState>(
      find.byType(ChatDetailPage),
    );
    final menu = state.buildBotMenuForTest([
      {'title': 'Hasil KRS', 'payload': 'Hasil KRS'},
    ]);

    await tester.pumpWidget(MaterialApp(home: Scaffold(body: menu)));

    final text = tester.widget<Text>(find.text('Hasil KRS'));
    expect(text.style?.color, Colors.white);
  });

  testWidgets('anonymous chatbot sender stays stable while page is open', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MaterialApp(home: ChatDetailPage()));
    await tester.pump();

    final state = tester.state<ChatDetailPageState>(
      find.byType(ChatDetailPage),
    );

    final firstSender = state.senderIdentifierForTest;
    final secondSender = state.senderIdentifierForTest;

    expect(firstSender, isNotEmpty);
    expect(secondSender, firstSender);
  });

  testWidgets('keyboard send action submits the chatbot message', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MaterialApp(home: ChatDetailPage()));
    await tester.pump();

    final state = tester.state<ChatDetailPageState>(
      find.byType(ChatDetailPage),
    );
    final input = find.byType(TextField);

    expect(state.chatWidgets, hasLength(1));

    await tester.enterText(input, 'cek krs');
    await tester.testTextInput.receiveAction(TextInputAction.send);
    await tester.pump();

    expect(state.chatWidgets, hasLength(greaterThanOrEqualTo(2)));
    expect(find.text('cek krs'), findsOneWidget);
    expect(tester.widget<TextField>(input).controller?.text, isEmpty);

    await tester.pump(const Duration(milliseconds: 100));
  });
}
