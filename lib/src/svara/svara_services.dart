import 'dart:async';
import 'dart:convert';
import 'package:mediasfu_mediasoup_client/mediasfu_mediasoup_client.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:svara_flutter_sdk/src/svara/svara_event_handler.dart';
import 'package:svara_flutter_sdk/src/svara/svara_user_data.dart';
import 'package:web_socket_channel/status.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart' as rtc;
import 'svara_collection.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

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
  String? appId;
  String? secretKey;
  SvaraEventHandler? _eventHandler;

  bool audioOnly = false;
  factory SvaraServices() {
    return _instance;
  }

  void _setEventHandler(SvaraEventHandler eventHandler) {
    _eventHandler = eventHandler;
  }

  void create(String appId, String secretKey, SvaraEventHandler evenHandler,
      bool audioOnly) {
    this.appId = appId;
    this.audioOnly = audioOnly;
    this.secretKey = secretKey;
    _setEventHandler(evenHandler);
  }

  void _send(String type, Map<dynamic, dynamic> data) {
    final message = jsonEncode({SvaraKeys.type: type, SvaraKeys.data: data});
    _channel?.sink.add(message);
  }

  void joinRoom(String roomId, Map<String, dynamic> userData, bool isProducer,
      bool isConsumer, bool isCameraOn, bool isMute) {
    localRenderer.initialize();
    WakelockPlus.enable();

    if (appId != null) {
      _channel = WebSocketChannel.connect(
        Uri.parse(serverSvaraUrl),
        protocols: [appId!, secretKey!],
      );
      Map<String, dynamic> data = {
        SvaraKeys.roomId: roomId,
        SvaraKeys.userData: userData,
        SvaraKeys.isMute: isMute,
        SvaraKeys.cameraOn: isCameraOn,
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
    WakelockPlus.enable();

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
        onDone: () {
          _cleanup();
        },
        onError: (error) {
          _cleanup();
        },
      );
    } else {
      throw "Create the Svara Service";
    }
  }

  void _cleanup() {
    WakelockPlus.disable();
  }

  void endOperations() {
    try {
      _cleanup();
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
      case SvaraSyncType.ping:
        _send(SvaraSyncType.pong, {});
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
      case SvaraSyncType.cameraToggleCallback:
        _manageCameraToggleCallback(decodedMessage[SvaraKeys.data]);
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
    } catch (e) {}
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

  void cameraOn() {
    Map<String, dynamic> cameraUser = {
      SvaraKeys.cameraOn: true,
    };
    svaraUserData!.cameraOn = true;
    _localStream!.getVideoTracks().first.enabled = true;
    _send(SvaraSyncType.toggleCamera, cameraUser);
  }

  void cameraOff() {
    Map<String, dynamic> cameraUser = {
      SvaraKeys.cameraOn: false,
    };
    svaraUserData!.cameraOn = false;
    _localStream!.getVideoTracks().first.enabled = false;
    _send(SvaraSyncType.toggleCamera, cameraUser);
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

  void _consumerCallback(Consumer consumer, var arguments) async {
    ScalabilityMode.parse(
        consumer.rtpParameters.encodings.first.scalabilityMode);
    if (consumer.kind == 'video') {
      final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
      await _remoteRenderer.initialize();
      final MediaStreamTrack track = consumer.track;

      final MediaStream remoteStream =
          await rtc.createLocalMediaStream('remote');
      await remoteStream.addTrack(track);
      _remoteRenderer.srcObject = remoteStream;

      _eventHandler!.updateVideoRender(
          consumer.appData[SvaraKeys.svaraUserId] ?? "", _remoteRenderer);
      // You should now store or display this renderer in your UI
    }
  }

  void _producerCallback(Producer producer) {
    /* Your code. */
  }

  Future<void> _produceAudio() async {
    // Produce our webcam video.
    Map<String, dynamic> mediaConstraints = <String, dynamic>{
      'audio': {
        'mandatory': {
          'echoCancellation': true,
          'googAutoGainControl': true,
          'googNoiseSuppression': true,
          'googHighpassFilter': true,
          'latency': 0.0,
        },
        'optional': [],
      },
      'video': false,
    };

    var status = await Permission.microphone.request();
    if (status.isDenied) {}
    _localStream =
        await rtc.navigator.mediaDevices.getUserMedia(mediaConstraints);

    final MediaStreamTrack track = _localStream!.getAudioTracks().first;
    localRenderer.srcObject = _localStream;

    var producerCodecOptions = ProducerCodecOptions(
        opusStereo: 0,
        opusDtx: 1,
        opusFec: 1,
        opusMaxPlaybackRate: 48000,
        opusMaxAverageBitrate: 32000);
    _sendTransport!.produce(
      stream: _localStream!,
      track: track,
      appData: {
        'source': 'mic',
      },
      codecOptions: producerCodecOptions,
      source: 'mic',
    );
  }

  Future<void> _produceCamera() async {
    // Produce our webcam video.
    Map<String, dynamic> mediaConstraints = <String, dynamic>{
      'audio': {
        'mandatory': {
          'echoCancellation': true,
          'googAutoGainControl': true,
          'googNoiseSuppression': true,
          'googHighpassFilter': true,
          'latency': 0.0,
        },
        'optional': [],
      },
      'video': {
        'mandatory': {
          'minWidth': '160',
          'minHeight': '120',
          'maxWidth': '320',
          'maxHeight': '240',
          'maxFrameRate': '5',
        },
        'facingMode': 'user',
        'optional': [],
      },
    };

    var status = await Permission.microphone.request();
    final camStatus = await Permission.camera.request();
    if (status.isDenied || camStatus.isDenied) {}

    _localStream =
        await rtc.navigator.mediaDevices.getUserMedia(mediaConstraints);

    _localStream!.getVideoTracks().first.enabled = svaraUserData!.cameraOn;

    final MediaStreamTrack track = _localStream!.getAudioTracks().first;
    final MediaStreamTrack videoTrack = _localStream!.getVideoTracks().first;

    localRenderer.srcObject = _localStream;

    _eventHandler!
        .updateVideoRender(svaraUserData?.svaraUserId ?? "", localRenderer);

    // Produce video
    _sendTransport!.produce(
      stream: _localStream!,
      track: videoTrack,
      // encodings: [RtpEncodingParameters(maxBitrate: 1000000)],
      appData: {
        'source': 'webcam',
      },
      source: 'webcam',
    );

    var producerCodecOptions = ProducerCodecOptions(
        opusStereo: 0,
        opusDtx: 1,
        opusFec: 1,
        opusMaxPlaybackRate: 48000,
        opusMaxAverageBitrate: 32000);
    _sendTransport!.produce(
      stream: _localStream!,
      track: track,
      appData: {
        'source': 'mic',
      },
      codecOptions: producerCodecOptions,
      source: 'mic',
    );
  }

  Future<void> _connectingTransport(Map<String, dynamic> data) async {
    if (svaraUserData!.isProducer && _sendTransport == null) {
      _sendTransport = device.createSendTransportFromMap(
        data[SvaraKeys.producerTransport],
        producerCallback: _producerCallback,
      );
      _sendTransport!.on(SvaraKeys.connect, (Map data) async {
        try {
          Map<String, dynamic> connectProducerTransportData = {
            SvaraKeys.transportId: _sendTransport!.id,
            SvaraKeys.dtlsParameters: data['dtlsParameters'].toMap(),
          };
          _send(SvaraSyncType.connectProducerTransport,
              connectProducerTransportData);

          data['callback']();
        } catch (error) {
          // EMPTY CATCH BLOCK
          data['errback'](error);
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
      if (audioOnly) {
        _produceAudio();
      } else {
        _produceCamera();
      }
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
          data['callback']();
        } catch (error) {
          data['errback'](error);
        }
      });

      _send(SvaraSyncType.connectEarlierProducer, {});
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
      final String kind =
          producer[SvaraKeys.kind] ?? 'audio'; // Default to audio if missing
      final RTCRtpMediaType mediaType;

      if (kind == 'audio') {
        mediaType = RTCRtpMediaType.RTCRtpMediaTypeAudio;
      } else {
        mediaType = RTCRtpMediaType.RTCRtpMediaTypeVideo;
      }
      _recTransport!.consume(
        id: producer[SvaraKeys.id],
        producerId: producer[SvaraKeys.producerId],
        kind: mediaType,
        rtpParameters: RtpParameters.fromMap(producer[SvaraKeys.rtpParameters]),
        appData: {SvaraKeys.svaraUserId: producer[SvaraKeys.svaraUserId]},
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

  void _manageCameraToggleCallback(Map<String, dynamic> data) {
    _eventHandler!.onUserCameraToggled(
        data[SvaraKeys.svaraUserId], data[SvaraKeys.cameraOn]);
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
