import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../infrastructure/auth/auth_service.dart';
import '../../infrastructure/auth/firebase_auth_service.dart';

final authServiceProvider = Provider<IAuthService>((ref) {
  return FirebaseAuthService();
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});
