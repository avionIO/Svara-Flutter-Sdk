import 'dart:convert';
import 'package:mediasfu_mediasoup_client/mediasfu_mediasoup_client.dart';
import 'package:svara_flutter_sdk/src/svara/svara_event_handler.dart';
import 'package:svara_flutter_sdk/src/svara/svara_user_data.dart';
import 'package:web_socket_channel/status.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'svara_collection.dart';

class SvaraServices {
  static final SvaraServices _instance = SvaraServices._internal();
  WebSocketChannel? _channel;
  Device device = Device();
  Transport? _sendTransport;
  Transport? _recTransport;
  rtc.RTCVideoRenderer localRenderer = rtc.RTCVideoRenderer();
  rtc.MediaStream? _localStream;
  SvaraUserData? svaraUserData;

  SvaraServices._internal();

  factory SvaraServices() {
    return _instance;
  }

  String? appId;
  String? secretKey;
  SvaraEventHandler? _eventHandler;

  void _setEventHandler(SvaraEventHandler eventHandler) {
    _eventHandler = eventHandler;
  }

  void create(String appId, String secretKey, SvaraEventHandler evenHandler) {
    this.appId = appId;
    this.secretKey = secretKey;
    _setEventHandler(evenHandler);
  }

  void _send(String type, Map<dynamic, dynamic> data) {
    final message = jsonEncode({SvaraKeys.type: type, SvaraKeys.data: data});
    _channel?.sink.add(message);
  }

  void joinRoom(String roomId, Map<String, dynamic> userData, bool isProducer,
      bool isConsumer) {
    localRenderer.initialize();

    if (appId != null) {
      _channel = WebSocketChannel.connect(
        Uri.parse(serverSvaraUrl),
        protocols: [appId!, secretKey!],
      );
      Map<String, dynamic> data = {
        SvaraKeys.roomId: roomId,
        SvaraKeys.userData: userData,
        SvaraKeys.isMute: false,
        SvaraKeys.isConsumer: isConsumer,
        SvaraKeys.isProducer: isProducer,
      };
      _send(SvaraSyncType.joinRoom, data);
      _channel!.stream.listen(_onMessage);
    } else {
      throw "Create the Svara Service";
    }
  }

  void createRoom(Map<String, dynamic> userData) {
    localRenderer.initialize();

    if (appId != null) {
      _channel = WebSocketChannel.connect(
        Uri.parse(serverSvaraUrl),
        protocols: [appId!, secretKey!],
      );
      Map<String, dynamic> data = {
        SvaraKeys.userData: userData,
      };
      _send(SvaraSyncType.createRoom, data);
      _channel!.stream.listen(
        _onMessage,
        onDone: () {},
        onError: (error) {},
      );
    } else {
      throw "Create the Svara Service";
    }
  }

  void endOperations() {
    try {
      device = Device();
      _sendTransport?.close();
      _recTransport?.close();
      _sendTransport = null;
      _recTransport = null;
      // Stop all media tracks
      _localStream?.getTracks().forEach((track) {
        track.stop();
      });
      localRenderer.dispose();
      localRenderer = rtc.RTCVideoRenderer();
      _localStream?.dispose();
      _localStream = null;
      _channel?.sink.close(normalClosure);
      _channel = null;
    } catch (e) {
      // EMPTY CATCH BLOCK
    }
  }

  void leaveRoom(String reason) {
    _send(SvaraSyncType.leaveRoom, {SvaraKeys.editor: reason});
    endOperations();
  }

  void _manageRoomEnded() {
    _eventHandler!.onRoomEnded();
    endOperations();
  }

  void removeUser(String removingUserId) {
    _send(SvaraSyncType.removeUser, {SvaraKeys.svaraUserId: removingUserId});
  }

  void updateUserData(String svaraUserId, Map<String, dynamic> me) {
    _send(SvaraSyncType.updateUserData,
        {SvaraKeys.userData: me, SvaraKeys.svaraUserId: svaraUserId});
  }

  void _onMessage(dynamic message) async {
    final decodedMessage = json.decode(message);
    // printLongString("Received Svara Connection Response: $message");
    switch (decodedMessage[SvaraKeys.type]) {
      case SvaraSyncType.routerRtpCapabilities:

      ///Receives Rtp Capabilities from serve
      ///load it into the device and send device sctpCapabilities with weather producing or consuming
        await _setRouterRtpCapabilities(decodedMessage[SvaraKeys.data]);
        break;
      case SvaraSyncType.createdRoom:
        _manageOnRoomCreated(decodedMessage[SvaraKeys.data]);
        break;
      case SvaraSyncType.onUserJoined:
        _manageOnUserJoined(decodedMessage[SvaraKeys.data]);
        break;
      case SvaraSyncType.createdTransport:

      ///Called when a producerTransport is created
        await _connectingTransport(decodedMessage[SvaraKeys.data]);
        break;
      case SvaraSyncType.connectedConsumerTransport:

      ///Called when a consumerTransport is created
        await _consumedProducers(decodedMessage[SvaraKeys.data]);
        break;
      case SvaraSyncType.connectedProducerTransport:

      ///Called when a ProducerTransport is connected
      // _produced();
        break;
      case SvaraSyncType.usersList:
        _manageUserList(decodedMessage[SvaraKeys.data]);
        break;
      case SvaraSyncType.newUserJoined:
        _manageNewUserJoined(decodedMessage[SvaraKeys.data]);
        break;
      case SvaraSyncType.newProducerUser:
        await _newProducerHandling(decodedMessage[SvaraKeys.data]);
        break;
      case SvaraSyncType.userDataUpdated:
        _manageUserDataUpdated(decodedMessage[SvaraKeys.data]);
        break;
      case SvaraSyncType.newConsumerUser:
        await _newConsumerHandling(decodedMessage[SvaraKeys.data]);
        break;
      case SvaraSyncType.muteUnMuteCallback:
        _manageMuteUnMuteCallback(decodedMessage[SvaraKeys.data]);
        break;
      case SvaraSyncType.userLeavedRoom:
        _manageUserLeavedRoom(decodedMessage[SvaraKeys.data]);
        break;
      case SvaraSyncType.removeMe:
        _manageRemoveMe(decodedMessage[SvaraKeys.data]);
        break;
      case SvaraSyncType.receiveTextMessage:
        _manageReceiveMessage(decodedMessage[SvaraKeys.data]);
        break;
      case SvaraSyncType.roomEnded:
        _manageRoomEnded();
        break;
      case SvaraSyncType.error:
        _manageError(decodedMessage[SvaraKeys.data]);
        break;
      case SvaraSyncType.warn:
        _manageWarn(decodedMessage[SvaraKeys.data]);
        break;
    }
  }

  void _manageReceiveMessage(Map<String, dynamic> data) {
    _eventHandler!.receivedMessage(data);
  }

  void _manageRemoveMe(Map<String, dynamic> data) {
    _eventHandler!.onRemoved();
    leaveRoom(data[SvaraKeys.editor]);
  }

  void removeProducer() {
    try {
      Map<String, dynamic> sendingData = {
        SvaraKeys.svaraUserId: svaraUserData!.svaraUserId,
        SvaraKeys.producerId: _sendTransport!.id,
      };
      _send(SvaraSyncType.removeProducer, sendingData);
      _sendTransport!.close();
      _sendTransport = null;
      svaraUserData!.isProducer = false;
    } catch (e) {
      // EMPTY CATCH BLOCK
    }
  }

  void muteMic() {
    Map<String, dynamic> muteUserData = {
      SvaraKeys.isMute: true,
    };
    svaraUserData!.isMute = true;
    _localStream!.getAudioTracks().first.enabled = false;
    _send(SvaraSyncType.muteUnMuteUser, muteUserData);
  }

  void unMuteMic() {
    Map<String, dynamic> muteUserData = {
      SvaraKeys.isMute: false,
    };
    svaraUserData!.isMute = false;
    _localStream!.getAudioTracks().first.enabled = true;
    _send(SvaraSyncType.muteUnMuteUser, muteUserData);
  }

  void createProducerTransport() {
    svaraUserData!.isProducer = true;
    Map<String, dynamic> createTransportData = {
      SvaraKeys.sctpCapabilities: device.sctpCapabilities.toMap(),
      SvaraKeys.rtpCapabilities: device.rtpCapabilities.toMap()
    };
    _send(SvaraSyncType.createProducerTransport, createTransportData);
  }

  void getUserList() {
    _send(SvaraSyncType.getUsersList, {});
  }

  void endRoom() {
    _send(SvaraSyncType.endRoom, {});
  }

  Future<void> _setRouterRtpCapabilities(Map<String, dynamic> data) async {
    try {
      var routerRtpCapabilities =
      RtpCapabilities.fromMap(data[SvaraKeys.routerRtpCapabilities]);
      await device.load(routerRtpCapabilities: routerRtpCapabilities);

      Map<String, dynamic> createTransportData = {
        SvaraKeys.sctpCapabilities: device.sctpCapabilities.toMap(),
        SvaraKeys.rtpCapabilities: device.rtpCapabilities.toMap()
      };
      _send(SvaraSyncType.createTransport, createTransportData);
    } catch (e) {
      leaveRoom('client');
    }
  }

  void _consumerCallback(Consumer consumer, var arguments) {
    /* Your code. */
  }

  void _producerCallback(Producer producer) {
    /* Your code. */
  }

  Future<void> _produced() async {

    // _sendTransport!.on('connectionstatechange', (state)async {
    //   print("Transport state changed: $state");
    //
    //   if (state == 'connected') {
    //     // Produce our webcam video.
    //     Map<String, dynamic> mediaConstraints = <String, dynamic>{
    //       'audio': true,
    //       'video': false,
    //     };
    //     // var status = await Permission.microphone.request();
    //     // if (status.isDenied) {
    //     //   print('Microphone permission is denied');
    //
    //     // }
    //     _localStream = await rtc.navigator.mediaDevices.getUserMedia(mediaConstraints);
    //     final MediaStreamTrack track = _localStream!.getAudioTracks().first;
    //     print("_sendTransport connected: ${_sendTransport?.connectionState}");
    //     _sendTransport!.produce(
    //       stream: _localStream!,
    //       track: track,
    //       appData: {
    //         'source': 'mic',
    //       },
    //       codecOptions: ProducerCodecOptions(opusStereo: 1, opusDtx: 1),
    //       source: 'mic',
    //     );
    //
    //   }
    // });

    // Produce our webcam video.
    Map<String, dynamic> mediaConstraints = <String, dynamic>{
      'audio': true,
      'video': false,
    };
    // var status = await Permission.microphone.request();
    // if (status.isDenied) {
    //   print('Microphone permission is denied');

    // }
    _localStream =
    await rtc.navigator.mediaDevices.getUserMedia(mediaConstraints);
    final MediaStreamTrack track = _localStream!.getAudioTracks().first;
    print("_sendTransport connected: ${_sendTransport?.connectionState}");
    _sendTransport!.produce(
      stream: _localStream!,
      track: track,
      appData: {
        'source': 'mic',
      },
      codecOptions: ProducerCodecOptions(opusStereo: 1, opusDtx: 1),
      source: 'mic',
    );
  }

  Future<void> _connectingTransport(Map<String, dynamic> data) async {
    if (svaraUserData!.isProducer && _sendTransport == null) {
      _sendTransport = device.createSendTransportFromMap(
        data[SvaraKeys.producerTransport],
        producerCallback: _producerCallback,
      );
      print("_sendTransport connecting: ${_sendTransport?.connectionState}");

      _sendTransport!.on(SvaraKeys.connect, (Map data) async {
        try {
          Map<String, dynamic> connectProducerTransportData = {
            SvaraKeys.transportId: _sendTransport!.id,
            SvaraKeys.dtlsParameters: data['dtlsParameters'].toMap(),
          };
          print("_sendTransport connect: ${_sendTransport?.connectionState}");

          _send(SvaraSyncType.connectProducerTransport,
              connectProducerTransportData);

          data['callback']();
        } catch (error) {
          // EMPTY CATCH BLOCK
        }
      });

      _sendTransport!.on(SvaraKeys.produce, (Map data) async {
        try {
          Map<String, dynamic> produceData = {
            SvaraKeys.transportId: _sendTransport!.id,
            SvaraKeys.kind: data['kind'],
            SvaraKeys.rtpParameters: data['rtpParameters'].toMap(),
            if (data['appData'] != null)
              SvaraKeys.appData: Map<String, dynamic>.from(data['appData'])
          };
          _send(SvaraSyncType.produce, produceData);

          data['callback'](_sendTransport!.id);
        } catch (error) {
          data['errback'](error);
        }
      });
      _produced();
    }
    if (svaraUserData!.isConsumer && _recTransport == null) {
      _recTransport = device.createRecvTransportFromMap(
          data[SvaraKeys.consumerTransport],
          consumerCallback: _consumerCallback);

      _recTransport!.on(SvaraKeys.connect, (Map data) async {
        try {
          Map<String, dynamic> consumerTransportData = {
            SvaraKeys.transportId: _recTransport!.id,
            SvaraKeys.dtlsParameters: data['dtlsParameters'].toMap(),
          };
          _send(SvaraSyncType.connectConsumerTransport, consumerTransportData);
          //  print('recverConnected done');
          data['callback']();
        } catch (error) {
          // print('recverConnected $error');
          data['errback'](error);
        }
      });

      _send(SvaraSyncType.connectEarlierProducer, {});
      //print('Receiving transport created');
    }
  }

  Future<void> _consumedProducers(Map<String, dynamic> data) async {
    List<dynamic> producersList = data[SvaraKeys.producerList];
    for (var producer in producersList) {
      _consume(producer);
    }
  }

  void _consume(var producer) {
    try {
      _recTransport!.consume(
        id: producer[SvaraKeys.id],
        producerId: producer[SvaraKeys.producerId],
        kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
        rtpParameters: RtpParameters.fromMap(producer[SvaraKeys.rtpParameters]),
        // appData: data['appData'],
        peerId: svaraUserData!.svaraUserId,
      );
    } catch (e) {
      // EMPTY CATCH BLOCK
    }
  }

  Future<void> _newProducerHandling(Map<String, dynamic> data) async {
    _consume(data[SvaraKeys.producers]);
  }

  Future<void> _newConsumerHandling(Map<String, dynamic> data) async {}

  void _manageMuteUnMuteCallback(Map<String, dynamic> data) {
    _eventHandler!
        .onUserMuteUnmute(data[SvaraKeys.svaraUserId], data[SvaraKeys.isMute]);
  }

  void _manageUserLeavedRoom(Map<String, dynamic> data) {
    _eventHandler!.onUserLeft(data[SvaraKeys.svaraUserId]);
  }

  void _manageOnRoomCreated(Map<String, dynamic> data) {
    svaraUserData = SvaraUserData.fromJson(data[SvaraKeys.userData]);
    _eventHandler!.onUserJoined(svaraUserData!);
    _eventHandler!.onRoomCreated(data[SvaraKeys.roomId]);
  }

  void _manageNewUserJoined(Map<String, dynamic> data) {
    _eventHandler!
        .onNewUserJoined(SvaraUserData.fromJson(data[SvaraKeys.userData]));
  }

  void _manageUserList(Map<String, dynamic> data) {
    List<SvaraUserData> svaraUsers = (data['user_list'] as List<dynamic>)
        .map((item) => SvaraUserData.fromJson(item as Map<String, dynamic>))
        .toList();
    _eventHandler!.onUserGetList(svaraUsers);
  }

  void _manageError(Map<String, dynamic> data) {
    leaveRoom('error');
    _eventHandler!.onRemoved();
    _eventHandler!.onError(data['error'], data['error_detail']);
  }

  void _manageWarn(Map<String, dynamic> data) {
    _eventHandler!.onWarning(data['warn']);
  }

  void _manageOnUserJoined(Map<String, dynamic> data) {
    svaraUserData = SvaraUserData.fromJson(data[SvaraKeys.userData]);
    _eventHandler!.onUserJoined(svaraUserData!);
  }

  void sendMsg(Map<String, dynamic> msgData) {
    _send(SvaraSyncType.sendTextMessage, msgData);
  }

  void _manageUserDataUpdated(Map<String, dynamic> data) {
    SvaraUserData userData = SvaraUserData.fromJson(data[SvaraKeys.svaraUser]);
    bool isItMe = svaraUserData!.svaraUserId == userData.svaraUserId;
    if (isItMe) {
      svaraUserData!.userData = userData.userData;
    }
    _eventHandler!.onUserDataChanged(userData, isItMe);
  }
}
