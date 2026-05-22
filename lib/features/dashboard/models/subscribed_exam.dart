import 'package:hive/hive.dart';
import 'exam_node.dart';

part 'subscribed_exam.g.dart';

/// Top-level exam a user is subscribed to.
///
/// [hasCategories] = false → 2-layer (Exam → Batch)
/// [hasCategories] = true  → 3-layer (Exam → Category → Batch)
///
/// [nodes] is a flat list. Build the tree using [rootNodes] and [childrenOf].
@HiveType(typeId: 4)
class SubscribedExam extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  /// false = 2-layer hierarchy, true = 3-layer
  @HiveField(2)
  bool hasCategories;

  /// Flat list of all nodes (categories + batches)
  @HiveField(3)
  List<ExamNode> nodes;

  @HiveField(4)
  DateTime subscribedAt;

  /// true = BCD exam; false = legacy (licence-based) exam.
  /// Affects how [TestAttempt] records are matched to this exam.
  @HiveField(5)
  bool isBcd;

  SubscribedExam({
    required this.id,
    required this.name,
    required this.hasCategories,
    required this.nodes,
    required this.subscribedAt,
    this.isBcd = false,
  });

  // Remote image URLs — not persisted, populated by ExamSyncService on load.
  String? examPictureDay;
  String? examPictureNight;

  // Cached computed properties — not persisted, rebuilt lazily after load.
  List<ExamNode>? _cachedBatches;
  List<ExamNode>? _cachedCategories;
  final Map<String, List<ExamNode>> _childrenCache = {};

  /// Root-level nodes.
  /// 3-layer → categories; 2-layer → batches directly.
  List<ExamNode> get rootNodes =>
      nodes.where((n) => n.parentId == null).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  /// Batch children of a given category node.
  List<ExamNode> childrenOf(String parentId) => _childrenCache.putIfAbsent(
        parentId,
        () => nodes.where((n) => n.parentId == parentId).toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
      );

  /// Every batch node in this exam (leaf nodes where tests are taken).
  List<ExamNode> get allBatches =>
      _cachedBatches ??= nodes.where((n) => n.isBatch).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  /// Every category node in this exam.
  List<ExamNode> get allCategories =>
      _cachedCategories ??= nodes.where((n) => n.isCategory).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
}
