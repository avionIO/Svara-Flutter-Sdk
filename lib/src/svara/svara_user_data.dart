class SvaraUserData {
  String svaraUserId;
  Map<String, dynamic> userData; // Wrap userData with RxMap
  bool isMute; // Wrap isMute with RxBool
  bool isProducer;
  bool isConsumer;

  SvaraUserData({
    required this.svaraUserId,
    required this.userData, // Receive a Map for userData
    required this.isProducer,
    required this.isConsumer,
    required this.isMute, // Receive a bool for isMute
  }); // Initialize RxBool

  factory SvaraUserData.fromJson(Map<String, dynamic> json) => SvaraUserData(
        svaraUserId: json["avion_uid"],
        userData:
            Map<String, dynamic>.from(json["user_data"]), // Convert to Map
        isMute: json["is_mute"],
        isProducer: json["is_producer"],
        isConsumer: json["is_consumer"],
      );

  Map<String, dynamic> toJson() => {
        'avion_uid': svaraUserId,
        'user_data': userData, // Access value of RxMap
        'is_mute': isMute, // Access value of RxBool
        'is_producer': isProducer,
        'is_consumer': isConsumer,
      };
}
