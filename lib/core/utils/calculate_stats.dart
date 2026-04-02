import 'package:taxi_exam_app/core/models/test_attempt.dart';

Map<String, dynamic> calculateStats(List<TestAttempt> attempts) {
  final totalAttempts = attempts.length;
  final totalPassed = attempts.where((a) => a.hasPassed).length;
  final averageScore = attempts.isEmpty
      ? 0
      : attempts.map((e) => e.score).reduce((a, b) => a + b) / attempts.length;

  final licenceCounts = <String, int>{};
  final categoryCounts = <String, int>{};
  final licenceWithCategories = <String, Map<String, int>>{};

  double bestScore = 0;
  double worstScore = 100;

  for (var a in attempts) {
    final licence = (a.licenceName?.isNotEmpty == true)
        ? a.licenceName!
        : (a.isBcd ? 'BCD' : 'Unknown');
    final category = (a.categoryName?.isNotEmpty == true)
        ? a.categoryName!
        : 'Unknown';

    // Count licenses
    licenceCounts[licence] = (licenceCounts[licence] ?? 0) + 1;

    // Count categories
    categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;

    // Group categories under license
    licenceWithCategories[licence] ??= {};
    licenceWithCategories[licence]![category] =
        (licenceWithCategories[licence]![category] ?? 0) + 1;

    // Best and worst scores
    if (a.score > bestScore) bestScore = a.score;
    if (a.score < worstScore) worstScore = a.score;
  }

  return {
    'totalAttempts': totalAttempts,
    'totalPassed': totalPassed,
    'averageScore': averageScore,
    'licenceCounts': licenceCounts,
    'categoryCounts': categoryCounts,
    'licenceWithCategories': licenceWithCategories,
    'bestScore': bestScore,
    'worstScore': worstScore,
  };
}
