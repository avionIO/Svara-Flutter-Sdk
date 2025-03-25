import 'package:flutter/material.dart';
import 'package:svara_flutter_sdk/svara_flutter_sdk.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Svara Flutter SDK Example',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _status = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _initializeSdk();
  }

  Future<void> _initializeSdk() async {
    try {
      // Initialize the Svara SDK with dummy values and a simple event handler.
      SvaraServices().create(
        'yourAppId',
        'yourSecretKey',
        DummySvaraEventHandler(),
      );
      // Optionally join a room, create a room, or perform other actions:
      // SvaraServices().joinRoom('testRoom', {'name': 'ExampleUser'}, true, true);
      setState(() {
        _status = 'Svara SDK initialized successfully';
      });
    } catch (error) {
      setState(() {
        _status = 'Initialization error: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Svara SDK Example')),
      body: Center(
        child: Text(
          _status,
          style: const TextStyle(fontSize: 18),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// A simple dummy event handler for demonstration.
class DummySvaraEventHandler implements SvaraEventHandler {
  @override
  void onRoomCreated(String roomId) => print("Room created: $roomId");

  @override
  void onUserJoined(SvaraUserData userData) =>
      print("User joined: ${userData.svaraUserId}");

  @override
  void onError(dynamic error, dynamic errorDetail) =>
      print("Error: $error, Detail: $errorDetail");

  @override
  void onUserGetList(List<SvaraUserData> users) {}

  @override
  void onUserLeft(String userId) => print("User left: $userId");

  @override
  void onNewUserJoined(SvaraUserData userData) =>
      print("New user joined: ${userData.svaraUserId}");

  @override
  void onUserMuteUnmute(String userId, bool isMute) =>
      print("User $userId mute changed to $isMute");

  @override
  void onUserDataChanged(SvaraUserData userData, bool isItMe) => print(
    "User data changed for: ${userData.svaraUserId}, is it me? $isItMe",
  );

  @override
  void onWarning(dynamic warn) => print("Warning: $warn");

  @override
  void onRemoved() => print("Removed from room");

  @override
  void onRoomEnded() => print("Room has ended");

  @override
  void onUserIsSpeaking(SvaraUserData svaraUserData, int volume) => print(
    "User ${svaraUserData.svaraUserId} is speaking with volume: $volume",
  );

  @override
  void receivedMessage(Map<String, dynamic> data) =>
      print("Received message: $data");
}
