import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';

class AuthGoogleService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: Platform.isIOS
        ? const String.fromEnvironment('IOS_CLIENT_ID', defaultValue: '471745302305-ja90tj0aatmq2e7i6rjei1v08bpb2nvp.apps.googleusercontent.com')
        : const String.fromEnvironment('WEB_CLIENT_ID', defaultValue: '471745302305-dn3dbl2ks77jqkajs9u2nivhrh4vrum0.apps.googleusercontent.com'),
    serverClientId: const String.fromEnvironment('SERVER_CLIENT_ID', defaultValue: '471745302305-tts3kroutn6jofuvcldfckjk4j7et6l2.apps.googleusercontent.com'),
  );

  Future<String?> getIdToken() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    return googleAuth.idToken;
  }

  Future<void> signOut() => _googleSignIn.signOut();
}
