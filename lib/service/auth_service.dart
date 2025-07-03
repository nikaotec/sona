import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Future<User?> signInWithGoogle() async {
  // //  final googleUser = await GoogleSignIn().signIn();
  //  // if (googleUser == null) return null;

  // //  final googleAuth = await googleUser.authentication;
  //   // final credential = GoogleAuthProvider.credential(
  //   //   accessToken: googleAuth.accessToken,
  //   //   idToken: googleAuth.idToken,
  //   // );

  //   final result = await _auth.signInWithCredential(credential);
  //   return result.user;
  // }

  Future<User?> signInWithEmail(String email, String password) async {
  final result = await _auth.signInWithEmailAndPassword(email: email, password: password);
  return result.user;
}


  Future<void> signOut() => _auth.signOut();

  User? get currentUser => _auth.currentUser;
}
