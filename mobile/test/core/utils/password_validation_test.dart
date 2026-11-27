import 'package:flutter_test/flutter_test.dart';
import 'package:sadguru_catering/core/utils/password_validation.dart';

void main() {
  test('validates the backend bcrypt byte-length limits', () {
    expect(isValidPasswordLength(null), isFalse);
    expect(isValidPasswordLength('short'), isFalse);
    expect(isValidPasswordLength(List.filled(12, 'a').join()), isTrue);
    expect(isValidPasswordLength(List.filled(72, 'a').join()), isTrue);
    expect(isValidPasswordLength(List.filled(73, 'a').join()), isFalse);
    expect(isValidPasswordLength(List.filled(6, 'é').join()), isTrue);
    expect(isValidPasswordLength(List.filled(37, 'é').join()), isFalse);
  });
}
