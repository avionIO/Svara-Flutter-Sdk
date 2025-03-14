# Svara - Flutter SDK

## Overview
Svara is a Flutter SDK that provides WebRTC-based real-time communication using the mediasoup framework. This package enables seamless video/audio streaming, room management, and user data handling for Flutter applications.

## Features
- WebRTC-based real-time audio/video communication
- Room creation and management
- User data handling and synchronization
- Mute/unmute functionality
- Producer and consumer transport management
- Event-based communication handling

## Getting Started
### Prerequisites
Ensure you have Flutter installed and set up properly. You can check the official Flutter installation guide [here](https://flutter.dev/docs/get-started/install).

### Installation
Add the following dependency to your `pubspec.yaml` file:

```yaml
dependencies:
  svara:
    git:
      url: https://github.com/avionIO/Svara-Flutter-Sdk
```

Then, run:
```sh
flutter pub get
```

## Usage
### Import the Package
```dart
import 'package:svara/svara.dart';
```

### Initialize Svara
```dart
Svara svara = Svara();

void main() {
  svara.create('yourAppId', 'yourSecretKey', YourEventHandler());
}
```

### Create a Room
```dart
svara.createRoom({
  'username': 'John Doe',
  'role': 'host',
});
```

### Join a Room
```dart
svara.joinRoom('roomId123', {
  'username': 'Jane Doe',
  'role': 'guest',
}, true, true);
```

### Mute/Unmute Microphone
```dart
svara.muteMic();
// To unmute
svara.unMuteMic();
```

### Leave Room
```dart
svara.leaveRoom("Leaving due to connection issue");
```

### End Room
```dart
svara.endRoom();
```

## Additional Information
### Contributing
Contributions are welcome! Please fork the repository and submit a pull request with your changes.

### Issues and Support
If you encounter any issues, please file a report on the [GitHub Issues](https://github.com/avionIO/Svara-Flutter-Sdk/issues) page.

### License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

Developed with ❤️ by Svara

