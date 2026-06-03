import 'package:audioplayers/audioplayers.dart';

class SoundService {
  SoundService._();
  static final SoundService instance = SoundService._();

  final Map<String, AudioPlayer> _players = {};

  Future<AudioPlayer> _getPlayer(String asset) async {
    if (_players.containsKey(asset)) return _players[asset]!;
    final player = AudioPlayer();
    await player.setReleaseMode(ReleaseMode.stop);
    await player.setSource(AssetSource('sounds/$asset'));
    _players[asset] = player;
    return player;
  }

  Future<void> _play(String asset) async {
    try {
      final player = await _getPlayer(asset);
      await player.seek(Duration.zero);
      await player.resume();
    } catch (_) {}
  }

  Future<void> correctAnswer() => _play('correct-answer.mp3');
  Future<void> incorrectAnswer() => _play('incorrect-question.mp3');
  Future<void> consecutiveCorrect() => _play('consective-correct.mp3');
  Future<void> consecutiveCorrectBroken() =>
      _play('consective-correct-broken.mp3');
  Future<void> passExam() => _play('pass-exam.mp3');
  Future<void> failExam() => _play('fail-exam.mp3');

  void dispose() {
    for (final p in _players.values) {
      p.dispose();
    }
    _players.clear();
  }
}
