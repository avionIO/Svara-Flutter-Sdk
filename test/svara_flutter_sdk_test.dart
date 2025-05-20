// File: test/svara_services_test.dart
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
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
    print("Room created with ID: $roomId");
  }

  @override
  void onUserJoined(SvaraUserData userData) {
    userJoinedCalled = true;
    print("User joined: ${userData.svaraUserId}");
  }

  @override
  void onError(dynamic error, dynamic errorDetail) {
    errorCalled = true;
    print("Error occurred: $error, detail: $errorDetail");
  }

  @override
  void onUserGetList(List<SvaraUserData> users) {
    // Dummy implementation for testing purposes.
  }

  @override
  void onUserLeft(String userId) {
    print("User left: $userId");
  }

  @override
  void onNewUserJoined(SvaraUserData userData) {
    print("New user joined: ${userData.svaraUserId}");
  }

  @override
  void onUserMuteUnmute(String userId, bool isMute) {
    print("User $userId mute state changed to: $isMute");
  }

  @override
  void onUserDataChanged(SvaraUserData userData, bool isItMe) {
    print("User data changed for ${userData.svaraUserId}, is it me? $isItMe");
  }

  @override
  void onWarning(dynamic warn) {
    print("Warning: $warn");
  }

  @override
  void onRemoved() {
    print("User removed from the room");
  }
  
  @override
  void onRoomEnded() {
    // Sample implementation: log the event and update state.
    roomEndedCalled = true;
    print("Room has ended. Executing cleanup procedures.");
    // TODO: Add any additional room-ended handling logic here.
  }
  
  @override
  void onUserIsSpeaking(SvaraUserData svaraUserData, int volume) {
    // Sample implementation: log speaking status and record volume.
    userIsSpeakingCalled = true;
    lastVolume = volume;
    print("User ${svaraUserData.svaraUserId} is speaking at volume: $volume");
    // TODO: Integrate real-time UI updates or audio feedback logic here.
  }
  
  @override
  void receivedMessage(Map<String, dynamic> data) {
    // Sample implementation: store and log the received message.
    messageReceivedCalled = true;
    lastMessage = data;
    print("Received message: ${json.encode(data)}");
    // TODO: Process the message data as per application requirements.
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
      services.create('testAppId', 'testSecretKey', dummyHandler,false);
      expect(services.appId, equals('testAppId'));
      expect(services.secretKey, equals('testSecretKey'));
    });

    test('Join Room without Initialization Throws Error', () {
      // Force appId to null to simulate uninitialized service.
      services.appId = null;
      expect(
        () => services.joinRoom('roomId', {'name': 'testUser'}, true, true),
        throwsA(equals("Create the Svara Service")),
      );
    });

    test('Create Room without Initialization Throws Error', () {
      // Similar test for createRoom.
      services.appId = null;
      expect(
        () => services.createRoom({'name': 'testUser'}),
        throwsA(equals("Create the Svara Service")),
      );
    });

    // Additional tests should simulate incoming WebSocket messages,
    // verify resource cleanup, and test event callback behavior.
  });
}
