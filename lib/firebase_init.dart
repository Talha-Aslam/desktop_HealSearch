import 'package:desktop_search_a_holic/imports.dart';

class FirebaseInit {
  static get Firebase => null;

  // Initialize Firebase
  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}
