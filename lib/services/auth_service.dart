import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../models/user_profile.dart';


class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseDatabase.instance.ref();


  User? get currentUser => _auth.currentUser;


  Future<bool> isLoggedIn() async {
    return _auth.currentUser != null;
  }


  Future<UserCredential> signInAnonymouslyAndCreateProfile(String name) async {
    final cred = await _auth.signInAnonymously();
    final uid = cred.user!.uid;
    final profile = UserProfile(uid: uid, name: name);


    final userRef = _db.child('users/$uid');
    final snap = await userRef.get();
    if (!snap.exists) {
      await userRef.set(profile.toMap());
    } else {
// isim güncellemek isterseniz:
      await userRef.child('name').set(name);
    }
    return cred;
  }
}