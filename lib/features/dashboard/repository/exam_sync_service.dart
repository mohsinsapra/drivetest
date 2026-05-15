import 'package:taxi_exam_app/core/services/bcd_cache.dart';
import '../models/exam_node.dart';
import '../models/subscribed_exam.dart';

/// Builds [SubscribedExam] objects from the shared [BcdCache].
/// Never makes direct API calls — the cache is the single source.
///
/// Only exams where `is_subscribed == true` are included in the result so
/// the dashboard shows what the user has actually paid for.
class ExamSyncService {
  final BcdCache _cache;

  ExamSyncService({BcdCache? cache}) : _cache = cache ?? BcdCache.instance;

  /// Returns subscribed BCD exams. Loads the cache on first call.
  Future<List<SubscribedExam>> fetchSubscribedExams() async {
    await _cache.ensureLoaded();

    final results = <SubscribedExam>[];

    for (final cat in _cache.categories) {
      final bcdId = cat['bcd_id'] as int?;
      if (bcdId == null) continue;

      // Dashboard only shows subscribed exams
      if (cat['is_subscribed'] != true) continue;

      final exam = _buildExam(cat, bcdId);
      results.add(exam);
    }

    return results;
  }

  // ── Mapping ───────────────────────────────────────────────────────────────

  SubscribedExam _buildExam(Map<String, dynamic> cat, int bcdId) {
    final name = cat['name']?.toString() ?? 'Exam $bcdId';
    final hasChildren = cat['has_children'] == true;

    final nodes = hasChildren
        ? _buildThreeLayerNodes(bcdId)
        : _buildTwoLayerNodes(bcdId, parentId: null);

    return SubscribedExam(
      id: bcdId.toString(),
      name: name,
      hasCategories: hasChildren,
      isBcd: true,
      nodes: nodes,
      subscribedAt: DateTime.now(),
    );
  }

  /// 2-layer: tests directly under the top-level category.
  List<ExamNode> _buildTwoLayerNodes(int bcdId, {required String? parentId}) {
    final tests = _cache.testsOf(bcdId);
    return tests.asMap().entries.map((e) {
      final t = e.value;
      return ExamNode(
        id: _testBcdId(t),
        name: t['name']?.toString() ?? '—',
        nodeTypeIndex: 1,
        parentId: parentId,
        targetDurationSeconds: _timeLimit(t),
        passScore: _passScore(t),
        sortOrder: e.key,
      );
    }).toList();
  }

  /// 3-layer: subcategories → tests per subcategory.
  List<ExamNode> _buildThreeLayerNodes(int bcdId) {
    final subs = _cache.subcategoriesOf(bcdId);
    final nodes = <ExamNode>[];
    var catSort = 0;

    for (final sub in subs) {
      final subId = sub['bcd_id'] as int?;
      if (subId == null) continue;

      nodes.add(ExamNode(
        id: subId.toString(),
        name: sub['name']?.toString() ?? '—',
        nodeTypeIndex: 0,
        parentId: null,
        sortOrder: catSort++,
      ));

      // Batch nodes under this subcategory
      final testNodes = _buildTwoLayerNodes(subId, parentId: subId.toString());
      nodes.addAll(testNodes);
    }

    return nodes;
  }

  // ── Field helpers ─────────────────────────────────────────────────────────

  /// BCD tests use the `bcd_id` field as their identifier.
  String _testBcdId(Map<String, dynamic> t) => (t['bcd_id'])?.toString() ?? '';

  int _timeLimit(Map<String, dynamic> t) {
    final v = t['time_limit'];
    if (v == null) return 0;
    final mins = v is num ? v.toInt() : int.tryParse(v.toString()) ?? 0;
    return mins * 60;
  }

  int _passScore(Map<String, dynamic> t) {
    final v = t['pass_score'];
    if (v == null) return 0;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }
}
