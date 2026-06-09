import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';
import 'package:taxi_exam_app/core/models/option.dart';
import 'package:taxi_exam_app/core/models/question.dart';
import 'package:taxi_exam_app/features/bcd/bcd_text_utils.dart';

class BcdProvider extends ChangeNotifier {
  static final BcdProvider _instance = BcdProvider._();
  factory BcdProvider() => _instance;
  BcdProvider._();

  final _api = ApiService();

  // ── Traffic signs ─────────────────────────────────────────────────────────

  List<dynamic> signs = [];
  bool signsLoading = false;

  // ── Test questions ────────────────────────────────────────────────────────

  List<Question> testQuestions = [];
  bool testQuestionsLoading = false;
  String? testQuestionsError;

  // ── Public API ────────────────────────────────────────────────────────────

  String mediaUrl(String path) => _api.bcdMediaUrl(path);

  Future<void> loadTrafficSigns() async {
    signsLoading = true;
    notifyListeners();
    try {
      signs = await _api.fetchBCDTrafficSigns();
    } finally {
      signsLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshTrafficSignsSilently() async {
    try {
      signs = await _api.fetchBCDTrafficSigns();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> loadTestQuestions(int testId) async {
    testQuestionsLoading = true;
    testQuestionsError = null;
    testQuestions = [];
    notifyListeners();
    try {
      final raw = await _api.fetchBCDTestQuestions(testId);
      final prefs = await SharedPreferences.getInstance();
      final shuffleOnDevice = prefs.getBool('shuffleOnDevice') ?? false;
      final questions = raw.map(toQuestion).toList();
      if (shuffleOnDevice) questions.shuffle(Random());
      testQuestions = questions;
    } catch (e) {
      testQuestionsError = e.toString();
    } finally {
      testQuestionsLoading = false;
      notifyListeners();
    }
  }

  /// Fetches a specific page of questions for Smart Learning chunk sessions.
  ///
  /// For chunk mode:  pass [limit] and [offset] computed from SmartUtils.
  /// For mistakes mode: pass [ids] (the weak question IDs to practice).
  /// Set [applyShufflePreference] to true to honour the user's shuffleOnDevice
  /// SharedPreferences setting — callers then need no prefs/Random imports.
  ///
  /// Unlike [loadTestQuestions] this does NOT update shared state — it is a
  /// pure fetch that returns the question list directly to the caller.
  Future<List<Question>> fetchChunkQuestions(
    int testId, {
    int? limit,
    int? offset,
    List<String>? ids,
    bool applyShufflePreference = false,
  }) async {
    final raw = await _api.fetchBCDTestQuestions(
      testId,
      limit: limit,
      offset: offset,
      ids: ids,
    );
    final questions = raw.map(toQuestion).toList();
    if (applyShufflePreference) {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('shuffleOnDevice') ?? false) questions.shuffle(Random());
    }
    return questions;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Question toQuestion(dynamic raw) {
    final q = raw as Map<String, dynamic>;
    final answers = (q['bcd_answers'] as List<dynamic>?) ?? [];

    final options = answers.map((a) {
      final ans = a as Map<String, dynamic>;
      return Option(
        optionLabel: ans['label']?.toString() ?? '',
        text: cleanBcdText(ans['content']?.toString() ?? ''),
        imageUrl: '',
      );
    }).toList();

    final rawImagePath = q['image_url']?.toString() ?? '';
    final imageUrl =
        rawImagePath.isNotEmpty ? _api.bcdMediaUrl(rawImagePath) : '';

    final rawImages = (q['images'] as List<dynamic>?) ?? [];
    final images = rawImages
        .map((e) => e.toString())
        .where((e) => e.isNotEmpty)
        .map(_api.bcdMediaUrl)
        .toList();

    final rawTabs = (q['tabs'] as List<dynamic>?) ?? [];
    final tabs = rawTabs.map((t) {
      final tab = t as Map<String, dynamic>;
      final tabImages = ((tab['images'] as List<dynamic>?) ?? [])
          .map((e) => _api.bcdMediaUrl(e.toString()))
          .where((e) => e.isNotEmpty)
          .toList();
      return QuestionTab(
        title: tab['title']?.toString() ?? '',
        text: tab['text']?.toString() ?? '',
        images: tabImages,
      );
    }).toList();

    return Question(
      questionId: q['bcd_id']?.toString() ?? '',
      text: cleanBcdText(q['content']?.toString() ?? ''),
      imageUrl: imageUrl,
      images: images,
      tabs: tabs,
      correctAnswer: q['correct_answer']?.toString() ?? '',
      answerExplanation: cleanBcdText(q['explanation']?.toString() ?? ''),
      options: options,
    );
  }
}
