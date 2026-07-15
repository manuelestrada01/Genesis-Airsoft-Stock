import 'package:firebase_auth/firebase_auth.dart';

abstract class IAuthService {
  Stream<User?> get authStateChanges;
  Future<void> signIn(String email, String password);
  Future<void> signOut();
}
