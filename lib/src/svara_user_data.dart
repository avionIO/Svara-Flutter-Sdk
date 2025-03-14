import 'package:get/get.dart';

class SvaraUserData {
  String svaraUserId;
  RxMap<String, dynamic> userData; // Wrap userData with RxMap
  RxBool isMute; // Wrap isMute with RxBool
  bool isProducer;
  bool isConsumer;

  SvaraUserData({
    required this.svaraUserId,
    required Map<String, dynamic> userData, // Receive a Map for userData
    required this.isProducer,
    required this.isConsumer,
    required bool isMute, // Receive a bool for isMute
  })  : userData = userData.obs, // Initialize RxMap
        isMute = isMute.obs; // Initialize RxBool

  factory SvaraUserData.fromJson(Map<String, dynamic> json) => SvaraUserData(
        svaraUserId: json["svara_uid"],
        userData:
            Map<String, dynamic>.from(json["user_data"]), // Convert to Map
        isMute: json["is_mute"],
        isProducer: json["is_producer"],
        isConsumer: json["is_consumer"],
      );

  Map<String, dynamic> toJson() => {
        'svara_uid': svaraUserId,
        'user_data': userData.value, // Access value of RxMap
        'is_mute': isMute.value, // Access value of RxBool
        'is_producer': isProducer,
        'is_consumer': isConsumer,
      };
}
