import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:web/web.dart' as web;

void playWebAudio(JSObject remoteStream) {
  final audioElement = web.HTMLAudioElement()
    ..autoplay = true
    ..controls = false;

  // Get 'jsStream' property from the remoteStream
  final jsStream = remoteStream.getProperty('jsStream'.toJS);

  // Set it as srcObject on the audio element
  (audioElement as JSObject).setProperty('srcObject'.toJS, jsStream);

  web.document.body?.append(audioElement);
}
