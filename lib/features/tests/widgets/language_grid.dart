import 'package:flutter/material.dart';
import 'package:taxi_exam_app/core/constants/language_options.dart';

class LanguageGrid extends StatefulWidget {
  final ValueNotifier<String> selectedLanguage;
  final Future<void> Function(String code) onSelected;

  const LanguageGrid({
    super.key,
    required this.selectedLanguage,
    required this.onSelected,
  });

  @override
  State<LanguageGrid> createState() => _LanguageGridState();
}

class _LanguageGridState extends State<LanguageGrid> {
  String? _loadingCode;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return SelectionContainer.disabled(
      child: ValueListenableBuilder<String>(
        valueListenable: widget.selectedLanguage,
        builder: (_, selectedCode, __) => GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.1,
          ),
          itemCount: languageOptions.length,
          itemBuilder: (_, i) {
            final lang = languageOptions[i];
            final code = lang['code']!.toLowerCase();
            final isSelected = selectedCode.toLowerCase() == code;
            final isLoading = _loadingCode == code;
            return GestureDetector(
              onTap: _loadingCode != null
                  ? null
                  : () async {
                      if (isSelected) return;
                      setState(() => _loadingCode = code);
                      await widget.onSelected(lang['code']!);
                      if (mounted) setState(() => _loadingCode = null);
                    },
              child: Stack(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? primary.withValues(alpha: 0.08)
                          : Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? primary.withValues(alpha: 0.5)
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            lang['label']!.split(' ').first,
                            style: const TextStyle(
                              fontSize: 28,
                              decoration: TextDecoration.none,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            lang['label']!.split(' ').skip(1).join(' '),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.none,
                              color: isSelected
                                  ? primary
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (isLoading)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: primary,
                        ),
                      ),
                    )
                  else if (isSelected)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check,
                            size: 12, color: Colors.white),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
