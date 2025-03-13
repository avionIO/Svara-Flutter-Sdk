


import 'package:svara_flutter_sdk/src/avion/avion_user_data.dart';

abstract class AvionEventHandler {
  // Constructor
  AvionEventHandler();

  // Callback methods
  void onWarning(String warn) ;
  void onError(String err,String errorDetail) {}
  void onUserJoined(AvionUserData avionUserData) {}
  void onUserMuteUnmute(String avionUid, bool mute) {}
  void onUserGetList(List<AvionUserData> avionUserData) {}
  void onNewUserJoined(AvionUserData avionUserData){}
  void onUserLeft(String avionUid){}
  void onRoomCreated(String roomId){}
  void onUserDataChanged(AvionUserData avionUserData,bool isItMe){}
  void onUserIsSpeaking(AvionUserData avionUserData, int volume){}
  void onRoomEnded(){}
  void onRemoved(){}
  //
  void receivedMessage(Map<String, dynamic> data) {}
}