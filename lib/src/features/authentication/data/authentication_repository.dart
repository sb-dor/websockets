import 'package:websockets/src/features/authentication/model/user.dart';

abstract interface class IAuthenticationRepository {}

class AuthenticationRepositoryImpl implements IAuthenticationRepository {
  AuthenticationRepositoryImpl();

  // ignore: unused_field
  // final ApiClient _apiClient;
}

class AuthenticationRepositoryFake implements IAuthenticationRepository {
  User get defaultUser => User.defaultUser();
}
