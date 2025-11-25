import 'package:parse_dart/parse_dart.dart';

void main() {
  Parse.initialize(
    applicationId: 'myAppId',
    serverUrl: 'http://localhost:1337/parse',
  );

  final foodClass = ParseObject('food');

  foodClass.set('name', 'Pizza');

  foodClass.save();
}
