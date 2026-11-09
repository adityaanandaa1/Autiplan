/// Removes the spaces and dashes people type in phone numbers.
String normalizePhoneNumber(String raw) => raw.replaceAll(RegExp(r'[\s-]'), '');

/// Whether a normalized number looks like an Indonesian mobile number.
bool isValidPhoneNumber(String number) =>
    RegExp(r'^08\d{8,11}$').hasMatch(number);
