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
    query.limit(10000); // Get more objects at once
    final results = await query.find(options: getMasterKeyOptions());

    if (results.isEmpty) {
      return;
    }

    // Delete all objects
    for (final object in results) {
      try {
        await object.delete(options: getMasterKeyOptions());
      } catch (e) {
        // Try again with a fresh query for this specific object
        try {
          final freshQuery = ParseQuery(className);
          freshQuery.whereEqualTo('objectId', object.objectId);
          final freshResults =
              await freshQuery.find(options: getMasterKeyOptions());
          if (freshResults.isNotEmpty) {
            await freshResults[0].delete(options: getMasterKeyOptions());
          }
        } catch (e2) {
          // Ignore - object may have been deleted already
        }
      }
    }

    // Recursively call to ensure all objects are deleted (in case there were more than limit)
    if (results.length >= 10000) {
      await deleteAllObjects(className);
    }
  } catch (e) {
    // Ignore query errors during cleanup
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

/// Purge all non-system classes from the database
///
/// This deletes ALL classes except Parse's built-in system classes.
/// Use this in tearDownAll to completely clean the test database.
///
/// System classes that are preserved: _User, _Role, _Session, _Installation, _Product
Future<void> purgeAllTestClasses() async {
  // Parse Server's built-in system classes that should NOT be deleted
  final systemClasses = {
    '_User',
    '_Role',
    '_Session',
    '_Installation',
    '_Product',
    '_Subscription',
    '_PushStatus',
    '_JobStatus',
    '_JobSchedule',
    '_Hooks',
    '_GlobalConfig',
    '_Audience',
  };

  print('Purging all non-system classes from database...');

  try {
    // Use Parse REST API to get all schemas
    final controller = ParseRESTController.instance;
    final response = await controller.request(
      'GET',
      'schemas',
      options: getMasterKeyOptions(),
    );

    int deletedClasses = 0;
    int failedClasses = 0;
    final results = response.data['results'] as List<dynamic>?;

    if (results != null) {
      for (final schema in results) {
        final className = schema['className'] as String;

        // Skip system classes
        if (systemClasses.contains(className)) {
          continue;
        }

        try {
          // First delete all objects in the class (with retries)
          await deleteAllObjects(className);

          // Small delay to let Parse Server update
          await Future.delayed(const Duration(milliseconds: 50));

          // Then delete the class schema itself
          await controller.request(
            'DELETE',
            'schemas/$className',
            options: getMasterKeyOptions(),
          );
          deletedClasses++;
        } catch (e) {
          failedClasses++;
        }
      }
    }

    if (failedClasses > 0) {
      print(
          '✓ Purged $deletedClasses classes ($failedClasses failed - may have orphaned data)');
    } else {
      print('✓ Successfully purged $deletedClasses classes');
    }
  } catch (e) {
    print('✗ Error: Failed to purge classes: $e');
  }
}
