import '../models/exam_node.dart';
import '../models/subscribed_exam.dart';

/// Sample seeded data for local development.
///
/// IDs here must match what your API sets as:
///   TestAttempt.licenceId  ↔  SubscribedExam.id
///   TestAttempt.categoryId ↔  ExamNode.id (for batch nodes)
///
/// Replace with real IDs once you integrate the API.
class DashboardSeedData {
  DashboardSeedData._();

  /// Taxi — 3-layer: Taxi → Category → Batch
  static SubscribedExam taxiExam() => SubscribedExam(
        id: 'taxi',
        name: 'Taxi',
        hasCategories: true,
        subscribedAt: DateTime(2024, 1, 15),
        nodes: [
          // ── Category: Lagstiftning ─────────────────────────────────────
          const ExamNode(
            id: 'taxi_lagstiftning',
            name: 'Lagstiftning',
            nodeTypeIndex: 0, // category
            parentId: null,
            sortOrder: 0,
          ),
          const ExamNode(
            id: 'taxi_lagstiftning_l1',
            name: 'L1',
            nodeTypeIndex: 1, // batch
            parentId: 'taxi_lagstiftning',
            targetDurationSeconds: 25 * 60,
            sortOrder: 0,
          ),
          const ExamNode(
            id: 'taxi_lagstiftning_l2',
            name: 'L2',
            nodeTypeIndex: 1,
            parentId: 'taxi_lagstiftning',
            targetDurationSeconds: 25 * 60,
            sortOrder: 1,
          ),
          const ExamNode(
            id: 'taxi_lagstiftning_l3',
            name: 'L3',
            nodeTypeIndex: 1,
            parentId: 'taxi_lagstiftning',
            targetDurationSeconds: 25 * 60,
            sortOrder: 2,
          ),

          // ── Category: Säkerhet ────────────────────────────────────────
          const ExamNode(
            id: 'taxi_sakerhet',
            name: 'Säkerhet',
            nodeTypeIndex: 0,
            parentId: null,
            sortOrder: 1,
          ),
          const ExamNode(
            id: 'taxi_sakerhet_s1',
            name: 'S1',
            nodeTypeIndex: 1,
            parentId: 'taxi_sakerhet',
            targetDurationSeconds: 20 * 60,
            sortOrder: 0,
          ),
          const ExamNode(
            id: 'taxi_sakerhet_s2',
            name: 'S2',
            nodeTypeIndex: 1,
            parentId: 'taxi_sakerhet',
            targetDurationSeconds: 20 * 60,
            sortOrder: 1,
          ),
          const ExamNode(
            id: 'taxi_sakerhet_s3',
            name: 'S3',
            nodeTypeIndex: 1,
            parentId: 'taxi_sakerhet',
            targetDurationSeconds: 20 * 60,
            sortOrder: 2,
          ),

          // ── Category: Geografi ────────────────────────────────────────
          const ExamNode(
            id: 'taxi_geografi',
            name: 'Geografi',
            nodeTypeIndex: 0,
            parentId: null,
            sortOrder: 2,
          ),
          const ExamNode(
            id: 'taxi_geografi_g1',
            name: 'G1',
            nodeTypeIndex: 1,
            parentId: 'taxi_geografi',
            targetDurationSeconds: 30 * 60,
            sortOrder: 0,
          ),
          const ExamNode(
            id: 'taxi_geografi_g2',
            name: 'G2',
            nodeTypeIndex: 1,
            parentId: 'taxi_geografi',
            targetDurationSeconds: 30 * 60,
            sortOrder: 1,
          ),
        ],
      );

  /// B-körkort — 2-layer: B-körkort → Batch
  static SubscribedExam bKorkortExam() => SubscribedExam(
        id: 'b_korkort',
        name: 'B-körkort',
        hasCategories: false,
        subscribedAt: DateTime(2024, 3, 1),
        nodes: [
          const ExamNode(
            id: 'b_korkort_b1',
            name: 'B1',
            nodeTypeIndex: 1,
            parentId: null,
            targetDurationSeconds: 45 * 60,
            sortOrder: 0,
          ),
          const ExamNode(
            id: 'b_korkort_b2',
            name: 'B2',
            nodeTypeIndex: 1,
            parentId: null,
            targetDurationSeconds: 45 * 60,
            sortOrder: 1,
          ),
          const ExamNode(
            id: 'b_korkort_b3',
            name: 'B3',
            nodeTypeIndex: 1,
            parentId: null,
            targetDurationSeconds: 45 * 60,
            sortOrder: 2,
          ),
          const ExamNode(
            id: 'b_korkort_b4',
            name: 'B4',
            nodeTypeIndex: 1,
            parentId: null,
            targetDurationSeconds: 45 * 60,
            sortOrder: 3,
          ),
        ],
      );

  static List<SubscribedExam> all() => [taxiExam(), bKorkortExam()];
}
