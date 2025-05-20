import 'package:flutter_webrtc/flutter_webrtc.dart';

class SvaraUserData {
  String svaraUserId;
  Map<String, dynamic> userData; // Wrap userData with RxMap
  bool isMute; // Wrap isMute with RxBool
  bool cameraOn; // Wrap isMute with RxBool
  bool isProducer;
  bool isConsumer;
  RTCVideoRenderer? renderer;

  SvaraUserData({
    required this.svaraUserId,
    required this.userData, // Receive a Map for userData
    required this.isProducer,
    required this.isConsumer,
    required this.isMute, // Receive a bool for isMute
    required this.cameraOn, // Receive a bool for isMute

    required this.renderer, // Receive a bool for isMute
  }); // Initialize RxBool

  factory SvaraUserData.fromJson(Map<String, dynamic> json) => SvaraUserData(
        svaraUserId: json["avion_uid"],
        userData:
            Map<String, dynamic>.from(json["user_data"]), // Convert to Map
        isMute: json["is_mute"],
        cameraOn: json["is_camera_on"],
        isProducer: json["is_producer"],
        isConsumer: json["is_consumer"],
        renderer: json["renderer"],
      );

  Map<String, dynamic> toJson() => {
        'avion_uid': svaraUserId,
        'user_data': userData, // Access value of RxMap
        'is_mute': isMute, // Access value of RxBool
        'is_producer': isProducer,
        'is_consumer': isConsumer,
        'is_camera_on': cameraOn,
      };
}
