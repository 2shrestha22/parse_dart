import 'package:parse_dart/parse_dart.dart';

Future<void> main() async {
  Parse.initialize(
    applicationId: 'myAppId',
    serverUrl: 'http://localhost:1337/parse',
  );

  final foodClass = ParseObject('Food');

  foodClass.set('name', 'Pizza');

  final acl = ParseACL();
  acl.setPublicWriteAccess(true);
  acl.setPublicReadAccess(false);
  foodClass.setACL(acl);

  await foodClass.save();

  print(foodClass.toFullJson());
  print(foodClass.toJson());
  print(foodClass.toString());
  print(foodClass.toPointer());
}
