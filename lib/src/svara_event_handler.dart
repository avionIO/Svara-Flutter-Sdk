import 'package:svara_flutter_sdk/src/svara_user_data.dart';

abstract class SvaraEventHandler {
  // Constructor
  SvaraEventHandler();

  // Callback methods
  void onWarning(String warn);
  void onError(String err, String errorDetail) {}
  void onUserJoined(SvaraUserData svaraUserData) {}
  void onUserMuteUnmute(String svaraUid, bool mute) {}
  void onUserGetList(List<SvaraUserData> svaraUserData) {}
  void onNewUserJoined(SvaraUserData svaraUserData) {}
  void onUserLeft(String svaraUid) {}
  void onRoomCreated(String roomId) {}
  void onUserDataChanged(SvaraUserData svaraUserData, bool isItMe) {}
  void onUserIsSpeaking(SvaraUserData svaraUserData, int volume) {}
  void onRoomEnded() {}
  void onRemoved() {}
  //
  void receivedMessage(Map<String, dynamic> data) {}
}
