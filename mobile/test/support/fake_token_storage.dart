import 'package:sadguru_catering/core/storage/secure_storage.dart';

class FakeTokenStorage implements TokenStorage {
  String? token;

  @override
  Future<String?> readToken() async => token;

  @override
  Future<void> writeToken(String value) async {
    token = value;
  }

  @override
  Future<void> clearToken() async {
    token = null;
  }
}
