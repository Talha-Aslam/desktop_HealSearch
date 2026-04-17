import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class FirebaseAuthException implements Exception {
  final String code;
  final String? message;
  FirebaseAuthException({required this.code, this.message});
}

class FirebaseAuth {
  static final FirebaseAuth instance = FirebaseAuth._();
  FirebaseAuth._();

  User? _currentUser = User(uid: 'mvp_uid_123', email: 'demo@healsearch.com');

  User? get currentUser => _currentUser;

  Future<UserCredential> signInWithEmailAndPassword({required String email, required String password}) async {
    _currentUser = User(uid: 'mvp_uid_123', email: email.trim());
    return UserCredential(user: _currentUser!);
  }

  Future<UserCredential> createUserWithEmailAndPassword({required String email, required String password}) async {
    _currentUser = User(uid: 'mvp_uid_123', email: email.trim());
    return UserCredential(user: _currentUser!);
  }

  Future<void> signOut() async {}

  Future<void> sendPasswordResetEmail({required String email}) async {}
}

class User {
  final String uid;
  final String email;
  final String? displayName;
  User({required this.uid, required this.email, this.displayName});

  Future<void> updatePassword(String newPassword) async {}
}

class UserCredential {
  final User user;
  UserCredential({required this.user});
}

class FirebaseFirestore {
  static final FirebaseFirestore instance = FirebaseFirestore._();
  FirebaseFirestore._();

  Map<String, Map<String, Map<String, dynamic>>> _data = {};

  Future<void> _initStorage() async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final folder = Directory('${docDir.path}/SeachAHolic');
      if (!folder.existsSync()) folder.createSync();
      
      final dbFile = File('${folder.path}/firestore_mock.json');
      if (dbFile.existsSync()) {
        final content = dbFile.readAsStringSync();
        if (content.isNotEmpty) {
          final decoded = json.decode(content) as Map<String, dynamic>;
          _data = {};
          decoded.forEach((coll, docs) {
            _data[coll] = {};
            (docs as Map<String, dynamic>).forEach((docId, docData) {
              _data[coll]![docId] = Map<String, dynamic>.from(docData);
            });
          });
        }
      }
    } catch (e) {
      print('Mock Firestore init error: $e');
    }
  }

  Future<void> _saveStorage() async {
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final folder = Directory('${docDir.path}/SeachAHolic');
      if (!folder.existsSync()) folder.createSync();
      
      final dbFile = File('${folder.path}/firestore_mock.json');
      print('DEBUG mock_firestore: Saving to ${dbFile.path}');
      dbFile.writeAsStringSync(json.encode(_data));
      print('DEBUG mock_firestore: Save successful. Data: ${_data.keys}');
    } catch (e) {
      print('Mock Firestore save error: $e');
    }
  }

  CollectionReference collection(String path) {
    return CollectionReference(path, this);
  }
  
  WriteBatch batch() => WriteBatch();
}

class WriteBatch {
  Future<void> commit() async {}
  void set(DocumentReference document, Map<String, dynamic> data, [SetOptions? options]) {}
  void update(DocumentReference document, Map<String, dynamic> data) {}
  void delete(DocumentReference document) {}
}

class CollectionReference {
  final String path;
  final FirebaseFirestore _firestore;
  CollectionReference(this.path, this._firestore);

  DocumentReference doc([String? id]) {
    return DocumentReference(path, id ?? DateTime.now().millisecondsSinceEpoch.toString(), _firestore);
  }

  Future<DocumentReference> add(Map<String, dynamic> data) async {
    final ref = doc();
    await ref.set(data);
    return ref;
  }

  Query where(String field, {dynamic isEqualTo, dynamic isGreaterThanOrEqualTo, dynamic isLessThanOrEqualTo, dynamic isLessThan}) {
    return Query(path, _firestore)..where(field, isEqualTo: isEqualTo, isGreaterThanOrEqualTo: isGreaterThanOrEqualTo, isLessThanOrEqualTo: isLessThanOrEqualTo, isLessThan: isLessThan);
  }
  
  Query orderBy(String field, {bool descending = false}) {
    return Query(path, _firestore)..orderBy(field, descending: descending);
  }

  Query limit(int count) {
    return Query(path, _firestore)..limit(count);
  }

  Future<QuerySnapshot> get() async {
    await _firestore._initStorage();
    final colData = _firestore._data[path] ?? {};
    final docs = colData.entries.map((e) => QueryDocumentSnapshot(e.key, e.value, reference: doc(e.key))).toList();
    return QuerySnapshot(docs);
  }
}

class DocumentReference {
  final String _collectionPath;
  final String id;
  final FirebaseFirestore _firestore;

  DocumentReference(this._collectionPath, this.id, this._firestore);

  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    await _firestore._initStorage();
    if (!_firestore._data.containsKey(_collectionPath)) {
      _firestore._data[_collectionPath] = {};
    }
    if (options?.merge == true && _firestore._data[_collectionPath]!.containsKey(id)) {
      _firestore._data[_collectionPath]![id] = {..._firestore._data[_collectionPath]![id]!, ...data};
    } else {
      _firestore._data[_collectionPath]![id] = data;
    }
    await _firestore._saveStorage();
  }

  Future<void> update(Map<String, dynamic> data) async {
    await set(data, SetOptions(merge: true));
  }

  Future<DocumentSnapshot> get() async {
    await _firestore._initStorage();
    final colData = _firestore._data[_collectionPath];
    if (colData != null && colData.containsKey(id)) {
      return DocumentSnapshot(id, colData[id]!, exists: true, reference: this);
    }
    return DocumentSnapshot(id, {}, exists: false, reference: this);
  }

  Future<void> delete() async {
    await _firestore._initStorage();
    if (_firestore._data.containsKey(_collectionPath)) {
      _firestore._data[_collectionPath]!.remove(id);
      await _firestore._saveStorage();
    }
  }
}

class DocumentSnapshot {
  final String id;
  final Map<String, dynamic> _data;
  final bool exists;
  final DocumentReference? reference;

  DocumentSnapshot(this.id, this._data, {this.exists = true, this.reference});

  dynamic data() => _data;
}

class QueryDocumentSnapshot extends DocumentSnapshot {
  @override
  final DocumentReference reference;
  
  QueryDocumentSnapshot(String id, Map<String, dynamic> data, {required this.reference}) : super(id, data, exists: true, reference: reference);
}

class QuerySnapshot {
  final List<QueryDocumentSnapshot> docs;
  QuerySnapshot(this.docs);
}

class Query {
  final String _collectionPath;
  final FirebaseFirestore _firestore;
  
  final List<Map<String, dynamic>> _conditions = [];
  String? orderByField;
  bool descending = false;
  int? limitCount;

  Query(this._collectionPath, this._firestore);

  Query where(String field, {dynamic isEqualTo, dynamic isGreaterThanOrEqualTo, dynamic isLessThanOrEqualTo, dynamic isLessThan}) {
    _conditions.add({
      'field': field,
      'isEqualTo': isEqualTo,
      'isGreaterThanOrEqualTo': isGreaterThanOrEqualTo,
      'isLessThanOrEqualTo': isLessThanOrEqualTo,
      'isLessThan': isLessThan
    });
    return this;
  }

  Query orderBy(String field, {bool descending = false}) {
    this.orderByField = field;
    this.descending = descending;
    return this;
  }

  Query limit(int count) {
    this.limitCount = count;
    return this;
  }

  Future<QuerySnapshot> get() async {
    await _firestore._initStorage();
    final colData = _firestore._data[_collectionPath] ?? {};
    
    var filtered = colData.entries.toList();
    
    for (var condition in _conditions) {
      final field = condition['field'];
      if (condition['isEqualTo'] != null) {
        filtered = filtered.where((e) => e.value[field] == condition['isEqualTo']).toList();
      }
      if (condition['isGreaterThanOrEqualTo'] != null) {
        filtered = filtered.where((e) {
          var val = e.value[field];
          if (val == null) return false;
          return val.compareTo(condition['isGreaterThanOrEqualTo']) >= 0;
        }).toList();
      }
      if (condition['isLessThanOrEqualTo'] != null) {
        filtered = filtered.where((e) {
          var val = e.value[field];
          if (val == null) return false;
          return val.compareTo(condition['isLessThanOrEqualTo']) <= 0;
        }).toList();
      }
      if (condition['isLessThan'] != null) {
        filtered = filtered.where((e) {
          var val = e.value[field];
          if (val == null) return false;
          return val.compareTo(condition['isLessThan']) < 0;
        }).toList();
      }
    }
    
    if (orderByField != null) {
      filtered.sort((a, b) {
        var valA = a.value[orderByField!];
        var valB = b.value[orderByField!];
        if (valA == null || valB == null) return 0;
        return descending ? valB.compareTo(valA) : valA.compareTo(valB);
      });
    }

    if (limitCount != null && limitCount! < filtered.length) {
      filtered = filtered.sublist(0, limitCount!);
    }

    final docs = filtered.map((e) => QueryDocumentSnapshot(e.key, e.value, reference: _firestore.collection(_collectionPath).doc(e.key))).toList();
    return QuerySnapshot(docs);
  }

  Stream<QuerySnapshot> snapshots() async* {
    while (true) {
      await Future.delayed(Duration(milliseconds: 500));
      yield await get();
    }
  }
}

class FieldValue {
  static String serverTimestamp() => DateTime.now().toIso8601String();
  static int increment(int value) => value;
}

class SetOptions {
  final bool merge;
  SetOptions({this.merge = false});
}

class Timestamp {
  final int seconds;
  final int nanoseconds;
  Timestamp(this.seconds, this.nanoseconds);
  
  static Timestamp now() {
    final dt = DateTime.now();
    return Timestamp(dt.millisecondsSinceEpoch ~/ 1000, 0);
  }
  
  DateTime toDate() {
    return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
  }
}
