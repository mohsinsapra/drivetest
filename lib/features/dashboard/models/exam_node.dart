import 'package:hive/hive.dart';

part 'exam_node.g.dart';

/// Type of node in the exam hierarchy.
/// category = middle layer (only in 3-layer exams)
/// batch    = leaf layer where tests are actually taken
enum ExamNodeType { category, batch }

/// A single node in the exam hierarchy tree.
/// Stored flat inside [SubscribedExam.nodes]; use [parentId] to build the tree.
///
/// 3-layer: root nodes are categories (parentId == null),
///          child nodes are batches (parentId == categoryId).
/// 2-layer: root nodes are batches directly (parentId == null).
@HiveType(typeId: 5)
class ExamNode {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  /// 0 = category, 1 = batch
  @HiveField(2)
  final int nodeTypeIndex;

  /// null for root-level nodes
  @HiveField(3)
  final String? parentId;

  /// Target seconds per attempt for this batch (0 if category).
  @HiveField(4)
  final int targetDurationSeconds;

  @HiveField(5)
  final int sortOrder;

  /// Pass-score threshold (0–100). Only relevant for BCD batch nodes.
  @HiveField(6)
  final int passScore;

  const ExamNode({
    required this.id,
    required this.name,
    required this.nodeTypeIndex,
    this.parentId,
    this.targetDurationSeconds = 0,
    this.sortOrder = 0,
    this.passScore = 0,
  });

  ExamNodeType get nodeType =>
      nodeTypeIndex == 0 ? ExamNodeType.category : ExamNodeType.batch;
  bool get isCategory => nodeType == ExamNodeType.category;
  bool get isBatch => nodeType == ExamNodeType.batch;

  ExamNode copyWith({
    String? id,
    String? name,
    int? nodeTypeIndex,
    String? parentId,
    int? targetDurationSeconds,
    int? sortOrder,
    int? passScore,
  }) =>
      ExamNode(
        id: id ?? this.id,
        name: name ?? this.name,
        nodeTypeIndex: nodeTypeIndex ?? this.nodeTypeIndex,
        parentId: parentId ?? this.parentId,
        targetDurationSeconds:
            targetDurationSeconds ?? this.targetDurationSeconds,
        sortOrder: sortOrder ?? this.sortOrder,
        passScore: passScore ?? this.passScore,
      );
}
