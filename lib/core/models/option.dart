// models/option.dart
import 'package:hive/hive.dart';
part 'option.g.dart';

@HiveType(typeId: 2)
class Option {
  @HiveField(0)
  final String optionLabel;
  @HiveField(1)
  final String text;
  @HiveField(2)
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
