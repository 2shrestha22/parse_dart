/// Parses a Parse Server ISO8601 date string to DateTime
DateTime? parseDate(String? dateString) {
  if (dateString == null || dateString.isEmpty) {
    return null;
  }

  try {
    return DateTime.parse(dateString).toLocal();
  } catch (e) {
    return null;
  }
}

/// Converts a DateTime to Parse Server ISO8601 format
String formatDate(DateTime date) {
  return date.toUtc().toIso8601String();
}

/// Converts a DateTime to Parse JSON format
Map<String, dynamic> dateToJson(DateTime date) {
  return {'__type': 'Date', 'iso': formatDate(date)};
}
