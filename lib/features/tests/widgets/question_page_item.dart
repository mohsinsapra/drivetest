import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:taxi_exam_app/core/localization/strings.g.dart';
import 'package:taxi_exam_app/core/models/image_viewer.dart';
import 'package:taxi_exam_app/core/models/question.dart';
import 'package:taxi_exam_app/core/widgets/ai_action_button.dart';
import 'package:taxi_exam_app/core/widgets/option_tile.dart';
import 'package:taxi_exam_app/core/widgets/question_tabs_widget.dart';
import 'package:taxi_exam_app/core/widgets/tts_button.dart';

class QuestionPageItem extends StatelessWidget {
  final int index;
  final Question question;
  final String legacyImageUrl;
  final Map<int, String> userSelections;
  final bool isReviewMode;
  final bool instantMarking;
  final Set<String> savedQuestionIds;
  final bool aiEnabled;
  final bool hasAiSession;
  final String currentLanguageCode;
  final double scale;

  /// Key placed on the spacer at the bottom — only pass this for index == 0
  /// (used by the tutorial to anchor the peek-area highlight).
  final GlobalKey? peekAreaKey;

  final void Function(String optionLabel) onOptionTap;
  final VoidCallback onLongPress;
  final VoidCallback onLongPressUp;
  final VoidCallback onAiContinue;
  final VoidCallback onAiHint;
  final VoidCallback onAiUnderstand;
  final void Function(String qId, String questionText) onToggleSave;

  const QuestionPageItem({
    super.key,
    required this.index,
    required this.question,
    required this.legacyImageUrl,
    required this.userSelections,
    required this.isReviewMode,
    required this.instantMarking,
    required this.savedQuestionIds,
    required this.aiEnabled,
    required this.hasAiSession,
    required this.currentLanguageCode,
    required this.scale,
    this.peekAreaKey,
    required this.onOptionTap,
    required this.onLongPress,
    required this.onLongPressUp,
    required this.onAiContinue,
    required this.onAiHint,
    required this.onAiUnderstand,
    required this.onToggleSave,
  });

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final s = scale;
    final t = Translations.of(context);
    final questionText = question.text;
    final optionTexts = question.options.map((e) => e.text).toList();

    return GestureDetector(
      onLongPress: onLongPress,
      onLongPressUp: onLongPressUp,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20.0 * s, 12.0 * s, 20.0 * s, 20.0 * s),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontSize: 22 * s,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                              height: 1.3,
                            ),
                        children: [
                          TextSpan(text: questionText),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: TtsButton(
                              textToSpeak: questionText,
                              languageCode: currentLanguageCode,
                              iconSize: 22 * s,
                              tooltip: t.ai_read_aloud,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!isReviewMode && question.questionId.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        onToggleSave(question.questionId, question.text);
                      },
                      child: Padding(
                        padding: EdgeInsets.only(left: 8 * s, top: 2 * s),
                        child: Icon(
                          savedQuestionIds.contains(question.questionId)
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: savedQuestionIds.contains(question.questionId)
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey[400],
                          size: 28 * s,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 14 * s),
              ..._buildQuestionImages(
                context,
                s,
                mq,
                question.images.isNotEmpty
                    ? question.images
                    : (question.imageUrl.isNotEmpty ? [legacyImageUrl] : []),
              ),
              if (question.tabs.isNotEmpty) ...[
                SizedBox(height: 8 * s),
                QuestionTabsWidget(tabs: question.tabs),
              ],
              SizedBox(height: 12 * s),
              ...question.options.asMap().entries.map((entry) {
                final optIndex = entry.key;
                final option = entry.value;
                final isSelected = userSelections[index] == option.optionLabel;
                return Option(
                  text: optionTexts[optIndex],
                  optionLabel: option.optionLabel,
                  imageUrl: option.imageUrl,
                  isSelected: isSelected,
                  showInstantMarking:
                      instantMarking && userSelections[index] != null,
                  isCorrectAnswer: option.optionLabel == question.correctAnswer,
                  onTap: () => onOptionTap(option.optionLabel),
                  languageCode: currentLanguageCode,
                  scale: s,
                  explanation: option.optionLabel == question.correctAnswer
                      ? question.answerExplanation
                      : null,
                );
              }),
              _buildAiButtons(context, s, t),
              SizedBox(key: peekAreaKey, height: 12 * s),
              SizedBox(height: 8 * s),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAiButtons(BuildContext context, double s, Translations t) {
    if (!aiEnabled) return const SizedBox.shrink();

    if (hasAiSession) {
      return Padding(
        padding: EdgeInsets.only(top: 8 * s, bottom: 4 * s),
        child: Wrap(
          spacing: 8 * s,
          runSpacing: 6 * s,
          children: [
            AiActionButton(
              label: t.ai_continue_button,
              icon: Icons.auto_awesome,
              onPressed: onAiContinue,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(top: 8 * s, bottom: 4 * s),
      child: Wrap(
        spacing: 8 * s,
        runSpacing: 6 * s,
        children: [
          AiActionButton(
            label: t.ai_hint_button,
            icon: Icons.lightbulb_outline,
            onPressed: onAiHint,
          ),
          AiActionButton(
            label: t.ai_understand_button,
            icon: Icons.auto_awesome,
            onPressed: onAiUnderstand,
          ),
        ],
      ),
    );
  }

  Widget _buildImageTile(
    BuildContext context,
    double s,
    String url,
    List<String> allUrls,
    int idx,
  ) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: GestureDetector(
          onTap: () => showImageViewer(context, allUrls, initialIndex: idx),
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            errorWidget: (_, __, ___) => const _BrokenImagePlaceholder(),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildQuestionImages(
    BuildContext context,
    double s,
    MediaQueryData mq,
    List<String> urls,
  ) {
    if (urls.isEmpty) return [];

    if (urls.length > 2) {
      return [
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 8 * s,
          mainAxisSpacing: 8 * s,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: urls
              .asMap()
              .entries
              .map((e) => _buildImageTile(context, s, e.value, urls, e.key))
              .toList(),
        ),
        SizedBox(height: 12 * s),
      ];
    }

    return [
      ...urls.asMap().entries.map(
            (e) => Container(
              margin: EdgeInsets.only(bottom: 12 * s),
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: GestureDetector(
                  onTap: () =>
                      showImageViewer(context, urls, initialIndex: e.key),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: mq.size.height * 0.32,
                      maxWidth: mq.size.width * 0.9,
                    ),
                    child: CachedNetworkImage(
                      imageUrl: e.value,
                      fit: BoxFit.contain,
                      errorWidget: (_, __, ___) =>
                          const _BrokenImagePlaceholder(),
                    ),
                  ),
                ),
              ),
            ),
          ),
      SizedBox(height: 8 * s),
    ];
  }
}

class _BrokenImagePlaceholder extends StatelessWidget {
  const _BrokenImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 40,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}
