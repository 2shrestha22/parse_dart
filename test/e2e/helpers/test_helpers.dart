import 'package:parse_dart/parse_dart.dart';

/// Test configuration for Parse Server
class TestConfig {
  static const String applicationId = 'myAppId';
  static const String masterKey = 'myMasterKey';
  static const String serverUrl = 'http://localhost:1337/parse';
}

/// Initialize Parse SDK for testing
void initializeParse() {
  if (!Parse.isInitialized) {
    Parse.initialize(
      applicationId: TestConfig.applicationId,
      serverUrl: TestConfig.serverUrl,
      masterKey: TestConfig.masterKey,
    );
  }
}

/// Create a unique class name for tests to avoid collisions
String generateTestClassName([String prefix = 'TestObject']) {
  final timestamp = DateTime.now().millisecondsSinceEpoch;
  return '${prefix}_$timestamp';
}

/// Delete all objects of a given class (cleanup helper)
Future<void> deleteAllObjects(String className) async {
  try {
    final query = ParseQuery(className);
    final results = await query.find();

    for (final object in results) {
      try {
        await object.delete();
      } catch (e) {
        // Ignore individual delete errors during cleanup
        print('Warning: Failed to delete object ${object.objectId}: $e');
      }
    }
  } catch (e) {
    // Ignore query errors during cleanup
    print('Warning: Failed to query for cleanup: $e');
  }
}

/// Create a test object with some initial data
ParseObject createTestObject(String className,
    {Map<String, dynamic>? initialData}) {
  final object = ParseObject(className);

  if (initialData != null) {
    initialData.forEach((key, value) {
      object.set(key, value);
    });
  }

  return object;
}

/// Verify that a ParseObject has expected properties
void verifyObjectState({
  required ParseObject object,
  required bool isSaved,
  required bool isDirty,
  bool hasCreatedAt = false,
  bool hasUpdatedAt = false,
}) {
  if (isSaved && object.objectId == null) {
    throw Exception('Expected object to be saved but objectId is null');
  }
  if (!isSaved && object.objectId != null) {
    throw Exception('Expected object to be unsaved but objectId is not null');
  }
  if (isDirty != object.isDirty) {
    throw Exception(
        'Expected isDirty to be $isDirty but got ${object.isDirty}');
  }
  if (hasCreatedAt && object.createdAt == null) {
    throw Exception('Expected createdAt to be set but it is null');
  }
  if (hasUpdatedAt && object.updatedAt == null) {
    throw Exception('Expected updatedAt to be set but it is null');
  }
}

/// Wait for a short period (useful for ensuring timestamp differences)
Future<void> waitBriefly(
    [Duration duration = const Duration(milliseconds: 100)]) async {
  await Future<void>.delayed(duration);
}

/// Get ParseRequestOptions with master key enabled for tests
ParseRequestOptions getMasterKeyOptions() {
  return const ParseRequestOptions(useMasterKey: true);
}
