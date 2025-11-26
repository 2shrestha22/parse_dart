import 'package:parse_dart/parse_dart.dart';
import 'package:test/test.dart';

import 'helpers/test_helpers.dart';

void main() {
  // Initialize Parse before all tests
  setUpAll(() {
    initializeParse();
  });

  group('ParseObject E2E Tests', () {
    late String testClassName;

    setUp(() {
      // Generate unique class name for each test to avoid collisions
      testClassName = generateTestClassName();
    });

    tearDown(() async {
      // Clean up test data after each test
      await deleteAllObjects(testClassName);
    });

    // Purge entire test database after all tests complete
    tearDownAll(() async {
      await purgeAllTestClasses();
    });

    group('Basic CRUD Operations', () {
      test('should create and save a new ParseObject', () async {
        final object = ParseObject(testClassName);
        object.set('name', 'Test Object');
        object.set('score', 100);

        // Verify unsaved state
        expect(object.isSaved, isFalse);
        expect(object.isDirty, isTrue);
        expect(object.objectId, isNull);

        // Save the object
        await object.save(options: getMasterKeyOptions());

        // Verify saved state
        expect(object.isSaved, isTrue);
        expect(object.isDirty, isFalse);
        expect(object.objectId, isNotNull);

        // Fetch to ensure timestamps are populated
        await object.fetch(options: getMasterKeyOptions());

        expect(object.createdAt, isNotNull);
        expect(object.updatedAt, isNotNull);
        expect(object.get<String>('name'), equals('Test Object'));
        expect(object.get<int>('score'), equals(100));
      });

      test('should fetch ParseObject by ID', () async {
        // Create and save an object
        final original = ParseObject(testClassName);
        original.set('name', 'Original Object');
        original.set('value', 42);
        await original.save(options: getMasterKeyOptions());

        final objectId = original.objectId!;

        // Fetch the object
        final fetched = ParseObject(testClassName);
        fetched.objectId = objectId;
        await fetched.fetch(options: getMasterKeyOptions());

        // Verify fetched data
        expect(fetched.objectId, equals(objectId));
        expect(fetched.get<String>('name'), equals('Original Object'));
        expect(fetched.get<int>('value'), equals(42));
        expect(fetched.createdAt, isNotNull);
        expect(fetched.updatedAt, isNotNull);
        expect(fetched.isDirty, isFalse);
      });

      test('should update existing ParseObject', () async {
        // Create and save an object
        final object = ParseObject(testClassName);
        object.set('name', 'Initial Name');
        object.set('count', 1);
        await object.save(options: getMasterKeyOptions());

        final originalUpdatedAt = object.updatedAt;

        // Wait briefly to ensure different timestamp
        await waitBriefly(const Duration(seconds: 1));

        // Update the object
        object.set('name', 'Updated Name');
        object.set('count', 2);

        expect(object.isDirty, isTrue);
        expect(object.dirtyKeys, containsAll(['name', 'count']));

        await object.save(options: getMasterKeyOptions());

        // Verify update
        expect(object.get<String>('name'), equals('Updated Name'));
        expect(object.get<int>('count'), equals(2));
        expect(object.isDirty, isFalse);
        expect(object.updatedAt, isNot(equals(originalUpdatedAt)));
      });

      test('should delete ParseObject', () async {
        // Create and save an object
        final object = ParseObject(testClassName);
        object.set('name', 'To Be Deleted');
        await object.save(options: getMasterKeyOptions());

        final objectId = object.objectId!;

        // Delete the object
        await object.delete(options: getMasterKeyOptions());

        // Verify deletion
        expect(object.objectId, isNull);
        expect(object.isDirty, isFalse);

        // Verify object no longer exists on server
        final query = ParseQuery(testClassName);
        query.whereEqualTo('objectId', objectId);
        final results = await query.find();
        expect(results, isEmpty);
      });

      test('should have correct timestamps', () async {
        final object = ParseObject(testClassName);
        object.set('name', 'Timestamp Test');

        expect(object.createdAt, isNull);
        expect(object.updatedAt, isNull);

        await object.save(options: getMasterKeyOptions());

        // Fetch to ensure timestamps are populated
        await object.fetch(options: getMasterKeyOptions());

        expect(object.createdAt, isNotNull);
        expect(object.updatedAt, isNotNull);

        // createdAt and updatedAt should be close for new objects
        final timeDiff = object.updatedAt!.difference(object.createdAt!);
        expect(timeDiff.inSeconds.abs(), lessThan(2));
      });
    });

    group('Field Operations', () {
      test('should set and get various data types', () async {
        final object = ParseObject(testClassName);

        // String
        object.set('stringField', 'Hello World');
        expect(object.get<String>('stringField'), equals('Hello World'));

        // int
        object.set('intField', 42);
        expect(object.get<int>('intField'), equals(42));

        // double
        object.set('doubleField', 3.14);
        expect(object.get<double>('doubleField'), equals(3.14));

        // bool
        object.set('boolField', true);
        expect(object.get<bool>('boolField'), isTrue);

        // List
        object.set('listField', [1, 2, 3]);
        expect(object.get<List>('listField'), equals([1, 2, 3]));

        // Map
        object.set('mapField', {'key': 'value', 'num': 123});
        final map = object.get<Map>('mapField');
        expect(map?['key'], equals('value'));
        expect(map?['num'], equals(123));

        // Save and verify persistence
        await object.save(options: getMasterKeyOptions());

        expect(object.get<String>('stringField'), equals('Hello World'));
        expect(object.get<int>('intField'), equals(42));
        expect(object.get<double>('doubleField'), equals(3.14));
        expect(object.get<bool>('boolField'), isTrue);
        expect(object.get<List>('listField'), equals([1, 2, 3]));
      });

      test('should unset fields', () async {
        final object = ParseObject(testClassName);
        object.set('field1', 'value1');
        object.set('field2', 'value2');
        await object.save(options: getMasterKeyOptions());

        expect(object.get<String>('field1'), equals('value1'));
        expect(object.get<String>('field2'), equals('value2'));

        // Unset field1
        object.unset('field1');
        expect(object.isDirty, isTrue);

        await object.save(options: getMasterKeyOptions());

        expect(object.get<String>('field1'), isNull);
        expect(object.get<String>('field2'), equals('value2'));
      });

      test('should increment numeric fields', () async {
        final object = ParseObject(testClassName);
        object.set('counter', 10);
        await object.save(options: getMasterKeyOptions());

        // Increment by 1 (default)
        object.increment('counter');
        expect(object.get<num>('counter'), equals(11));

        // Increment by custom amount
        object.increment('counter', 5);
        expect(object.get<num>('counter'), equals(16));

        // Increment by negative (decrement)
        object.increment('counter', -3);
        expect(object.get<num>('counter'), equals(13));

        await object.save(options: getMasterKeyOptions());
        expect(object.get<num>('counter'), equals(13));
      });

      test('should track dirty state correctly', () async {
        final object = ParseObject(testClassName);

        expect(object.isDirty, isFalse);
        expect(object.dirtyKeys, isEmpty);

        object.set('field1', 'value1');
        expect(object.isDirty, isTrue);
        expect(object.dirtyKeys, contains('field1'));
        expect(object.isKeyDirty('field1'), isTrue);
        expect(object.isKeyDirty('field2'), isFalse);

        object.set('field2', 'value2');
        expect(object.dirtyKeys, containsAll(['field1', 'field2']));

        await object.save(options: getMasterKeyOptions());

        expect(object.isDirty, isFalse);
        expect(object.dirtyKeys, isEmpty);
        expect(object.isKeyDirty('field1'), isFalse);
      });

      test('should handle null values', () async {
        final object = ParseObject(testClassName);
        object.set('field', 'initial value');
        await object.save(options: getMasterKeyOptions());

        object.set('field', null);
        await object.save(options: getMasterKeyOptions());

        expect(object.get<String>('field'), isNull);
      });
    });

    group('ACL Operations', () {
      test('should set and retrieve ACL', () async {
        final object = ParseObject(testClassName);
        object.set('name', 'ACL Test');

        final acl = ParseACL();
        acl.setPublicReadAccess(true);
        acl.setPublicWriteAccess(false);

        object.setACL(acl);

        expect(object.acl, isNotNull);
        expect(object.acl!.getPublicReadAccess(), isTrue);
        expect(object.acl!.getPublicWriteAccess(), isFalse);

        await object.save(options: getMasterKeyOptions());

        // Verify ACL persisted
        expect(object.acl, isNotNull);
        expect(object.acl!.getPublicReadAccess(), isTrue);
        expect(object.acl!.getPublicWriteAccess(), isFalse);
      });

      test('should persist ACL across fetch', () async {
        final object = ParseObject(testClassName);
        object.set('name', 'ACL Persist Test');

        final acl = ParseACL();
        acl.setPublicReadAccess(true);
        acl.setPublicWriteAccess(false);
        acl.setReadAccess('user123', true);

        object.setACL(acl);
        await object.save(options: getMasterKeyOptions());

        final objectId = object.objectId!;

        // Fetch in a new object
        final fetched = ParseObject(testClassName);
        fetched.objectId = objectId;
        await fetched.fetch(options: getMasterKeyOptions());

        expect(fetched.acl, isNotNull);
        expect(fetched.acl!.getPublicReadAccess(), isTrue);
        expect(fetched.acl!.getPublicWriteAccess(), isFalse);
        expect(fetched.acl!.getReadAccess('user123'), isTrue);
      });

      test('should update ACL on existing object', () async {
        final object = ParseObject(testClassName);
        object.set('name', 'ACL Update Test');

        final acl1 = ParseACL();
        acl1.setPublicReadAccess(true);
        object.setACL(acl1);
        await object.save(options: getMasterKeyOptions());

        expect(object.acl!.getPublicReadAccess(), isTrue);
        expect(object.acl!.getPublicWriteAccess(), isFalse);

        // Update ACL
        final acl2 = ParseACL();
        acl2.setPublicReadAccess(false);
        acl2.setPublicWriteAccess(true);
        object.setACL(acl2);
        await object.save(options: getMasterKeyOptions());

        expect(object.acl!.getPublicReadAccess(), isFalse);
        expect(object.acl!.getPublicWriteAccess(), isTrue);
      });
    });

    group('Advanced Features', () {
      test('should create and use pointers', () async {
        // Create a referenced object
        final referenced = ParseObject('ReferencedClass');
        referenced.set('name', 'Referenced Object');
        await referenced.save(options: getMasterKeyOptions());

        // Create object with pointer
        final object = ParseObject(testClassName);
        object.set('name', 'Main Object');
        object.set('pointer', referenced);
        await object.save(options: getMasterKeyOptions());

        // Fetch and verify pointer
        final fetched = ParseObject(testClassName);
        fetched.objectId = object.objectId;
        await fetched.fetch(options: getMasterKeyOptions());

        final fetchedPointer = fetched.get<ParseObject>('pointer');
        expect(fetchedPointer, isNotNull);
        expect(fetchedPointer!.className, equals('ReferencedClass'));
        expect(fetchedPointer.objectId, equals(referenced.objectId));

        // Cleanup
        await referenced.delete(options: getMasterKeyOptions());
      });

      test('should serialize to JSON correctly', () async {
        final object = ParseObject(testClassName);
        object.set('name', 'JSON Test');
        object.set('score', 100);
        await object.save(options: getMasterKeyOptions());

        // Fetch to ensure timestamps are populated
        await object.fetch(options: getMasterKeyOptions());

        final json = object.toJson();

        expect(json['objectId'], equals(object.objectId));
        expect(json['name'], equals('JSON Test'));
        expect(json['score'], equals(100));
        expect(json['createdAt'], isNotNull);
        expect(json['updatedAt'], isNotNull);
      });

      test('should create from JSON', () async {
        final json = {
          'objectId': 'test123',
          'createdAt': '2024-01-01T00:00:00.000Z',
          'updatedAt': '2024-01-01T00:00:00.000Z',
          'name': 'From JSON',
          'score': 42,
        };

        final object = ParseObject.fromJson(testClassName, json);

        expect(object.className, equals(testClassName));
        expect(object.objectId, equals('test123'));
        expect(object.get<String>('name'), equals('From JSON'));
        expect(object.get<int>('score'), equals(42));
        expect(object.createdAt, isNotNull);
        expect(object.updatedAt, isNotNull);
      });

      test('should convert to pointer format', () {
        final object = ParseObject(testClassName);
        object.objectId = 'abc123';

        final pointer = object.toPointer();

        expect(pointer['__type'], equals('Pointer'));
        expect(pointer['className'], equals(testClassName));
        expect(pointer['objectId'], equals('abc123'));
      });

      test('should generate local ID for unsaved pointers', () {
        final object = ParseObject(testClassName);
        expect(object.objectId, isNull);
        expect(object.localId, isNull);

        final pointer = object.toPointer();

        expect(pointer['__type'], equals('Pointer'));
        expect(pointer['className'], equals(testClassName));
        expect(pointer['_localId'], isNotNull);
        expect(object.localId, isNotNull);
      });

      test('should compare objects correctly', () async {
        final object1 = ParseObject(testClassName);
        object1.set('name', 'Object 1');
        await object1.save(options: getMasterKeyOptions());

        final object2 = ParseObject(testClassName);
        object2.set('name', 'Object 2');
        await object2.save(options: getMasterKeyOptions());

        // Same object reference
        expect(object1, equals(object1));

        // Different objects
        expect(object1, isNot(equals(object2)));

        // Same objectId
        final object1Copy = ParseObject(testClassName);
        object1Copy.objectId = object1.objectId;
        expect(object1, equals(object1Copy));

        // Unsaved objects are never equal
        final unsaved1 = ParseObject(testClassName);
        final unsaved2 = ParseObject(testClassName);
        expect(unsaved1, isNot(equals(unsaved2)));
      });
    });

    group('Error Handling', () {
      test('should throw error when setting reserved keys', () {
        final object = ParseObject(testClassName);

        expect(
          () => object.set('objectId', 'test'),
          throwsA(isA<ParseException>()),
        );

        expect(
          () => object.set('createdAt', DateTime.now()),
          throwsA(isA<ParseException>()),
        );

        expect(
          () => object.set('updatedAt', DateTime.now()),
          throwsA(isA<ParseException>()),
        );

        expect(
          () => object.set('ACL', {}),
          throwsA(isA<ParseException>()),
        );
      });

      test('should throw error when fetching without objectId', () async {
        final object = ParseObject(testClassName);

        expect(
          () => object.fetch(),
          throwsA(isA<ParseException>()),
        );
      });

      test('should throw error when deleting without objectId', () async {
        final object = ParseObject(testClassName);

        expect(
          () => object.delete(),
          throwsA(isA<ParseException>()),
        );
      });

      test('should handle network errors gracefully', () async {
        // Try to fetch non-existent object
        final object = ParseObject(testClassName);
        object.objectId = 'nonexistent123';

        expect(
          () => object.fetch(),
          throwsA(isA<ParseException>()),
        );
      });
    });

    group('Relations', () {
      test('should create ParseRelation', () {
        final object = ParseObject(testClassName);
        final relation = object.relation<ParseObject>('relatedObjects');

        expect(relation, isNotNull);
        expect(relation, isA<ParseRelation<ParseObject>>());
      });
    });
  });
}
