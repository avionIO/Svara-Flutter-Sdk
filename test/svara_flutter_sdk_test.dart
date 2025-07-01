// File: test/svara_services_test.dart
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webrtc/src/native/rtc_video_renderer_impl.dart';
import 'package:svara_flutter_sdk/svara_flutter_sdk.dart'; // Public API export including SvaraServices

/// A dummy implementation of SvaraEventHandler for testing purposes.
/// This implementation simulates event responses with basic logging and state updates.
class DummySvaraEventHandler implements SvaraEventHandler {
  bool roomCreatedCalled = false;
  bool userJoinedCalled = false;
  bool errorCalled = false;
  bool roomEndedCalled = false;
  bool userIsSpeakingCalled = false;
  bool messageReceivedCalled = false;
  int lastVolume = 0;
  Map<String, dynamic>? lastMessage;

  @override
  void onRoomCreated(String roomId) {
    roomCreatedCalled = true;
    // Simulate some processing logic
  }

  @override
  void onUserJoined(SvaraUserData userData) {
    userJoinedCalled = true;
  }

  @override
  void onError(dynamic error, dynamic errorDetail) {
    errorCalled = true;
  }

  @override
  void onUserGetList(List<SvaraUserData> users) {
    // Dummy implementation for testing purposes.
  }

  @override
  void onUserLeft(String userId) {}

  @override
  void onNewUserJoined(SvaraUserData userData) {}

  @override
  void onUserMuteUnmute(String userId, bool isMute) {}

  @override
  void onUserDataChanged(SvaraUserData userData, bool isItMe) {}

  @override
  void onWarning(dynamic warn) {}

  @override
  void onRemoved() {}

  @override
  void onRoomEnded() {
    // Sample implementation: log the event and update state.
    roomEndedCalled = true;
    // TODO: Add any additional room-ended handling logic here.
  }

  @override
  void onUserIsSpeaking(SvaraUserData svaraUserData, int volume) {
    // Sample implementation: log speaking status and record volume.
    userIsSpeakingCalled = true;
    lastVolume = volume;
    // TODO: Integrate real-time UI updates or audio feedback logic here.
  }

  @override
  void receivedMessage(Map<String, dynamic> data) {
    // Sample implementation: store and log the received message.
    messageReceivedCalled = true;
    lastMessage = data;
    // TODO: Process the message data as per application requirements.
  }

  @override
  void onUserCameraToggled(String svaraUid, bool cameraOn) {
    // TODO: implement onUserCameraToggled
  }

  @override
  void updateVideoRender(String svaraUid, RTCVideoRenderer renderer) {
    // TODO: implement updateVideoRender
  }
}

void main() {
  // Group related tests for better organization.
  group('SvaraServices Tests', () {
    final dummyHandler = DummySvaraEventHandler();
    final services = SvaraServices();

    test('Singleton Instance Test', () {
      // Verify that SvaraServices returns a singleton.
      final instance1 = SvaraServices();
      final instance2 = SvaraServices();
      expect(instance1, same(instance2));
    });

    test('Create Service Sets Credentials', () {
      // Initialize the service with appId, secretKey, and an event handler.
      services.create(appId: 'testAppId', secretKey: "testScretKey");
      expect(services.appId, equals('testAppId'));
      expect(services.secretKey, equals('testSecretKey'));
    });

    test('Join Room without Initialization Throws Error', () {
      // Force appId to null to simulate uninitialized service.
      services.appId = null;
      expect(
        () => services.joinRoom(
          roomId: 'roomId',
        ),
        throwsA(equals("Create the Svara Service")),
      );
    });

    test('Create Room without Initialization Throws Error', () {
      // Similar test for createRoom.
      services.appId = null;
      expect(
        () => services.createRoom(),
        throwsA(equals("Create the Svara Service")),
      );
    });

    // Additional tests should simulate incoming WebSocket messages,
    // verify resource cleanup, and test event callback behavior.
  });
}
