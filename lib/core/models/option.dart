// models/option.dart
class Option {
  final String optionLabel;
  final String text;
  final String imageUrl;

  Option({
    required this.optionLabel,
    required this.text,
    required this.imageUrl,
  });

  factory Option.fromMap(Map<String, dynamic> map) {
    return Option(
      optionLabel: map['option_label'] ?? '',
      text: map['text'] ?? '',
      imageUrl: map['image_url'] ?? '',
    );
  }
}
