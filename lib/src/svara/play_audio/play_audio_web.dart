import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web/web.dart' as web;

void playWebAudio(MediaStream remoteStream) {
  final audioElement = web.HTMLAudioElement()
    ..autoplay = true
    ..controls = false;

  // On web, MediaStream is MediaStreamWeb which exposes jsStream directly.
  final jsMediaStream = (remoteStream as dynamic).jsStream as web.MediaStream;
  audioElement.srcObject = jsMediaStream;

  web.document.body?.append(audioElement);
}
