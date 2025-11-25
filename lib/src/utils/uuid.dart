import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Generates a v4 UUID string
String generateUuid() {
  return _uuid.v4();
}
