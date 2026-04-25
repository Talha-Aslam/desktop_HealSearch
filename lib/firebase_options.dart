class FirebaseOptions {
  final String apiKey;
  final String appId;
  final String messagingSenderId;
  final String projectId;
  final String? authDomain;
  final String? databaseURL;
  final String? storageBucket;
  final String? measurementId;

  const FirebaseOptions({
    required this.apiKey,
    required this.appId,
    required this.messagingSenderId,
    required this.projectId,
    this.authDomain,
    this.databaseURL,
    this.storageBucket,
    this.measurementId,
  });
}

class DefaultFirebaseOptions {
  static FirebaseOptions get web => const FirebaseOptions(
        apiKey: 'mock',
        appId: 'mock',
        messagingSenderId: 'mock',
        projectId: 'mock',
      );

  static FirebaseOptions get android => const FirebaseOptions(
        apiKey: 'mock',
        appId: 'mock',
        messagingSenderId: 'mock',
        projectId: 'mock',
      );

  static FirebaseOptions get ios => const FirebaseOptions(
        apiKey: 'mock',
        appId: 'mock',
        messagingSenderId: 'mock',
        projectId: 'mock',
      );

  static FirebaseOptions get macos => const FirebaseOptions(
        apiKey: 'mock',
        appId: 'mock',
        messagingSenderId: 'mock',
        projectId: 'mock',
      );

  static FirebaseOptions get windows => const FirebaseOptions(
        apiKey: 'mock',
        appId: 'mock',
        messagingSenderId: 'mock',
        projectId: 'mock',
      );

  static FirebaseOptions get currentPlatform => windows;
}
