import 'dart:js_util' as js_util;
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:web/web.dart' as web;

void playWebAudio(MediaStream remoteStream) {
  final audioElement = web.HTMLAudioElement()
    ..autoplay = true
    ..controls = false;

  final jsMediaStream = js_util.getProperty(remoteStream, 'jsStream');

  js_util.setProperty(audioElement, 'srcObject', jsMediaStream);

  web.document.body?.append(audioElement);
}
