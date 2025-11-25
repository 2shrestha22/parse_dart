# JavaScript to Dart Conversion Reference

This document shows common patterns for converting Parse JS SDK code to the Dart SDK.

## Initialization

### JavaScript
```javascript
Parse.initialize("YOUR_APP_ID", "YOUR_JAVASCRIPT_KEY");
Parse.serverURL = 'https://your-server.com/parse';
```

### Dart
```dart
Parse.initialize(
  applicationId: 'YOUR_APP_ID',
  clientKey: 'YOUR_CLIENT_KEY',
  serverUrl: 'https://your-server.com/parse',
);
```

##  Creating Objects

### JavaScript
```javascript
const GameScore = Parse.Object.extend("GameScore");
const gameScore = new GameScore();
gameScore.set("score", 1337);
gameScore.set("playerName", "Sean Plott");
await gameScore.save();
```

### Dart
```dart
class GameScore extends ParseObject {
  GameScore() : super('GameScore');
  
  int? get score => get<int>('score');
  set score(int? value) => set('score', value);
  
  String? get playerName => get<String>('playerName');
  set playerName(String? value) => set('playerName', value);
}

final gameScore = GameScore()
  ..score = 1337
  ..playerName = 'Sean Plott';
await gameScore.save();
```

## Querying

### JavaScript
```javascript
const query = new Parse.Query(GameScore);
query.equalTo("playerName", "Dan Stemkoski");
query.greaterThan("score", 1000);
const results = await query.find();
```

### Dart
```dart
final query = ParseQuery<GameScore>('GameScore')
  ..whereEqualTo('playerName', 'Dan Stemkoski')
  ..whereGreaterThan('score', 1000);
final results = await query.find();
```

## User Authentication

### JavaScript
```javascript
const user = new Parse.User();
user.set("username", "my name");
user.set("password", "my pass");
user.set("email", "email@example.com");
await user.signUp();

// Login
const user = await Parse.User.logIn("myname", "mypass");

// Current user
const currentUser = Parse.User.current();
```

### Dart
```dart
final user = ParseUser()
  ..username = 'my name'
  ..password = 'my pass'
  ..email = 'email@example.com';
await user.signUp();

// Login  
final user = await ParseUser.login('myname', 'mypass');

// Current user
final currentUser = await ParseUser.currentUser();
```

## GeoPoints

### JavaScript
```javascript
const point = new Parse.GeoPoint(37.75, -122.68);
object.set("location", point);

// Distance
const distanceInKm = point.kilometersTo(anotherPoint);
const distanceInMiles = point.milesTo(anotherPoint);
```

### Dart
```dart
final point = ParseGeoPoint(37.75, -122.68);
object.set('location', point);

// Distance
final distanceInKm = point.distanceTo(anotherPoint);
final distanceInMiles = point.distanceToInMiles(anotherPoint);
```

## Files

### JavaScript
```javascript
const file = new Parse.File("resume.txt", { base64: base64 });
await file.save();
console.log(file.url());
```

### Dart
```dart
final file = ParseFile.fromBytes('resume.txt', bytes);
await file.save();
print(file.url);
```

## ACL

### JavaScript
```javascript
const acl = new Parse.ACL();
acl.setPublicReadAccess(true);
acl.setWriteAccess(Parse.User.current().id, true);
object.setACL(acl);
```

### Dart
```dart
final acl = ParseACL()
  ..setPublicReadAccess(true)
  ..setWriteAccess(await ParseUser.currentUser()!.objectId!, true);
object.setACL(acl);
```

## Cloud Functions

### JavaScript
```javascript
const result = await Parse.Cloud.run("hello", { name: "Nelson" });
```

### Dart
```dart
final result = await ParseCloud.run('hello', params: {'name': 'Nelson'});
```

## LiveQuery

### JavaScript
```javascript
const query = new Parse.Query('GameScore');
const subscription = await query.subscribe();

subscription.on('create', (object) => {
  console.log('New game score!', object.get('score'));
});

subscription.on('update', (object) => {
  console.log('Updated score!', object.get('score'));
});
```

### Dart
```dart
final query = ParseQuery<GameScore>('GameScore');
final subscription = await query.subscribe();

subscription.on(LiveQueryEvent.create, (object) {  
  print('New game score! ${object.score}');
});

subscription.on(LiveQueryEvent.update, (object) {
  print('Updated score! ${object.score}');
});
```

## Key Differences

### 1. No Dynamic Property Access

**JavaScript:**
```javascript
object.myCustomField = "value";
const value = object.myCustomField;
```

**Dart:**
```dart
// Must use getter/setter methods
object.set('myCustomField', 'value');
final value = object.get<String>('myCustomField');
```

### 2. Strong Typing

**JavaScript:**
```javascript
const number = object.get("score"); // Could be anything
```

**Dart:**
```dart
final number = object.get<int>('score'); // Type-safe!
```

### 3. Async/Await

Both use async/await, but Dart uses `Future` instead of `Promise`:

**JavaScript:**
```javascript
async function fetchData() {
  const result = await query.find();
  return result;
}
```

**Dart:**
```dart
Future<List<GameScore>> fetchData() async {
  final result = await query.find();
  return result;
}
```

### 4. Null Safety

Dart has null safety built-in:

**Dart:**
```dart
String? username; // Can be null
String email = ''; // Cannot be null

final user = await ParseUser.currentUser();
if (user != null) {
  print(user.username);
}

// Or use null-aware operator
print(user?.username ?? 'No username');
```

### 5. Class Extensions

**JavaScript:**
```javascript
const Monster = Parse.Object.extend("Monster");
```

**Dart:**
```dart
class Monster extends ParseObject {
  Monster() : super('Monster');
  
  // Add typed properties
  String? get name => get<String>('name');
  set name(String? value) => set('name', value);
}
```

### 6. Promises vs Futures

**JavaScript:**
```javascript
query.find()
  .then(results => console.log(results))
  .catch(error => console.error(error));
```

**Dart:**
```dart
query.find()
  .then((results) => print(results))
  .catchError((error) => print(error));

// Or better, use async/await:
try {
  final results = await query.find();
  print(results);
} catch (error) {
  print(error);
}
```

## Error Handling

### JavaScript
```javascript
try {
  await object.save();
} catch (error) {
  console.log(error.code, error.message);
}
```

### Dart
```dart
try {
  await object.save();
} on ParseException catch (error) {
  print('${error.code}: ${error.message}');
}
```

## Configuration

### JavaScript
```javascript
Parse.liveQueryServerURL = 'ws://localhost:1337';
Parse.CoreManager.set('REQUEST_ATTEMPT_LIMIT', 5);
```

### Dart
```dart
Parse.initialize(
  // ...
  liveQueryUrl: 'ws://localhost:1337',
);

Parse.requestAttemptLimit = 5;
```
