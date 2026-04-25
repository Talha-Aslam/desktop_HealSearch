import 'package:desktop_search_a_holic/mock_firebase.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Check if user is logged in
  bool get isLoggedIn => _auth.currentUser != null;

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Register with email and password
  Future<UserCredential> createUserWithEmailAndPassword(
      String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Store user data in Firestore
  Future<void> storeUserData(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('pharmacies').doc(userId).set(data);
    } catch (e) {
      rethrow;
    }
  }

  // Get user data from Firestore
  Future<DocumentSnapshot> getUserData(String userId) async {
    try {
      return await _firestore.collection('pharmacies').doc(userId).get();
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } catch (e) {
      rethrow;
    }
  }

  // Update user password
  Future<void> updatePassword(String newPassword) async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        await user.updatePassword(newPassword);
      } else {
        throw Exception('No user is currently signed in');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Test Firebase connection
  Future<bool> testFirebaseConnection() async {
    try {
      // Try to perform a simple read operation
      await _firestore.collection('test').limit(1).get();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Check if user has a valid shop ID
  Future<bool> hasValidShopId() async {
    try {
      String? shopId = await getUserShopId();
      return shopId != null && shopId.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Get or create shop ID for current user
  Future<String> ensureUserHasShopId() async {
    try {
      // Check if user is logged in
      if (_auth.currentUser == null) {
        throw Exception('User not logged in');
      }

      String? existingShopId = await getUserShopId();
      if (existingShopId != null && existingShopId.isNotEmpty) {
        return existingShopId;
      }

      // Generate a new shop ID if user doesn't have one
      String newShopId = 'shop_${_auth.currentUser!.uid}_${DateTime.now().millisecondsSinceEpoch}';
      
      // Update user's shop ID
      await _firestore.collection('pharmacies').doc(_auth.currentUser!.uid).update({
        'shopId': newShopId,
        'updatedAt': DateTime.now().toIso8601String()
      });

      return newShopId;
    } catch (e) {
      rethrow;
    }
  }

  // Product-related methods

  // Add a new product to Firestore
  Future<String> addProduct(Map<String, dynamic> productData) async {
    try {
      // Check if user is logged in
      if (_auth.currentUser == null) {
        throw Exception('User not logged in');
      }

      // Add user email to product data
      productData['userEmail'] = _auth.currentUser!.email;
      
      // Add timestamps
      productData['createdAt'] = DateTime.now().toIso8601String();
      productData['updatedAt'] = DateTime.now().toIso8601String();
      
      // Get user data to retrieve the shop ID
      DocumentSnapshot userData = await _firestore.collection('pharmacies').doc(_auth.currentUser!.uid).get();
      if (userData.exists) {
        Map<String, dynamic> userDataMap = userData.data() as Map<String, dynamic>;
        // Add shop ID to product data if available
        if (userDataMap.containsKey('shopId') && userDataMap['shopId'] != null && userDataMap['shopId'] != '') {
          productData['shopId'] = userDataMap['shopId'];
        } else {
          productData['shopId'] = 'mock_shop_id'; // MVP fallback
        }
      } else {
        productData['shopId'] = 'mock_shop_id'; // MVP fallback for no profile
      }

      DocumentReference docRef =
          await _firestore.collection('products').add(productData);
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  // Add a new medicine/product with shop ID validation
  Future<String> addMedicine(Map<String, dynamic> medicineData) async {
    try {
      // Ensure user has a shop ID
      String shopId = 'mock_shop_id';
      try {
        shopId = await ensureUserHasShopId();
      } catch (e) {
        // Fallback to mock shop ID
      }
      
      // Add medicine-specific fields
      medicineData['type'] = 'medicine';
      medicineData['shopId'] = shopId;
      medicineData['userEmail'] = _auth.currentUser!.email;
      medicineData['createdAt'] = DateTime.now().toIso8601String();
      medicineData['updatedAt'] = DateTime.now().toIso8601String();
      
      // Validate required medicine fields
      List<String> requiredFields = ['name', 'price', 'quantity'];
      for (String field in requiredFields) {
        if (!medicineData.containsKey(field) || medicineData[field] == null || medicineData[field].toString().isEmpty) {
          throw Exception('Missing required field: $field');
        }
      }

      DocumentReference docRef = await _firestore.collection('products').add(medicineData);
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  // Get all products from Firestore (filtered by current user)
  Future<List<Map<String, dynamic>>> getProducts() async {
    try {
      // Check if user is logged in
      if (_auth.currentUser == null) {
        throw Exception('User not logged in');
      }

      // Filter products by current user's email
      QuerySnapshot querySnapshot = await _firestore
          .collection('products')
          .where('userEmail', isEqualTo: _auth.currentUser!.email)
          .get();

      List<Map<String, dynamic>> products = [];
      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> productData =
            Map<String, dynamic>.from(doc.data() as Map);
        productData['id'] = doc.id; // Add document ID to the product data
        products.add(productData);
      }

      return products;
    } catch (e) {
      rethrow;
    }
  }
  
  // Get all products from Firestore by shop ID
  Future<List<Map<String, dynamic>>> getProductsByShopId(String shopId) async {
    try {
      // Check if user is logged in
      if (_auth.currentUser == null) {
        throw Exception('User not logged in');
      }

      // Filter products by shop ID
      QuerySnapshot querySnapshot = await _firestore
          .collection('products')
          .where('shopId', isEqualTo: shopId)
          .get();

      List<Map<String, dynamic>> products = [];
      for (var doc in querySnapshot.docs) {
        Map<String, dynamic> productData =
            Map<String, dynamic>.from(doc.data() as Map);
        productData['id'] = doc.id; // Add document ID to the product data
        products.add(productData);
      }

      return products;
    } catch (e) {
      rethrow;
    }
  }

  // Get products stream for real-time updates (filtered by current user)
  Stream<List<Map<String, dynamic>>> getProductsStream() {
    // Check if user is logged in
    if (_auth.currentUser == null) {
      return Stream.value([]); // Return empty stream if no user
    }

    return _firestore
        .collection('products')
        .where('userEmail', isEqualTo: _auth.currentUser!.email)
        .snapshots()
        .map((snapshot) {
      List<Map<String, dynamic>> products = [];
      for (var doc in snapshot.docs) {
        Map<String, dynamic> productData =
            Map<String, dynamic>.from(doc.data() as Map);
        productData['id'] = doc.id;
        products.add(productData);
      }
      return products;
    });
  }
  
  // Get products stream for real-time updates by shop ID
  Stream<List<Map<String, dynamic>>> getProductsStreamByShopId(String shopId) {
    // Check if user is logged in
    if (_auth.currentUser == null) {
      return Stream.value([]); // Return empty stream if no user
    }

    return _firestore
        .collection('products')
        .where('shopId', isEqualTo: shopId)
        .snapshots()
        .map((snapshot) {
      List<Map<String, dynamic>> products = [];
      for (var doc in snapshot.docs) {
        Map<String, dynamic> productData =
            Map<String, dynamic>.from(doc.data() as Map);
        productData['id'] = doc.id;
        products.add(productData);
      }
      return products;
    });
  }

  // Update a product in Firestore (only if it belongs to current user)
  Future<void> updateProduct(
      String productId, Map<String, dynamic> productData) async {
    try {
      // Check if user is logged in
      if (_auth.currentUser == null) {
        throw Exception('User not logged in');
      }

      // First, verify that the product belongs to the current user
      DocumentSnapshot doc =
          await _firestore.collection('products').doc(productId).get();
      if (!doc.exists) {
        throw Exception('Product not found');
      }

      Map<String, dynamic> existingData =
          Map<String, dynamic>.from(doc.data() as Map);
      if (existingData['userEmail'] != _auth.currentUser!.email) {
        throw Exception(
            'Access denied - product does not belong to current user');
      }

      // Add updated timestamp and ensure userEmail is preserved
      productData['updatedAt'] = DateTime.now().toIso8601String();
      productData['userEmail'] = _auth.currentUser!.email;
      
      // Preserve the shop ID if it exists in the original document
      if (existingData.containsKey('shopId') && existingData['shopId'] != null) {
        productData['shopId'] = existingData['shopId'];
      } else {
        // Get shop ID from user profile if not already in the product
        try {
          DocumentSnapshot userData = await _firestore.collection('pharmacies').doc(_auth.currentUser!.uid).get();
          if (userData.exists) {
            Map<String, dynamic> userDataMap = userData.data() as Map<String, dynamic>;
            if (userDataMap.containsKey('shopId') && userDataMap['shopId'] != null && userDataMap['shopId'] != '') {
              productData['shopId'] = userDataMap['shopId'];
            }
          }
        } catch (e) {
          print('Error getting shop ID for update: $e');
        }
      }

      await _firestore
          .collection('products')
          .doc(productId)
          .update(productData);
    } catch (e) {
      rethrow;
    }
  }

  // Delete a product from Firestore (only if it belongs to current user)
  Future<void> deleteProduct(String productId) async {
    try {
      // Check if user is logged in
      if (_auth.currentUser == null) {
        throw Exception('User not logged in');
      }

      // First, verify that the product belongs to the current user
      DocumentSnapshot doc =
          await _firestore.collection('products').doc(productId).get();
      if (!doc.exists) {
        throw Exception('Product not found');
      }

      Map<String, dynamic> existingData =
          Map<String, dynamic>.from(doc.data() as Map);
      if (existingData['userEmail'] != _auth.currentUser!.email) {
        throw Exception(
            'Access denied - product does not belong to current user');
      }

      await _firestore.collection('products').doc(productId).delete();
    } catch (e) {
      rethrow;
    }
  }

  // Get a single product by ID (only if it belongs to current user)
  Future<Map<String, dynamic>?> getProduct(String productId) async {
    try {
      // Check if user is logged in
      if (_auth.currentUser == null) {
        throw Exception('User not logged in');
      }

      DocumentSnapshot doc =
          await _firestore.collection('products').doc(productId).get();
      if (doc.exists) {
        Map<String, dynamic> productData =
            Map<String, dynamic>.from(doc.data() as Map);

        // Check if the product belongs to the current user
        if (productData['userEmail'] == _auth.currentUser!.email) {
          productData['id'] = doc.id;
          return productData;
        } else {
          // Product doesn't belong to current user
          throw Exception('Product not found or access denied');
        }
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }
  
  // Get user's shop ID
  Future<String?> getUserShopId() async {
    try {
      // Check if user is logged in
      if (_auth.currentUser == null) {
        throw Exception('User not logged in');
      }
      
      DocumentSnapshot doc = 
          await _firestore.collection('pharmacies').doc(_auth.currentUser!.uid).get();
          
      if (doc.exists) {
        Map<String, dynamic> userData = 
            Map<String, dynamic>.from(doc.data() as Map);
            
        return userData['shopId'] as String?;
      }
      
      return null;
    } catch (e) {
      rethrow;
    }
  }
  
  // Create or update shop information
  Future<void> createOrUpdateShop(String shopId, Map<String, dynamic> shopData) async {
    try {
      // Check if user is logged in
      if (_auth.currentUser == null) {
        throw Exception('User not logged in');
      }
      
      // Add owner email to shop data
      shopData['ownerEmail'] = _auth.currentUser!.email;
      shopData['updatedAt'] = DateTime.now().toIso8601String();
      
      if (!shopData.containsKey('createdAt')) {
        shopData['createdAt'] = DateTime.now().toIso8601String();
      }
      
      // Create or update shop document
      await _firestore.collection('shops').doc(shopId).set(
        shopData, 
        SetOptions(merge: true)
      );
      
      // Update user's shop ID
      await _firestore.collection('pharmacies').doc(_auth.currentUser!.uid).update({
        'shopId': shopId
      });
    } catch (e) {
      rethrow;
    }
  }
}
