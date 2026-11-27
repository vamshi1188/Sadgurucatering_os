import 'package:sadguru_catering/features/authentication/models/authentication_state.dart';

const testOwner = AuthenticatedUser(
  id: 1,
  username: 'admin',
  role: 'owner',
  mustChangePassword: false,
);

const authenticatedOwner = AuthenticationState.authenticated(user: testOwner);
