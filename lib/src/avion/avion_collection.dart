class AvionKeys{
  static const String appId= 'app_id';
  static const String type= 'type';
  static const String editor= 'editor';
  static const String data= 'data';
  static const String roomId= 'room_id';
  static const String userData= 'user_data';
  static const String isConsumer= 'is_consumer';
  static const String isProducer= 'is_producer';
  static const String routerRtpCapabilities='router_rtp_capabilities';
  static const String sctpCapabilities= "sctp_capabilities";
  static const String connect= "connect";
  static const String produce= "produce";
  static const String producers= "producers";
  static const String dtlsParameters= "dtls_parameters";
  static const String rtpParameters= "rtp_parameters";
  static const String rtpCapabilities= "rtp_capabilities";
  static const String transportId= "transport_id";
  static const String kind= "kind";
  static const String appData="app_data";
  static const String producerList='producer_list';
  static const String id='id';
  static const String producerId='producer_id';
  static const String peerId='peer_id';
  static const String avionUserId='avion_user_id';
  static const String avionUser='avion_user';
  static const String mute='mute';
  static const String isMute='is_mute';
  static const String producerTransport='producer_transport';
  static const String consumerTransport='consumer_transport';
}

const String serverAvionUrl= 'wss://meet.svara.live';

class AvionSyncType{
  static const String joinRoom= 'join_room';

  static const String createRoom= 'create_room';

  static const String routerRtpCapabilities= 'router_rtp_capabilities';


  /// we will call [createTransport] for creating transport in the server
  /// by passing sctpCapabilities and the weather producing and consuming
  static const String createTransport= 'create_transport';

  /// [createdTransport] is the callback from the server indicating transport created
  /// providing consuming and Producer Transport accordingly
  static const String createdTransport= 'created_transport';


  static const String produce= 'produce';


  static const String removeProducer= 'remove_producer';


  static const String removeMe= 'remove_me';


  static const String receiveTextMessage= 'receive_text_message';


  static const String sendTextMessage= 'send_text_message';


  static const String connectProducerTransport= 'connect_producer_transport';


  static const String connectedProducerTransport= 'connected_producer_transport';


  static const String connectConsumerTransport= 'connect_consumer_transport';


  static const String connectedConsumerTransport= 'connected_consumer_transport';


  static const String getUsersList= 'get_users_list';


  static const String usersList= 'users_list';


  static const String newConsumerUser= 'new_consumer_user';


  static const String createProducerTransport= 'create_producer_transport';


  static const String consumeProducer= 'consume_producer';


  static const String consumedProducer= 'consumed_producer';

  static const String newProducerUser= 'new_producer_user';

  static const String userDataUpdated= 'user_data_updated';

  static const String muteUnMuteUser= 'mute_unmute_user';

  static const String unMuteUser= 'un_mute_user';

  static const String muteUnMuteCallback= 'mute_unmute_callback';

  static const String leaveRoom = 'leave_room';

  static const String removeUser = 'remove_user';

  static const String userLeavedRoom = 'user_leaved_room';


  static const String roomEnded = 'room_ended';


  static const String newUserJoined="new_user_joined";


  static const String updateUserData= "update_user_data";


  static const String connectEarlierProducer= "connect_earlier_producer";


  static const String error= "error";


  static const String endRoom= "end_room";


  static const String warn= "warn";


  static const String createdRoom="created_room";


  static const String onUserJoined= "on_user_joined";

}

