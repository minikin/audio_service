import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:audio_service_example/media_control.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TextPlayerTask extends BackgroundAudioTask {
  final _tts = FlutterTts();

  /// Represents the completion of a period of playing or pausing.
  var _playPauseCompleter = Completer();

  BasicPlaybackState get _basicState => AudioServiceBackground.state.basicState;

  MediaItem mediaItem(int number) => MediaItem(
      id: 'tts_$number',
      album: 'Numbers',
      title: 'Number $number',
      artist: 'Sample Artist');

  @override
  void onClick(MediaButton button) {
    playPause();
  }

  @override
  void onPause() {
    playPause();
  }

  @override
  void onPlay() {
    playPause();
  }

  @override
  Future<void> onStart() async {
    playPause();
    for (var i = 1; i <= 10 && _basicState != BasicPlaybackState.stopped; i++) {
      await AudioServiceBackground.setMediaItem(mediaItem(i));
      await AudioServiceBackground.androidForceEnableMediaButtons();
      await _tts.speak('$i');
      // Wait for the speech or a pause request.
      await Future.any(
          [Future.delayed(const Duration(seconds: 1)), _playPauseFuture()]);
      // If we were just paused...
      if (_playPauseCompleter.isCompleted &&
          _basicState == BasicPlaybackState.paused) {
        // Wait to be unpaused...
        await _playPauseFuture();
      }
    }
    if (_basicState != BasicPlaybackState.stopped) onStop();
  }

  @override
  void onStop() {
    if (_basicState == BasicPlaybackState.stopped) return;
    _tts.stop();
    AudioServiceBackground.setState(
      controls: [],
      basicState: BasicPlaybackState.stopped,
    );
    _playPauseCompleter.complete();
  }

  void playPause() {
    if (_basicState == BasicPlaybackState.playing) {
      _tts.stop();
      AudioServiceBackground.setState(
        controls: [playControl, stopControl],
        basicState: BasicPlaybackState.paused,
      );
    } else {
      AudioServiceBackground.setState(
        controls: [pauseControl, stopControl],
        basicState: BasicPlaybackState.playing,
      );
    }
    _playPauseCompleter.complete();
  }

  /// This wraps [_playPauseCompleter.future], replacing [_playPauseCompleter]
  /// if it has already completed.
  Future _playPauseFuture() {
    if (_playPauseCompleter.isCompleted) _playPauseCompleter = Completer();
    return _playPauseCompleter.future;
  }
}
