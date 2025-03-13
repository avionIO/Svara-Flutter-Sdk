import 'package:get/get.dart';

class AvionUserData {
  String avionUserId;
  RxMap<String, dynamic> userData; // Wrap userData with RxMap
  RxBool isMute; // Wrap isMute with RxBool
  bool isProducer;
  bool isConsumer;

  AvionUserData({
    required this.avionUserId,
    required Map<String, dynamic> userData, // Receive a Map for userData
    required this.isProducer,
    required this.isConsumer,
    required bool isMute, // Receive a bool for isMute
  })  : userData = userData.obs, // Initialize RxMap
        isMute = isMute.obs; // Initialize RxBool

  factory AvionUserData.fromJson(Map<String, dynamic> json) =>
      AvionUserData(
        avionUserId: json["avion_uid"],
        userData: Map<String, dynamic>.from(json["user_data"]), // Convert to Map
        isMute: json["is_mute"],
        isProducer: json["is_producer"],
        isConsumer: json["is_consumer"],
      );

  Map<String, dynamic> toJson() => {
    'avion_uid': avionUserId,
    'user_data': userData.value, // Access value of RxMap
    'is_mute': isMute.value, // Access value of RxBool
    'is_producer': isProducer,
    'is_consumer': isConsumer,
  };
}
