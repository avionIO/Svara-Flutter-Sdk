import 'dart:convert';
import 'package:get/get.dart';
import 'package:mediasfu_mediasoup_client/mediasfu_mediasoup_client.dart';
import 'package:svara_flutter_sdk/src/avion/avion_event_handler.dart';
import 'package:svara_flutter_sdk/src/avion/avion_user_data.dart';
import 'package:web_socket_channel/status.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'avion_collection.dart';

class AvionServices {
  static final AvionServices _instance = AvionServices._internal();
  WebSocketChannel? _channel;
  Device device = Device();
  Transport? _sendTransport;
  Transport? _recTransport;
  rtc.RTCVideoRenderer localRenderer = rtc.RTCVideoRenderer();
  rtc.MediaStream? _localStream;
  Rx<AvionUserData>? avionUserData;

  AvionServices._internal();

  factory AvionServices() {
    return _instance;
  }

  String? appId;
  String? secretKey;
  AvionEventHandler? _eventHandler;

  void _setEventHandler(AvionEventHandler eventHandler) {
    _eventHandler = eventHandler;
  }

  void create(String appId,String secretKey, AvionEventHandler evenHandler) {
    this.appId = appId;
    this.secretKey = secretKey;
    _setEventHandler(evenHandler);
  }

  void _send(String type, Map<dynamic, dynamic> data) {
    final message = jsonEncode({AvionKeys.type: type, AvionKeys.data: data});
    _channel?.sink.add(message);
  }

  void joinRoom(String roomId, Map<String, dynamic> userData, bool isProducer,
      bool isConsumer) {
    localRenderer.initialize();

    if (appId != null) {
      _channel = WebSocketChannel.connect(
        Uri.parse(serverAvionUrl),
        protocols: [appId!,secretKey!],
      );
      Map<String, dynamic> data = {
        AvionKeys.roomId: roomId,
        AvionKeys.userData: userData,
        AvionKeys.isMute: false,
        AvionKeys.isConsumer: isConsumer,
        AvionKeys.isProducer: isProducer,
      };
      _send(AvionSyncType.joinRoom, data);
      _channel!.stream.listen(_onMessage);
    } else {
      throw "Create the Avion Service";
    }
  }

  void createRoom(Map<String, dynamic> userData) {
    localRenderer.initialize();

    if (appId != null) {

      _channel = WebSocketChannel.connect(
        Uri.parse(serverAvionUrl),
        protocols: [appId!,secretKey!],
      );
      Map<String, dynamic> data = {
        AvionKeys.userData: userData,
      };
      _send(AvionSyncType.createRoom, data);
      _channel!.stream.listen(_onMessage, onDone: () {
        print("WebSocket connection closed. Attempting to reconnect...");

      }, onError:  (error) {
        print("WebSocket error: $error. Attempting to reconnect...");

      },
      );
    } else {
      throw "Create the Avion Service";
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
      print('Disconnecting from room');
    } catch (e) {
      print('Failed to leave $e');
    }
  }

  void leaveRoom(String reason) {
    _send(AvionSyncType.leaveRoom, {AvionKeys.editor: reason});
    endOperations();
  }

  void _manageRoomEnded() {
    _eventHandler!.onRoomEnded();
    endOperations();
  }

  void removeUser(String removingUserId) {
    _send(AvionSyncType.removeUser, {AvionKeys.avionUserId: removingUserId});
  }

  void updateUserData(String avionUserId, Map<String, dynamic> me) {
    _send(AvionSyncType.updateUserData,
        {AvionKeys.userData: me, AvionKeys.avionUserId: avionUserId});
  }

  void _onMessage(dynamic message) async {
    final decodedMessage = json.decode(message);
   // printLongString("Received Avion Connection Response: $message");
    switch (decodedMessage[AvionKeys.type]) {
      case AvionSyncType.routerRtpCapabilities:

        ///Receives Rtp Capabilities from serve
        ///load it into the device and send device sctpCapabilities with weather producing or consuming
        await _setRouterRtpCapabilities(decodedMessage[AvionKeys.data]);
        break;
      case AvionSyncType.createdRoom:
        _manageOnRoomCreated(decodedMessage[AvionKeys.data]);
        break;
      case AvionSyncType.onUserJoined:
        _manageOnUserJoined(decodedMessage[AvionKeys.data]);
        break;
      case AvionSyncType.createdTransport:

        ///Called when a producerTransport is created
        await _connectingTransport(decodedMessage[AvionKeys.data]);
        break;
      case AvionSyncType.connectedConsumerTransport:

        ///Called when a consumerTransport is created
        await _consumedProducers(decodedMessage[AvionKeys.data]);
        break;
      case AvionSyncType.connectedProducerTransport:

        ///Called when a ProducerTransport is created
        break;
      case AvionSyncType.usersList:
        _manageUserList(decodedMessage[AvionKeys.data]);
        break;
      case AvionSyncType.newUserJoined:
        _manageNewUserJoined(decodedMessage[AvionKeys.data]);
        break;
      case AvionSyncType.newProducerUser:
        await _newProducerHandling(decodedMessage[AvionKeys.data]);
        break;
      case AvionSyncType.userDataUpdated:
        _manageUserDataUpdated(decodedMessage[AvionKeys.data]);
        break;
      case AvionSyncType.newConsumerUser:
        await _newConsumerHandling(decodedMessage[AvionKeys.data]);
        break;
      case AvionSyncType.muteUnMuteCallback:
        _manageMuteUnMuteCallback(decodedMessage[AvionKeys.data]);
        break;
      case AvionSyncType.userLeavedRoom:
        _manageUserLeavedRoom(decodedMessage[AvionKeys.data]);
        break;
      case AvionSyncType.removeMe:
        _manageRemoveMe(decodedMessage[AvionKeys.data]);
        break;
      case AvionSyncType.receiveTextMessage:
        _manageReceiveMessage(decodedMessage[AvionKeys.data]);
        break;
      case AvionSyncType.roomEnded:
        _manageRoomEnded();
        break;
      case AvionSyncType.error:
        _manageError(decodedMessage[AvionKeys.data]);
        break;
      case AvionSyncType.warn:
        _manageWarn(decodedMessage[AvionKeys.data]);
        break;
    }
  }

  void _manageReceiveMessage(Map<String, dynamic> data) {
    print(data);
    _eventHandler!.receivedMessage(data);
  }

  void _manageRemoveMe(Map<String, dynamic> data) {
    _eventHandler!.onRemoved();
    leaveRoom(data[AvionKeys.editor]);
  }

  void removeProducer() {
    try {
      Map<String, dynamic> sendingData = {
        AvionKeys.avionUserId: avionUserData!.value.avionUserId,
        AvionKeys.producerId: _sendTransport!.id,
      };
      _send(AvionSyncType.removeProducer, sendingData);
      _sendTransport!.close();
      _sendTransport = null;
      avionUserData!.value.isProducer = false;
    } catch (e) {
      print("Failed to close _senderTransport $e");
    }
  }

  void muteMic() {
    Map<String, dynamic> muteUserData = {
      AvionKeys.isMute: true,
    };
    avionUserData!.value.isMute.value = true;
    _localStream!.getAudioTracks().first.enabled = false;
    _send(AvionSyncType.muteUnMuteUser, muteUserData);
  }

  void unMuteMic() {
    Map<String, dynamic> muteUserData = {
      AvionKeys.isMute: false,
    };
    avionUserData!.value.isMute.value = false;
    _localStream!.getAudioTracks().first.enabled = true;
    _send(AvionSyncType.muteUnMuteUser, muteUserData);
  }

  void createProducerTransport() {
    avionUserData!.value.isProducer = true;
    Map<String, dynamic> createTransportData = {
      AvionKeys.sctpCapabilities: device.sctpCapabilities.toMap(),
      AvionKeys.rtpCapabilities: device.rtpCapabilities.toMap()
    };
    _send(AvionSyncType.createProducerTransport, createTransportData);
  }

  void getUserList() {
    _send(AvionSyncType.getUsersList, {});
  }

  void endRoom() {
    _send(AvionSyncType.endRoom, {});
  }

  Future<void> _setRouterRtpCapabilities(Map<String, dynamic> data) async {
    try {
      var routerRtpCapabilities =
          RtpCapabilities.fromMap(data[AvionKeys.routerRtpCapabilities]);
      await device.load(routerRtpCapabilities: routerRtpCapabilities);
      print('loaded rtp Capabilities');

      Map<String, dynamic> createTransportData = {
        AvionKeys.sctpCapabilities: device.sctpCapabilities.toMap(),
        AvionKeys.rtpCapabilities: device.rtpCapabilities.toMap()
      };
      _send(AvionSyncType.createTransport, createTransportData);
    } catch (e) {
      print('Failed in setting RouterRtpCapabilities');
      leaveRoom('client');
    }
  }

  void _consumerCallback(Consumer consumer, var arguments) {
    /* Your code. */
    print('New consumer created: ${consumer.id}');
  }

  void _producerCallback(Producer producer) {
    /* Your code. */

    print('New producer created: ${producer.id}');
  }

  Future<void> _produced() async {
    // Produce our webcam video.
    Map<String, dynamic> mediaConstraints = <String, dynamic>{
      'audio': true,
      'video': false,
    };
    // var status = await Permission.microphone.request();
    // if (status.isDenied) {
    //   print('Microphone permission is denied');
    //   ///TODO end the call
    // }
    _localStream =
        await rtc.navigator.mediaDevices.getUserMedia(mediaConstraints);
    final MediaStreamTrack track = _localStream!.getAudioTracks().first;
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
    print(
        'connectingTransport ${avionUserData!.value.isProducer && _sendTransport == null}');
    print('${avionUserData!.value.isConsumer && _recTransport == null}');
    if (avionUserData!.value.isProducer && _sendTransport == null) {
      _sendTransport = device.createSendTransportFromMap(
        data[AvionKeys.producerTransport],
        producerCallback: _producerCallback,
      );
      print('Transport created ${_sendTransport!.id}');

      _sendTransport!.on(AvionKeys.connect, (Map data) async {
        try {
          print(' creating transport: ${data['dtlsParameters'].toMap()}');

          Map<String, dynamic> connectProducerTransportData = {
            AvionKeys.transportId: _sendTransport!.id,
            AvionKeys.dtlsParameters: data['dtlsParameters'].toMap(),
          };

          _send(AvionSyncType.connectProducerTransport,
              connectProducerTransportData);

          print(' created transport: ');

          data['callback']();
        } catch (error) {
          print('Error creating transport: $error');
        }
      });
      _sendTransport!.on(AvionKeys.produce, (Map data) async {
        try {
          print('_transportProduced $data');

          Map<String, dynamic> produceData = {
            AvionKeys.transportId: _sendTransport!.id,
            AvionKeys.kind: data['kind'],
            AvionKeys.rtpParameters: data['rtpParameters'].toMap(),
            if (data['appData'] != null)
              AvionKeys.appData: Map<String, dynamic>.from(data['appData'])
          };
          _send(AvionSyncType.produce, produceData);

          data['callback']();
        } catch (error) {
          data['errback'](error);
          print("_transportProducing error $error");
        }
      });
      _produced();
    }
    if (avionUserData!.value.isConsumer && _recTransport == null) {
      _recTransport = device.createRecvTransportFromMap(
          data[AvionKeys.consumerTransport],
          consumerCallback: _consumerCallback);

      _recTransport!.on(AvionKeys.connect, (Map data) async {
        try {
          print('recverConnected');

          Map<String, dynamic> consumerTransportData = {
            AvionKeys.transportId: _recTransport!.id,
            AvionKeys.dtlsParameters: data['dtlsParameters'].toMap(),
          };
          _send(AvionSyncType.connectConsumerTransport, consumerTransportData);
        //  print('recverConnected done');
          data['callback']();
        } catch (error) {
         // print('recverConnected $error');
          data['errback'](error);
        }
      });

      _send(AvionSyncType.connectEarlierProducer, {});
      //print('Receiving transport created');
    }
  }

  Future<void> _consumedProducers(Map<String, dynamic> data) async {
    List<dynamic> producersList = data[AvionKeys.producerList];
    for (var producer in producersList) {
      _consume(producer);
    }
  }

  void _consume(var producer) {
    try {
      _recTransport!.consume(
        id: producer[AvionKeys.id],
        producerId: producer[AvionKeys.producerId],
        kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
        rtpParameters: RtpParameters.fromMap(producer[AvionKeys.rtpParameters]),
        // appData: data['appData'],
        peerId: avionUserData!.value.avionUserId,
      );
      print('Added consume');
    } catch (e) {
      print('Error handling consumed message: $e');
    }
  }

  Future<void> _newProducerHandling(Map<String, dynamic> data) async {
    _consume(data[AvionKeys.producers]);
  }

  Future<void> _newConsumerHandling(Map<String, dynamic> data) async {}

  void _manageMuteUnMuteCallback(Map<String, dynamic> data) {
    _eventHandler!
        .onUserMuteUnmute(data[AvionKeys.avionUserId], data[AvionKeys.isMute]);
  }

  void _manageUserLeavedRoom(Map<String, dynamic> data) {
    _eventHandler!.onUserLeft(data[AvionKeys.avionUserId]);
  }

  void _manageOnRoomCreated(Map<String, dynamic> data) {
    avionUserData = AvionUserData.fromJson(data[AvionKeys.userData]).obs;
    _eventHandler!.onUserJoined(avionUserData!.value);
    _eventHandler!.onRoomCreated(data[AvionKeys.roomId]);
  }

  void _manageNewUserJoined(Map<String, dynamic> data) {
    _eventHandler!
        .onNewUserJoined(AvionUserData.fromJson(data[AvionKeys.userData]));
  }

  void _manageUserList(Map<String, dynamic> data) {
    List<AvionUserData> avionUsers = (data['user_list'] as List<dynamic>)
        .map((item) => AvionUserData.fromJson(item as Map<String, dynamic>))
        .toList();
    _eventHandler!.onUserGetList(avionUsers);
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
    avionUserData = AvionUserData.fromJson(data[AvionKeys.userData]).obs;
    _eventHandler!.onUserJoined(avionUserData!.value);
  }

  void sendMsg(Map<String, dynamic> msgData) {
    _send(AvionSyncType.sendTextMessage, msgData);
  }

  void _manageUserDataUpdated(Map<String, dynamic> data) {
    AvionUserData userData = AvionUserData.fromJson(data[AvionKeys.avionUser]);
    bool isItMe = avionUserData!.value.avionUserId == userData.avionUserId;
    if (isItMe) {
      avionUserData!.value.userData.value = userData.userData;
    }
    _eventHandler!.onUserDataChanged(userData, isItMe);
  }
}
