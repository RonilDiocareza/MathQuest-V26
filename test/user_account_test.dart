import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mathquest/models/user_account.dart';

void main() {
  test('serializes the selected character with the user profile', () {
    final account = UserAccount(
      email: 'student@example.com',
      role: 'student',
      status: 'pending',
      name: 'Student',
      address: 'School',
      lrn: '123456789012',
      character: 'girl',
    );

    expect(account.toJson()['character'], 'girl');
  });

  test('defaults legacy profiles to boy', () {
    final account = UserAccount.fromJson({
      'email': 'student@example.com',
      'role': 'student',
      'status': 'pending',
      'name': 'Student',
      'address': 'School',
      'lrn': '123456789012',
    });

    expect(account.character, 'boy');
  });
}
