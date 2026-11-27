import 'dart:convert';

bool isValidPasswordLength(String? password) {
  if (password == null) {
    return false;
  }
  final byteLength = utf8.encode(password).length;
  return byteLength >= 12 && byteLength <= 72;
}
