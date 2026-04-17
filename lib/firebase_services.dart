import 'package:desktop_search_a_holic/mock_firebase.dart';
import 'package:desktop_search_a_holic/mock_firebase.dart';

class FirebaseServices {
  // Authentication functions
  static Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      return await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  static Future<UserCredential> createUserWithEmailAndPassword(
      String email, String password) async {
    try {
      return await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  static User? getCurrentUser() {
    return FirebaseAuth.instance.currentUser;
  }

  // Firestore functions
  static Future<void> addDocument(
      String collection, Map<String, dynamic> data) async {
    await FirebaseFirestore.instance.collection(collection).add(data);
  }

  static Future<void> setDocument(
      String collection, String documentId, Map<String, dynamic> data) async {
    await FirebaseFirestore.instance
        .collection(collection)
        .doc(documentId)
        .set(data);
  }

  static Future<DocumentSnapshot> getDocument(
      String collection, String documentId) async {
    return await FirebaseFirestore.instance
        .collection(collection)
        .doc(documentId)
        .get();
  }

  static Future<QuerySnapshot> getCollection(String collection) async {
    return await FirebaseFirestore.instance.collection(collection).get();
  }

  static Future<void> updateDocument(
      String collection, String documentId, Map<String, dynamic> data) async {
    await FirebaseFirestore.instance
        .collection(collection)
        .doc(documentId)
        .update(data);
  }

  static Future<void> deleteDocument(
      String collection, String documentId) async {
    await FirebaseFirestore.instance
        .collection(collection)
        .doc(documentId)
        .delete();
  }

  // Password reset
  static Future<void> sendPasswordResetEmail(String email) async {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());
  }

  // Product management functions
  static Future<String> addProduct(Map<String, dynamic> productData) async {
    try {
      // Add current user ID to product data
      User? currentUser = getCurrentUser();
      if (currentUser != null) {
        productData['userId'] = currentUser.uid;
        productData['createdAt'] = FieldValue.serverTimestamp();
        productData['updatedAt'] = FieldValue.serverTimestamp();
      }

      DocumentReference docRef = await FirebaseFirestore.instance
          .collection('products')
          .add(productData);
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  static Future<QuerySnapshot> getProducts() async {
    try {
      User? currentUser = getCurrentUser();
      if (currentUser != null) {
        return await FirebaseFirestore.instance
            .collection('products')
            .where('userId', isEqualTo: currentUser.uid)
            .get();
      } else {
        throw Exception('No user is currently signed in');
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> updateProduct(
      String productId, Map<String, dynamic> productData) async {
    try {
      productData['updatedAt'] = FieldValue.serverTimestamp();
      await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .update(productData);
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> deleteProduct(String productId) async {
    try {
      await FirebaseFirestore.instance
          .collection('products')
          .doc(productId)
          .delete();
    } catch (e) {
      rethrow;
    }
  }
}
