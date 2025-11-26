import 'package:parse_dart/parse_dart.dart';
import 'package:test/test.dart';

import 'helpers/test_helpers.dart';

void main() {
  // Initialize Parse before all tests
  setUpAll(() {
    initializeParse();
  });

  group('ParseRelation E2E Tests', () {
    late String postClassName;
    late String commentClassName;
    late String userClassName;

    setUp(() {
      // Generate unique class names for each test to avoid collisions
      postClassName = generateTestClassName('Post');
      commentClassName = generateTestClassName('Comment');
      userClassName = generateTestClassName('User');
    });

    // Purge entire test database after all tests complete
    tearDownAll(() async {
      await purgeAllTestClasses();
    });

    group('Basic Relation Operations', () {
      test('should create a relation and add objects', () async {
        // Create a user
        final user = ParseObject(userClassName);
        user.set('name', 'Alice');
        await user.save(options: getMasterKeyOptions());

        // Create posts
        final post1 = ParseObject(postClassName);
        post1.set('title', 'Post 1');
        await post1.save(options: getMasterKeyOptions());

        final post2 = ParseObject(postClassName);
        post2.set('title', 'Post 2');
        await post2.save(options: getMasterKeyOptions());

        // Create relation and add posts
        final relation = user.relation<ParseObject>('likes');
        relation.add(post1);
        relation.add(post2);

        // Save the user to persist the relation
        await user.save(options: getMasterKeyOptions());
      });

      test('should add multiple objects at once to a relation', () async {
        final user = ParseObject(userClassName);
        user.set('name', 'Bob');
        await user.save(options: getMasterKeyOptions());

        // Create multiple posts
        final post1 = ParseObject(postClassName);
        post1.set('title', 'Post 1');
        await post1.save(options: getMasterKeyOptions());

        final post2 = ParseObject(postClassName);
        post2.set('title', 'Post 2');
        await post2.save(options: getMasterKeyOptions());

        final post3 = ParseObject(postClassName);
        post3.set('title', 'Post 3');
        await post3.save(options: getMasterKeyOptions());

        // Add all posts at once
        final relation = user.relation<ParseObject>('likes');
        relation.add(post1);
        relation.add(post2);
        relation.add(post3);

        await user.save(options: getMasterKeyOptions());

        // Query to verify all posts were added
        final query = relation.query();
        final results = await query.find(options: getMasterKeyOptions());

        expect(results.length, equals(3));
      });

      test('should remove objects from a relation', () async {
        final user = ParseObject(userClassName);
        user.set('name', 'Charlie');
        await user.save(options: getMasterKeyOptions());

        // Create posts
        final post1 = ParseObject(postClassName);
        post1.set('title', 'Post 1');
        await post1.save(options: getMasterKeyOptions());

        final post2 = ParseObject(postClassName);
        post2.set('title', 'Post 2');
        await post2.save(options: getMasterKeyOptions());

        // Add both posts
        final relation = user.relation<ParseObject>('likes');
        relation.add(post1);
        relation.add(post2);
        await user.save(options: getMasterKeyOptions());

        // Verify both posts are in the relation
        var query = relation.query();
        var results = await query.find(options: getMasterKeyOptions());
        expect(results.length, equals(2));

        // Remove one post
        relation.remove(post1);
        await user.save(options: getMasterKeyOptions());

        // Verify only one post remains
        query = relation.query();
        results = await query.find(options: getMasterKeyOptions());
        expect(results.length, equals(1));
        expect(results[0].get<String>('title'), equals('Post 2'));
      });

      test('should handle multiple add and remove before save', () async {
        final user = ParseObject(userClassName);
        user.set('name', 'Diana');
        await user.save(options: getMasterKeyOptions());

        // Create posts
        final post1 = ParseObject(postClassName);
        post1.set('title', 'Post 1');
        await post1.save(options: getMasterKeyOptions());

        final post2 = ParseObject(postClassName);
        post2.set('title', 'Post 2');
        await post2.save(options: getMasterKeyOptions());

        final post3 = ParseObject(postClassName);
        post3.set('title', 'Post 3');
        await post3.save(options: getMasterKeyOptions());

        // Multiple operations before save
        final relation = user.relation<ParseObject>('likes');
        relation.add(post1);
        relation.add(post2);
        relation.add(post3);
        relation.remove(post2); // Remove post2 before saving

        await user.save(options: getMasterKeyOptions());

        // Verify correct posts are in the relation
        final query = relation.query();
        final results = await query.find(options: getMasterKeyOptions());

        expect(results.length, equals(2));
        final titles = results.map((p) => p.get<String>('title')).toList();
        expect(titles, containsAll(['Post 1', 'Post 3']));
        expect(titles, isNot(contains('Post 2')));
      });
    });

    group('Querying Relations', () {
      test('should query all objects in a relation', () async {
        final user = ParseObject(userClassName);
        user.set('name', 'Eve');
        await user.save(options: getMasterKeyOptions());

        // Create and add posts
        final posts = <ParseObject>[];
        for (int i = 1; i <= 5; i++) {
          final post = ParseObject(postClassName);
          post.set('title', 'Post $i');
          post.set('index', i);
          await post.save(options: getMasterKeyOptions());
          posts.add(post);
        }

        final relation = user.relation<ParseObject>('likes');
        for (final post in posts) {
          relation.add(post);
        }
        await user.save(options: getMasterKeyOptions());

        // Query all related posts
        final query = relation.query();
        final results = await query.find(options: getMasterKeyOptions());

        expect(results.length, equals(5));
      });

      test('should query relation with constraints', () async {
        final user = ParseObject(userClassName);
        user.set('name', 'Frank');
        await user.save(options: getMasterKeyOptions());

        // Create posts with different titles
        final post1 = ParseObject(postClassName);
        post1.set('title', 'I\'m Hungry');
        post1.set('score', 100);
        await post1.save(options: getMasterKeyOptions());

        final post2 = ParseObject(postClassName);
        post2.set('title', 'I\'m Happy');
        post2.set('score', 200);
        await post2.save(options: getMasterKeyOptions());

        final post3 = ParseObject(postClassName);
        post3.set('title', 'I\'m Hungry');
        post3.set('score', 150);
        await post3.save(options: getMasterKeyOptions());

        // Add all posts to relation
        final relation = user.relation<ParseObject>('likes');
        relation.add(post1);
        relation.add(post2);
        relation.add(post3);
        await user.save(options: getMasterKeyOptions());

        // Query with constraint
        final query = relation.query();
        query.whereEqualTo('title', 'I\'m Hungry');
        final results = await query.find(options: getMasterKeyOptions());

        expect(results.length, equals(2));
        for (final result in results) {
          expect(result.get<String>('title'), equals('I\'m Hungry'));
        }
      });

      test('should query relation with ordering', () async {
        final user = ParseObject(userClassName);
        user.set('name', 'Grace');
        await user.save(options: getMasterKeyOptions());

        // Create relation once and reuse it
        final relation = user.relation<ParseObject>('likes');

        // Create posts with different scores
        final scores = [50, 200, 100, 150, 75];
        for (final score in scores) {
          final post = ParseObject(postClassName);
          post.set('title', 'Post with score $score');
          post.set('score', score);
          await post.save(options: getMasterKeyOptions());

          relation.add(post);
        }
        await user.save(options: getMasterKeyOptions());

        // Query with descending order
        final query = relation.query();
        query.orderByDescending('score');
        final results = await query.find(options: getMasterKeyOptions());

        expect(results.length, equals(5));
        expect(results[0].get<int>('score'), equals(200));
        expect(results[1].get<int>('score'), equals(150));
        expect(results[2].get<int>('score'), equals(100));
        expect(results[3].get<int>('score'), equals(75));
        expect(results[4].get<int>('score'), equals(50));
      });

      test('should query relation with limit', () async {
        final user = ParseObject(userClassName);
        user.set('name', 'Henry');
        await user.save(options: getMasterKeyOptions());

        // Create relation once and reuse it
        final relation = user.relation<ParseObject>('likes');

        // Create 10 posts
        for (int i = 1; i <= 10; i++) {
          final post = ParseObject(postClassName);
          post.set('title', 'Post $i');
          await post.save(options: getMasterKeyOptions());

          relation.add(post);
        }
        await user.save(options: getMasterKeyOptions());

        // Query with limit
        final query = relation.query();
        query.limit(5);
        final results = await query.find(options: getMasterKeyOptions());

        expect(results.length, equals(5));
      });

      test('should count objects in relation', () async {
        final user = ParseObject(userClassName);
        user.set('name', 'Iris');
        await user.save(options: getMasterKeyOptions());

        // Create relation once and reuse it
        final relation = user.relation<ParseObject>('likes');

        // Create and add 7 posts
        for (int i = 1; i <= 7; i++) {
          final post = ParseObject(postClassName);
          post.set('title', 'Post $i');
          await post.save(options: getMasterKeyOptions());

          relation.add(post);
        }
        await user.save(options: getMasterKeyOptions());

        // Count objects in relation
        final query = relation.query();
        final count = await query.count(options: getMasterKeyOptions());

        expect(count, equals(7));
      });
    });

    group('Relational Queries', () {
      test('should query objects with pointer equality', () async {
        // Create a post
        final post = ParseObject(postClassName);
        post.set('title', 'My Post');
        await post.save(options: getMasterKeyOptions());

        // Create comments pointing to the post
        final comment1 = ParseObject(commentClassName);
        comment1.set('text', 'Great post!');
        comment1.set('post', post);
        await comment1.save(options: getMasterKeyOptions());

        final comment2 = ParseObject(commentClassName);
        comment2.set('text', 'Interesting!');
        comment2.set('post', post);
        await comment2.save(options: getMasterKeyOptions());

        // Create another post with a comment
        final otherPost = ParseObject(postClassName);
        otherPost.set('title', 'Other Post');
        await otherPost.save(options: getMasterKeyOptions());

        final comment3 = ParseObject(commentClassName);
        comment3.set('text', 'Different post');
        comment3.set('post', otherPost);
        await comment3.save(options: getMasterKeyOptions());

        // Query comments for the first post
        final query = ParseQuery<ParseObject>(commentClassName);
        query.whereEqualTo('post', post);
        final results = await query.find(options: getMasterKeyOptions());

        expect(results.length, equals(2));
        for (final comment in results) {
          final commentPost = comment.get<ParseObject>('post');
          expect(commentPost?.objectId, equals(post.objectId));
        }
      });

      test('should include related objects in query results', () async {
        // Create a post
        final post = ParseObject(postClassName);
        post.set('title', 'Amazing Post');
        post.set('content', 'This is the content');
        await post.save(options: getMasterKeyOptions());

        // Create comments
        final comment1 = ParseObject(commentClassName);
        comment1.set('text', 'Comment 1');
        comment1.set('post', post);
        await comment1.save(options: getMasterKeyOptions());

        final comment2 = ParseObject(commentClassName);
        comment2.set('text', 'Comment 2');
        comment2.set('post', post);
        await comment2.save(options: getMasterKeyOptions());

        // Query with include
        final query = ParseQuery<ParseObject>(commentClassName);
        query.whereEqualTo('post', post);
        query.include('post');
        final results = await query.find(options: getMasterKeyOptions());

        expect(results.length, equals(2));

        // Verify the post data is included (not just a pointer)
        for (final comment in results) {
          final includedPost = comment.get<ParseObject>('post');
          expect(includedPost, isNotNull);
          expect(includedPost!.objectId, equals(post.objectId));
          // This should not require a network request
          expect(includedPost.get<String>('title'), equals('Amazing Post'));
          expect(
            includedPost.get<String>('content'),
            equals('This is the content'),
          );
        }
      });

      test('should query by objectId using pointer', () async {
        // Create a post
        final post = ParseObject(postClassName);
        post.set('title', 'Test Post');
        await post.save(options: getMasterKeyOptions());

        // Create comments
        final comment = ParseObject(commentClassName);
        comment.set('text', 'A comment');
        comment.set('post', post);
        await comment.save(options: getMasterKeyOptions());

        // Query using a pointer object with just objectId
        final postPointer = ParseObject(postClassName);
        postPointer.objectId = post.objectId;

        final query = ParseQuery<ParseObject>(commentClassName);
        query.whereEqualTo('post', postPointer);
        final results = await query.find(options: getMasterKeyOptions());

        expect(results.length, equals(1));
        expect(results[0].get<String>('text'), equals('A comment'));
      });
    });

    group('Error Handling', () {
      // Note: The JS SDK allows querying without targetClassName by using
      // the parent's className, so we don't test for that error.
      // If targetClassName is set later by adding objects, it will be used.
    });

    group('JSON Serialization', () {
      test('should serialize relation to JSON', () {
        final user = ParseObject(userClassName);
        final relation = user.relation<ParseObject>('likes');

        // Add a post to set targetClassName
        final post = ParseObject(postClassName);
        post.objectId = 'test123';
        relation.add(post);

        final json = relation.toJson();

        expect(json['__type'], equals('Relation'));
        expect(json['className'], equals(postClassName));
      });

      test('should create relation from JSON', () {
        final json = {
          '__type': 'Relation',
          'className': postClassName,
        };

        final relation = ParseRelation.fromJson(json);

        expect(relation.targetClassName, equals(postClassName));

        final relationJson = relation.toJson();
        expect(relationJson['__type'], equals('Relation'));
        expect(relationJson['className'], equals(postClassName));
      });
    });
  });
}
