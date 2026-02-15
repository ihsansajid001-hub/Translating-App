# 🌍 Real-Time Translator - Flutter App

Cross-platform mobile and desktop app for real-time speech translation.

## ✨ Features

- 🎤 Real-time speech-to-text
- 🌐 Translation between 15 languages
- 🔊 Text-to-speech output
- 📱 Works on Android, iOS, Windows, macOS, Web
- 🔒 Secure authentication
- 💾 Offline mode with message queue
- 📊 Real-time latency indicators

## 🚀 Quick Start

### Prerequisites
- Flutter SDK 3.0+
- Dart 3.0+
- Android Studio / Xcode (for mobile)
- Backend server running

### Setup

1. **Install dependencies**
```bash
flutter pub get
```

2. **Configure environment**
```bash
# Copy .env.example to .env
cp .env .env.local

# Edit .env with your backend URLs
API_BASE_URL=http://your-backend-url/api/v1
WS_URL=ws://your-backend-url
```

3. **Run the app**
```bash
# Mobile (Android/iOS)
flutter run

# Web
flutter run -d chrome

# Desktop (Windows/macOS)
flutter run -d windows
flutter run -d macos
```

## 📱 Build for Production

### Android
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### iOS
```bash
flutter build ios --release
# Then open in Xcode and archive
```

### Windows
```bash
flutter build windows --release
```

### macOS
```bash
flutter build macos --release
```

### Web
```bash
flutter build web --release
# Deploy the build/web folder
```

## 🏗️ Project Structure

```
lib/
├── core/
│   ├── di/              # Dependency injection
│   ├── routes/          # Navigation
│   ├── services/        # Core services (API, WebSocket, Audio, Storage)
│   └── theme/           # App theme
├── features/
│   ├── auth/            # Authentication
│   ├── home/            # Home screen
│   ├── session/         # Session management
│   ├── translation/     # Main translation feature
│   ├── profile/         # User profile
│   └── history/         # Translation history
└── main.dart            # App entry point
```

## 🔧 Configuration

### Android Permissions
Add to `android/app/src/main/AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS"/>
```

### iOS Permissions
Add to `ios/Runner/Info.plist`:
```xml
<key>NSMicrophoneUsageDescription</key>
<string>We need microphone access for speech translation</string>
```

## 🎨 Customization

### Change Theme
Edit `lib/core/theme/app_theme.dart`

### Add Languages
Edit language lists in:
- `lib/features/session/screens/create_session_screen.dart`
- `lib/features/session/screens/join_session_screen.dart`

## 🐛 Troubleshooting

### WebSocket Connection Issues
- Check backend URL in `.env`
- Ensure backend is running
- Check firewall settings

### Audio Recording Issues
- Grant microphone permissions
- Check device audio settings
- Test on real device (not emulator)

### Build Issues
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

## 📚 Dependencies

- **provider**: State management
- **dio**: HTTP client
- **socket_io_client**: WebSocket communication
- **record**: Audio recording
- **audioplayers**: Audio playback
- **shared_preferences**: Local storage
- **google_fonts**: Custom fonts

## 🚀 Deployment

### Google Play Store
1. Build release APK
2. Create app in Play Console
3. Upload APK
4. Fill store listing
5. Submit for review

### Apple App Store
1. Build release IPA
2. Create app in App Store Connect
3. Upload via Xcode
4. Fill store listing
5. Submit for review

## 📄 License

MIT License - see LICENSE file

## 🙏 Support

For issues and questions:
- GitHub Issues
- Email: support@yourdomain.com

---

Built with ❤️ using Flutter
