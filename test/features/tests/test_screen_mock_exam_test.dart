import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_exam_app/core/api/dio_client.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/core/models/option.dart';
import 'package:taxi_exam_app/core/models/question.dart';
import 'package:taxi_exam_app/core/models/test_attempt.dart';
import 'package:taxi_exam_app/core/storage/app_storage.dart';
import 'package:taxi_exam_app/core/widgets/option_tile.dart' as option_tile;
import 'package:taxi_exam_app/features/tests/test_screen.dart';

const _noScreenshotChannel = MethodChannel('no_screenshot');
const _flutterTtsChannel = MethodChannel('flutter_tts');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('test-screen-mock-exam');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(TestAttemptAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(QuestionAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(OptionAdapter());
    }
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    AppStorage.clearCurrentUser();
    await DioClient().init();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_noScreenshotChannel, (call) async => true);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_flutterTtsChannel, (call) async {
      switch (call.method) {
        case 'getLanguages':
          return <String>['en-US', 'sv-SE'];
        case 'stop':
        case 'setLanguage':
        case 'setPitch':
        case 'speak':
          return 1;
        default:
          return null;
      }
    });
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_noScreenshotChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_flutterTtsChannel, null);
    await _clearBoxIfOpen(AppStorage.testAttemptsBoxName);
  });

  Future<void> pumpScreen(
    WidgetTester tester, {
    required bool isMockExamMode,
    int? maxWrongAnswers,
    VoidCallback? onGameOver,
  }) async {
    LocaleSettings.setLocaleSync(AppLocale.en);
    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          home: Testscreen(
            questions: _questions,
            instantMarking: false,
            licenceId: '',
            categoryId: '1',
            licenceName: 'Taxi',
            categoryName: 'Mock Exam',
            isTimed: true,
            timeLimitMinutes: 30,
            passScorePercent: 70,
            isMockExamMode: isMockExamMode,
            maxWrongAnswers: maxWrongAnswers,
            onGameOver: onGameOver,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('mock exam mode hides overflow menu and keeps timer visible',
      (tester) async {
    await pumpScreen(tester, isMockExamMode: true);

    expect(find.byType(PopupMenuButton<String>), findsNothing);
    expect(find.byIcon(Icons.timer), findsOneWidget);
  });

  testWidgets('mock exam hearts mode shows one heart chip before the timer',
      (tester) async {
    await pumpScreen(
      tester,
      isMockExamMode: true,
      maxWrongAnswers: 3,
    );

    expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_border_rounded), findsNothing);

    final heartX = tester.getCenter(find.byIcon(Icons.favorite_rounded)).dx;
    final timerX = tester.getCenter(find.byIcon(Icons.timer)).dx;
    expect(heartX, lessThan(timerX));
  });

  testWidgets('mock exam without hearts does not use instant marking',
      (tester) async {
    await pumpScreen(tester, isMockExamMode: true);

    final wrongOption = find.byType(option_tile.Option).at(1);
    tester.widget<option_tile.Option>(wrongOption).onTap();
    await tester.pump();

    expect(
      find.descendant(of: wrongOption, matching: find.byIcon(Icons.close)),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byType(option_tile.Option).at(0),
        matching: find.byIcon(Icons.check),
      ),
      findsNothing,
    );
  });

  testWidgets('mock exam without hearts allows answer changes before finish',
      (tester) async {
    await pumpScreen(tester, isMockExamMode: true);

    final correctOption = find.byType(option_tile.Option).at(0);
    final wrongOption = find.byType(option_tile.Option).at(1);

    tester.widget<option_tile.Option>(wrongOption).onTap();
    await tester.pump();
    tester.widget<option_tile.Option>(correctOption).onTap();
    await tester.pump();

    expect(
      find.descendant(of: correctOption, matching: find.byIcon(Icons.circle)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: wrongOption, matching: find.byIcon(Icons.circle)),
      findsNothing,
    );
  });

  testWidgets('mock exam hearts mode triggers game over at the wrong-answer limit',
      (tester) async {
    var gameOverCalls = 0;
    await pumpScreen(
      tester,
      isMockExamMode: true,
      maxWrongAnswers: 1,
      onGameOver: () => gameOverCalls++,
    );

    final wrongOption = find.byType(option_tile.Option).at(1);
    tester.widget<option_tile.Option>(wrongOption).onTap();
    await tester.pump();
    await tester.pump();

    expect(gameOverCalls, 1);
  });

  testWidgets('mock exam hearts mode uses instant marking', (tester) async {
    await pumpScreen(
      tester,
      isMockExamMode: true,
      maxWrongAnswers: 3,
    );

    final wrongOption = find.byType(option_tile.Option).at(1);
    tester.widget<option_tile.Option>(wrongOption).onTap();
    await tester.pump();

    expect(
      find.descendant(of: wrongOption, matching: find.byIcon(Icons.close)),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(option_tile.Option).at(0),
        matching: find.byIcon(Icons.check),
      ),
      findsOneWidget,
    );
  });
}

final _questions = List<Question>.generate(
  3,
  (index) => Question(
    questionId: 'q$index',
    text: 'Question ${index + 1}',
    imageUrl: '',
    correctAnswer: 'A',
    answerExplanation: 'Explanation',
    options: [
      Option(optionLabel: 'A', text: 'Correct', imageUrl: ''),
      Option(optionLabel: 'B', text: 'Wrong', imageUrl: ''),
    ],
  ),
);

Future<void> _clearBoxIfOpen(String name) async {
  if (!Hive.isBoxOpen(name)) return;
  final box = Hive.box(name);
  await box.clear();
  await box.close();
}
