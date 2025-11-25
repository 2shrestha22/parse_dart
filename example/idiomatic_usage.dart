import 'package:parse_dart/parse_dart.dart';

/// Example demonstrating convenient Dart patterns for ParseObject
///
/// These patterns let you use ParseObject efficiently while keeping
/// your own model classes for business logic.

// ============================================================================
// Pattern 1: Factory Constructor with Data
// ============================================================================

void exampleWithDataFactory() async {
  print('=== Pattern 1: withData() Factory ===');

  // Create object with initial data in one call
  final gameScore = ParseObject.withData('GameScore', {
    'playerName': 'John Doe',
    'score': 1337,
    'cheatMode': false,
  });

  print('Created: ${gameScore.get<String>('playerName')}');
  // await gameScore.save();
}

// ============================================================================
// Pattern 2: setAll() Extension Method
// ============================================================================

void exampleSetAllExtension() async {
  print('\n=== Pattern 2: setAll() Extension ===');

  // Use setAll() for map-based initialization
  final gameScore = ParseObject('GameScore').setAll({
    'playerName': 'Jane Doe',
    'score': 2000,
    'cheatMode': false,
  });

  // Can combine with cascade notation:
  final post = ParseObject('Post')
    ..setAll({
      'title': 'My Post',
      'content': 'Content here',
    })
    ..setACL(ParseACL()..setPublicReadAccess(true));

  print('Created post: ${post.get<String>('title')}');
  // await post.save();
}

// ============================================================================
// Pattern 3: Cascade Notation
// ============================================================================

void exampleCascadeNotation() async {
  print('\n=== Pattern 3: Cascade Notation ===');

  // Use Dart's cascade operator for fluent API
  final gameScore = ParseObject('GameScore')
    ..set('playerName', 'Alice')
    ..set('score', 3000)
    ..set('cheatMode', false);

  // Works great with ACL:
  final post = ParseObject('Post')
    ..set('title', 'Hello World')
    ..set('content', 'My first post')
    ..setACL(ParseACL()
      ..setPublicReadAccess(true)
      ..setPublicWriteAccess(false));

  print('Created: ${gameScore.get<String>('playerName')}');
  // await post.save();
}

// ============================================================================
// Working with Your Own Models
// ============================================================================

/// Your own model class for business logic
class GameScoreModel {
  final String playerName;
  final int score;
  final bool cheatMode;

  GameScoreModel({
    required this.playerName,
    required this.score,
    required this.cheatMode,
  });

  /// Convert your model to ParseObject for saving
  ParseObject toParseObject() {
    return ParseObject.withData('GameScore', {
      'playerName': playerName,
      'score': score,
      'cheatMode': cheatMode,
    });
  }

  /// Create your model from ParseObject
  factory GameScoreModel.fromParseObject(ParseObject obj) {
    return GameScoreModel(
      playerName: obj.get<String>('playerName') ?? '',
      score: obj.get<int>('score') ?? 0,
      cheatMode: obj.get<bool>('cheatMode') ?? false,
    );
  }

  /// Computed properties in your model
  String get displayScore => 'Score: $score';
  String get grade => score > 1000 ? 'A' : 'B';
}

void exampleWithOwnModels() async {
  print('\n=== Using Your Own Models ===');

  // Create your model with business logic
  final model = GameScoreModel(
    playerName: 'Bob',
    score: 1500,
    cheatMode: false,
  );

  print('Player: ${model.playerName}');
  print('Display: ${model.displayScore}');
  print('Grade: ${model.grade}');

  // Convert to ParseObject and save
  await model.toParseObject().save();

  // Later, fetch and convert back
  // final query = ParseQuery('GameScore');
  // final results = await query.find();
  // final models = results.map((obj) => GameScoreModel.fromParseObject(obj)).toList();
}

// ============================================================================
// Relations and Pointers
// ============================================================================

void exampleRelationsAndPointers() async {
  print('\n=== Relations and Pointers ===');

  // Create related object
  final team = ParseObject.withData('Team', {
    'name': 'Warriors',
    'city': 'Golden State',
  });
  await team.save();

  // Create object with pointer
  final player = ParseObject('Player')
    ..setAll({
      'name': 'Stephen Curry',
      'number': 30,
    })
    ..set('team', team); // Pointer to team

  await player.save();

  // Working with relations
  // final user = await ParseUser.currentUser();
  // player.relation('followers').add(user);
  // await player.save();

  print('Player: ${player.get<String>('name')}');
}

// ============================================================================
// Complex Example
// ============================================================================

void exampleComplexUsage() async {
  print('\n=== Complex Example ===');

  // Create a post with author, tags, and ACL
  final currentUser = ParseObject('User')..objectId = 'user123';

  final post = ParseObject('Post')
    ..setAll({
      'title': 'Getting Started with Parse',
      'content': 'Parse is a powerful backend...',
      'tags': ['tutorial', 'beginner', 'parse'],
      'published': true,
      'views': 0,
    })
    ..set('author', currentUser)
    ..set('publishedAt', DateTime.now())
    ..setACL(ParseACL()
      ..setPublicReadAccess(true)
      ..setWriteAccess(currentUser.objectId!, true));

  print('Post: ${post.get<String>('title')}');
  print('Tags: ${post.get<List>('tags')}');
  await post.save();
}

// ============================================================================
// Main Example
// ============================================================================

Future<void> main() async {
  // Initialize Parse
  Parse.initialize(
    applicationId: 'myAppId',
    serverUrl: 'http://localhost:1337/parse',
  );

  exampleWithDataFactory();
  exampleSetAllExtension();
  exampleCascadeNotation();
  exampleWithOwnModels();
  exampleRelationsAndPointers();
  exampleComplexUsage();

  print('\n✅ All examples completed!');
}
