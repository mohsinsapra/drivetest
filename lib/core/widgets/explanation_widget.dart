import 'package:flutter/material.dart';
import 'package:expandable/expandable.dart';
import 'package:taxi_exam_app/core/api/api_service.dart';
import 'package:taxi_exam_app/core/models/image_viewer.dart';
import '../models/question.dart';

class ExplanationWidget extends StatelessWidget {
  final Question question;
  final String licenceId;
  final String categoryId;
  final ApiService apiService;

  const ExplanationWidget({
    super.key,
    required this.question,
    required this.licenceId,
    required this.categoryId,
    required this.apiService,
  });

  Future<String> _loadImage(String imagePath) async {
    try {
      return apiService.fetchImage(licenceId, categoryId, imagePath);
    } catch (e) {
      throw Exception('Failed to fetch image URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (question.answerExplanation.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExpandableNotifier(
          initialExpanded: true,
          child: ExpandablePanel(
            theme: const ExpandableThemeData(
              headerAlignment: ExpandablePanelHeaderAlignment.center,
              hasIcon: true,
              iconColor: Colors.black,
              iconPlacement: ExpandablePanelIconPlacement.right,
              tapBodyToCollapse: false,
              tapBodyToExpand: false,
            ),
            header: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: Colors.blue[700],
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Explanation',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            collapsed: const SizedBox.shrink(),
            expanded: FutureBuilder<String>(
              future: _loadImage(question.answerExplanation),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: Padding(
                    padding: EdgeInsets.all(12.0),
                    child: CircularProgressIndicator(),
                  ));
                } else if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      'Error loading image URL: ${snapshot.error}',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                } else if (snapshot.hasData) {
                  return Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: GestureDetector(
                      onTap: () => showImageViewer(context, snapshot.data!),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: MediaQuery.of(context).size.height * 0.4,
                          maxWidth: MediaQuery.of(context).size.width * 0.9,
                        ),
                        child:
                            Image.network(snapshot.data!, fit: BoxFit.contain),
                      ),
                    ),
                  );
                } else {
                  return const Text('No image available.');
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}
