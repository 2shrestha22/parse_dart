import 'package:parse_dart/parse_dart.dart';

void main() {
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

  foodClass.save();
}
