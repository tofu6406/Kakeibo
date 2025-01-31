import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ゲストログイン（匿名認証）
  Future<User?> signInAnonymously() async {
    try {
      UserCredential userCredential = await _auth.signInAnonymously();
      return userCredential.user;
    } catch (e) {
      print("ゲストログインエラー: $e");
      return null;
    }
  }

  // ユーザー登録（新規アカウント作成）
  Future<User?> signUpWithEmail(String email, String password) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return userCredential.user;
    } catch (e) {
      print("登録エラー: $e");
      return null;
    }
  }

  // ログイン
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      UserCredential userCredential =
          await _auth.signInWithEmailAndPassword(email: email, password: password);
      return userCredential.user;
    } catch (e) {
      print("ログインエラー: $e");
      return null;
    }
  }

  // **アカウント削除**
  Future<bool> deleteAccount() async {
    try {
      await _auth.currentUser?.delete();
      return true;
    } catch (e) {
      print("アカウント削除エラー: $e");
      return false;
    }
  }

  // ログアウト
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // 現在のユーザー取得
  User? get currentUser => _auth.currentUser;

  // ゲストアカウントかどうか
  bool isGuestUser() {
    return _auth.currentUser?.isAnonymous ?? false;
  }
}
