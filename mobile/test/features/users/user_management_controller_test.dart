import 'package:flutter_test/flutter_test.dart';
import 'package:sadguru_catering/core/network/api_exception.dart';
import 'package:sadguru_catering/features/users/controllers/user_management_controller.dart';
import 'package:sadguru_catering/features/users/models/managed_user.dart';
import 'package:sadguru_catering/features/users/services/user_management_service.dart';

void main() {
  late _FakeUserService service;
  late UserManagementController controller;

  setUp(() {
    service = _FakeUserService();
    controller = UserManagementController(service);
  });

  tearDown(() {
    controller.dispose();
  });

  test('loads users and displays roles and active state', () async {
    await controller.load();
    expect(controller.users, hasLength(1));
    expect(controller.users.single.role, 'owner');
    expect(controller.users.single.isActive, isTrue);
  });

  test('creates a user and refreshes the list', () async {
    final success = await controller.createUser(
      username: 'supervisor',
      password: 'strong-password',
      role: 'supervisor',
    );
    expect(success, isTrue);
    expect(service.lastCreatedRole, 'supervisor');
    expect(controller.users, hasLength(2));
  });

  test('updates role and activation status', () async {
    final success = await controller.updateUser(
      id: 2,
      username: 'new-name',
      role: 'owner',
      isActive: false,
    );
    expect(success, isTrue);
    expect(service.lastUpdatedRole, 'owner');
    expect(service.lastUpdatedActive, isFalse);
  });

  test('resets a password and removes users', () async {
    expect(
      await controller.resetPassword(id: 2, password: 'new-password'),
      isTrue,
    );
    expect(service.lastResetPassword, 'new-password');

    expect(await controller.deleteUser(2), isTrue);
    expect(service.deletedId, 2);
  });

  test('surfaces server errors without reporting success', () async {
    service.failNextMutation = true;
    final success = await controller.deleteUser(2);
    expect(success, isFalse);
    expect(controller.error, isNotNull);
  });
}

class _FakeUserService implements UserManagementServiceContract {
  final List<ManagedUser> _users = [
    ManagedUser(
      id: 1,
      username: 'admin',
      role: 'owner',
      isActive: true,
      mustChangePassword: false,
      createdAt: DateTime.utc(2026),
    ),
  ];

  bool failNextMutation = false;
  String? lastCreatedRole;
  String? lastUpdatedRole;
  bool? lastUpdatedActive;
  String? lastResetPassword;
  int? deletedId;

  void _maybeFail() {
    if (failNextMutation) {
      failNextMutation = false;
      throw const ApiException(
        code: 'INTERNAL_ERROR',
        message: 'Server failure',
        statusCode: 500,
      );
    }
  }

  @override
  Future<List<ManagedUser>> listUsers() async => List.of(_users);

  @override
  Future<ManagedUser> createUser({
    required String username,
    required String password,
    required String role,
  }) async {
    _maybeFail();
    lastCreatedRole = role;
    final user = ManagedUser(
      id: 2,
      username: username,
      role: role,
      isActive: true,
      mustChangePassword: true,
      createdAt: DateTime.utc(2026),
    );
    _users.add(user);
    return user;
  }

  @override
  Future<ManagedUser> updateUser({
    required int id,
    required String username,
    required String role,
    required bool isActive,
  }) async {
    _maybeFail();
    lastUpdatedRole = role;
    lastUpdatedActive = isActive;
    return _users.first;
  }

  @override
  Future<void> resetPassword({
    required int id,
    required String password,
  }) async {
    _maybeFail();
    lastResetPassword = password;
  }

  @override
  Future<void> deleteUser(int id) async {
    _maybeFail();
    deletedId = id;
    _users.removeWhere((user) => user.id == id);
  }
}
