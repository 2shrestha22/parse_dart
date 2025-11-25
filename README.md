# Parse Dart SDK

A feature-complete Dart/Flutter SDK for Parse Server, providing a clean, type-safe API for authentication, data storage, queries, file uploads, and real-time updates.

## Features

- ✅ **Parse Objects** - Full CRUD operations with type safety
- ✅ **Parse Queries** - Powerful query builder with support for all query types
- ✅ **User Authentication** - Sign up, login, session management with automatic persistence
- ✅ **File Storage** - Upload and manage files with progress tracking
- ✅ **Access Control Lists (ACL)** - Fine-grained permissions
- ✅ **Relations** - Object relationships and relational queries
- ✅ **Cloud Functions** - Execute server-side Cloud Code
- ✅ **Operations** - Efficient field operations (Set, Increment, Add, Remove, etc.)
- ⚙️ **Storage Abstraction** - Bring your own storage implementation
- ⚙️ **WebSocket Abstraction** - Bring your own WebSocket for Live Query
- 🚧 **Live Queries** - Real-time data synchronization (in progress)
- 🚧 **Local Datastore** - Offline support with automatic sync (planned)


## Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  parse_dart: ^0.1.0
```

Then run:

```bash
dart pub get
```

## Quick Start

### Initialize the SDK

```dart
import 'package:parse_dart/parse_dart.dart';

void main() {
  Parse.initialize(
    applicationId: 'YOUR_APP_ID',
    serverUrl: 'https://your-parse-server.com/parse',
    clientKey: 'YOUR_CLIENT_KEY', // Optional
  );
}
```

### Create and Save Objects

```dart
class GameScore extends ParseObject {
  GameScore() : super('GameScore');
  
  int? get score => get<int>('score');
  set score(int? value) => set('score', value);
  
  String? get playerName => get<String>('playerName');
  set playerName(String? value) => set('playerName', value);
}

// Create and save
final gameScore = GameScore()
  ..score = 1337
  ..playerName = 'Sean Plott';

await gameScore.save();
print('Saved with objectId: ${gameScore.objectId}');
```

### Query Objects

```dart
final query = ParseQuery<GameScore>('GameScore')
  ..whereGreaterThan('score', 1000)
  ..orderByDescending('score')
  ..limit(10);

final results = await query.find();
for (final score in results) {
  print('${score.playerName}: ${score.score}');
}
```

### User Authentication

```dart
// Sign Up
final user = ParseUser()
  ..username = 'johndoe'
  ..password = 'secure123'
  ..email = 'john@example.com';

await user.signUp();

// Login
final loggedInUser = await ParseUser.login('johndoe', 'secure123');

// Get Current User
final currentUser = await ParseUser.currentUser();
```

### File Upload

```dart
final file = ParseFile.fromBytes(
  'profile.jpg',
  imageBytes,
  mimeType: 'image/jpeg',
);

await file.save(
  onProgress: (progress) {
    print('Upload progress: ${(progress * 100).toStringAsFixed(0)}%');
  },
);

print('File URL: ${file.url}');
```

### Cloud Functions

```dart
// Call a server-side cloud function
final score = await ParseCloud.run<int>(
  'calculateScore',
  parameters: {
    'userId': user.objectId,
    'level': 5,
  },
);
print('Score: $score');

// With authenticated user context
final stats = await ParseCloud.run<Map<String, dynamic>>(
  'getUserStats',
  options: ParseRequestOptions(sessionToken: user.sessionToken),
);
```


## Documentation

For complete documentation, visit: [Documentation Link]

## Platform Support

- ✅ Dart VM (Server-side)
- ✅ Flutter (iOS, Android, Web, Desktop)
- ✅ Web (Browser)

## Parse Server Compatibility

| Parse Dart SDK | Parse Server |
|----------------|--------------|
| 0.1.x          | >= 4.0.0     |

## Contributing

Contributions are welcome! Please read our [Contributing Guide](CONTRIBUTING.md) for details.

## License

Apache License 2.0 - see [LICENSE](LICENSE) for details.

## Related Projects

- [Parse JavaScript SDK](https://github.com/parse-community/Parse-SDK-JS) - The original JavaScript SDK
- [Parse Server](https://github.com/parse-community/parse-server) - The backend server

## Support

- [GitHub Issues](https://github.com/parse-community/Parse-SDK-JS/issues)
- [Community Forum](https://community.parseplatform.org/)
- [Stack Overflow](https://stackoverflow.com/questions/tagged/parse.com)
