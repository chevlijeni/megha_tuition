import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  static String? _cachedToken;
  static Map<String, dynamic>? _cachedHomeData;

  static Map<String, dynamic>? get allHomeData => _cachedHomeData;

  static void clearCache() {
    _cachedHomeData = null;
  }

  static Future<void> saveToken(String token) async {
    _cachedToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  static Future<String?> getToken() async {
    if (_cachedToken != null) return _cachedToken;
    final user = _auth.currentUser;
    if (user != null) {
      _cachedToken = await user.getIdToken();
      return _cachedToken;
    }
    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString('jwt_token');
    return _cachedToken;
  }

  static Future<void> clearToken() async {
    _cachedToken = null;
    await _auth.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }

  // Helper to standardise email format for username login
  static String _formatEmail(String username) {
    final trimmed = username.trim();
    if (trimmed.contains('@')) {
      return trimmed;
    }
    return '$trimmed@meghatuition.com';
  }

  // Login using Firebase Auth (Auto-creates account on first login if needed)
  static Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final email = _formatEmail(username);
      UserCredential userCredential;

      try {
        userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
          // If first time logging in, auto-create user in Firebase Auth
          try {
            userCredential = await _auth.createUserWithEmailAndPassword(
              email: email,
              password: password,
            );
            // Create user profile in Firestore
            await _db.collection('users').doc(userCredential.user!.uid).set({
              'username': username.trim(),
              'email': email,
              'role': 'admin',
              'createdAt': FieldValue.serverTimestamp(),
            });
          } catch (_) {
            return {'success': false, 'message': 'Invalid credentials or login error'};
          }
        } else if (e.code == 'wrong-password') {
          return {'success': false, 'message': 'Invalid password'};
        } else {
          return {'success': false, 'message': e.message ?? 'Login failed'};
        }
      }

      final token = await userCredential.user?.getIdToken() ?? 'firebase_token';
      await saveToken(token);

      return {'success': true, 'message': 'Login successful'};
    } catch (e) {
      return {'success': false, 'message': 'Error during login: ${e.toString()}'};
    }
  }

  // Get Sync Data (Full home bundle for fast loading)
  static Future<Map<String, dynamic>> getSyncData({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedHomeData != null) {
      return {'success': true, 'message': 'Loaded from cache', 'data': _cachedHomeData};
    }

    try {
      final studentsRes = await getStudents(useCache: false);
      final paymentsRes = await getPayments(useCache: false);
      
      final List students = studentsRes['data'] ?? [];
      final List payments = paymentsRes['data'] ?? [];
      
      _calculateStudentBalances(students, payments);
      
      final statsRes = await getDashboardStats(useCache: false);

      final homeBundle = {
        'students': students,
        'payments': payments,
        'stats': statsRes['data'] ?? {},
        'monthlyEarnings': statsRes['monthlyEarnings'] ?? [],
      };

      _cachedHomeData = homeBundle;

      return {
        'success': true,
        'message': 'Sync successful',
        'data': homeBundle,
      };
    } catch (e) {
      return {'success': false, 'message': 'Sync failed: ${e.toString()}'};
    }
  }

  // Create Student
  static Future<Map<String, dynamic>> createStudent(Map<String, dynamic> studentData) async {
    try {
      final dataToSave = Map<String, dynamic>.from(studentData);
      dataToSave['createdAt'] = FieldValue.serverTimestamp();
      dataToSave['updatedAt'] = FieldValue.serverTimestamp();

      final docRef = await _db.collection('students').add(dataToSave);
      
      // Ensure id and _id fields are set in document
      await docRef.update({'id': docRef.id, '_id': docRef.id});
      
      _cachedHomeData = null; // Invalidate cache

      return {
        'success': true,
        'message': 'Student created successfully',
        'data': {'id': docRef.id, '_id': docRef.id, ...dataToSave}
      };
    } catch (e) {
      return {'success': false, 'message': 'Failed to create student: ${e.toString()}'};
    }
  }

  // Get Students
  static Future<Map<String, dynamic>> getStudents({bool useCache = true}) async {
    if (useCache && _cachedHomeData != null && _cachedHomeData!['students'] != null) {
      return {
        'success': true,
        'message': 'Fetched from cache',
        'data': _cachedHomeData!['students']
      };
    }

    try {
      final snapshot = await _db.collection('students').get();
      final students = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        data['_id'] = doc.id;
        return data;
      }).toList();

      return {
        'success': true,
        'message': 'Fetched successfully',
        'data': students,
      };
    } catch (e) {
      return {'success': false, 'message': 'Failed to fetch students: ${e.toString()}'};
    }
  }

  // Get single student by ID
  static Future<Map<String, dynamic>> getStudentById(String id) async {
    try {
      final doc = await _db.collection('students').doc(id).get();
      if (!doc.exists) {
        return {'success': false, 'message': 'Student not found'};
      }

      final data = doc.data()!;
      data['id'] = doc.id;
      data['_id'] = doc.id;

      return {
        'success': true,
        'message': 'Fetched successfully',
        'data': data,
      };
    } catch (e) {
      return {'success': false, 'message': 'Failed to fetch student details: ${e.toString()}'};
    }
  }

  // Update student
  static Future<Map<String, dynamic>> updateStudent(String id, Map<String, dynamic> studentData) async {
    try {
      final dataToUpdate = Map<String, dynamic>.from(studentData);
      dataToUpdate['updatedAt'] = FieldValue.serverTimestamp();

      await _db.collection('students').doc(id).update(dataToUpdate);

      _cachedHomeData = null; // Invalidate cache

      final updatedDoc = await _db.collection('students').doc(id).get();
      final data = updatedDoc.data() ?? {};
      data['id'] = id;
      data['_id'] = id;

      return {
        'success': true,
        'message': 'Updated successfully',
        'data': data,
      };
    } catch (e) {
      return {'success': false, 'message': 'Failed to update student: ${e.toString()}'};
    }
  }

  // Delete student and associated payments
  static Future<Map<String, dynamic>> deleteStudent(String studentId) async {
    try {
      await _db.collection('students').doc(studentId).delete();

      // Delete associated payments
      final paymentsSnapshot = await _db.collection('payments').where('studentId', isEqualTo: studentId).get();
      for (var doc in paymentsSnapshot.docs) {
        await doc.reference.delete();
      }

      _cachedHomeData = null; // Invalidate cache

      return {
        'success': true,
        'message': 'Student deleted successfully',
      };
    } catch (e) {
      return {'success': false, 'message': 'Failed to delete student: ${e.toString()}'};
    }
  }

  static Future<Map<String, dynamic>> collectFee(Map<String, dynamic> paymentData) async {
    try {
      final dataToSave = Map<String, dynamic>.from(paymentData);
      final now = DateTime.now();
      final nowStr = now.toIso8601String();
      dataToSave['createdAt'] = FieldValue.serverTimestamp();
      dataToSave['paymentDate'] = nowStr;
      dataToSave['month'] = now.month;
      dataToSave['year'] = now.year;

      final docRef = await _db.collection('payments').add(dataToSave);
      await docRef.update({'id': docRef.id, '_id': docRef.id});

      // Update student's fee payment balance and status if studentId exists
      final studentId = dataToSave['studentId'] ?? dataToSave['student'];
      if (studentId != null && studentId.toString().isNotEmpty) {
        final studentDoc = await _db.collection('students').doc(studentId.toString()).get();
        if (studentDoc.exists) {
          final studentData = studentDoc.data() ?? {};
          final num amountPaid = (dataToSave['amount'] ?? dataToSave['amountPaid'] ?? 0);
          final num currentPaid = (studentData['paidAmount'] ?? studentData['totalPaid'] ?? 0);
          final num newPaid = currentPaid + amountPaid;
          final num totalFee = (studentData['feeDetails']?['feeAmount'] ?? studentData['totalFees'] ?? studentData['totalFee'] ?? 0);
          final num newBalance = (totalFee - newPaid) > 0 ? (totalFee - newPaid) : 0;

          await _db.collection('students').doc(studentId.toString()).update({
            'isPaidCurrentMonth': newBalance <= 0,
            'paidAmount': newPaid,
            'totalPaid': newPaid,
            'balance': newBalance,
            'pendingBalance': newBalance,
            'lastPaymentDate': FieldValue.serverTimestamp(),
            'paymentDetails': {
              'amount': amountPaid,
              'paymentDate': nowStr,
              'paymentMethod': dataToSave['paymentMethod'] ?? 'Cash',
            },
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }

      _cachedHomeData = null; // Invalidate cache

      return {
        'success': true,
        'message': 'Fee collected successfully',
        'data': {'id': docRef.id, '_id': docRef.id, ...dataToSave}
      };
    } catch (e) {
      return {'success': false, 'message': 'Failed to collect payment: ${e.toString()}'};
    }
  }

  // Get payments
  static Future<Map<String, dynamic>> getPayments({bool useCache = true}) async {
    if (useCache && _cachedHomeData != null && _cachedHomeData!['payments'] != null) {
      return {
        'success': true,
        'message': 'Fetched from cache',
        'data': _cachedHomeData!['payments']
      };
    }

    try {
      final studentsRes = await getStudents(useCache: useCache);
      final List studentsList = studentsRes['data'] ?? [];
      final Map<String, dynamic> studentMap = {};
      for (var s in studentsList) {
        final id1 = s['_id']?.toString();
        final id2 = s['id']?.toString();
        final id3 = s['studentId']?.toString();
        if (id1 != null) studentMap[id1] = s;
        if (id2 != null) studentMap[id2] = s;
        if (id3 != null) studentMap[id3] = s;
      }

      final snapshot = await _db.collection('payments').orderBy('createdAt', descending: true).get();
      final payments = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        data['_id'] = doc.id;

        final sid = (data['studentId'] ?? data['student'])?.toString();
        if (sid != null && studentMap.containsKey(sid)) {
          data['student'] = studentMap[sid];
        }

        return data;
      }).toList();

      return {
        'success': true,
        'message': 'Fetched payments successfully',
        'data': payments,
      };
    } catch (e) {
      // Fallback without ordering if index not built yet
      try {
        final studentsRes = await getStudents(useCache: useCache);
        final List studentsList = studentsRes['data'] ?? [];
        final Map<String, dynamic> studentMap = {};
        for (var s in studentsList) {
          final id1 = s['_id']?.toString();
          final id2 = s['id']?.toString();
          final id3 = s['studentId']?.toString();
          if (id1 != null) studentMap[id1] = s;
          if (id2 != null) studentMap[id2] = s;
          if (id3 != null) studentMap[id3] = s;
        }

        final snapshot = await _db.collection('payments').get();
        final payments = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          data['_id'] = doc.id;

          final sid = (data['studentId'] ?? data['student'])?.toString();
          if (sid != null && studentMap.containsKey(sid)) {
            data['student'] = studentMap[sid];
          }

          return data;
        }).toList();

        return {
          'success': true,
          'message': 'Fetched payments successfully',
          'data': payments,
        };
      } catch (err) {
        return {'success': false, 'message': 'Failed to fetch payments: ${err.toString()}'};
      }
    }
  }

  // Get payments for a specific student
  static Future<Map<String, dynamic>> getStudentPayments(String studentId) async {
    try {
      final studentDoc = await _db.collection('students').doc(studentId).get();
      Map<String, dynamic>? studentData;
      if (studentDoc.exists) {
        studentData = studentDoc.data();
        studentData?['id'] = studentDoc.id;
        studentData?['_id'] = studentDoc.id;
      }

      final snapshot = await _db.collection('payments').where('studentId', isEqualTo: studentId).get();
      final payments = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        data['_id'] = doc.id;
        return data;
      }).toList();

      return {
        'success': true,
        'message': 'Fetched student payments successfully',
        'data': {
          'student': studentData,
          'payments': payments,
        },
      };
    } catch (e) {
      return {'success': false, 'message': 'Failed to fetch student payments: ${e.toString()}'};
    }
  }

  static num _safeNum(dynamic val) {
    if (val == null) return 0;
    if (val is num) return val;
    if (val is String) {
      return num.tryParse(val) ?? 0;
    }
    return 0;
  }

  static DateTime? _parseDate(dynamic val) {
    if (val == null) return null;
    if (val is Timestamp) return val.toDate().toLocal();
    if (val is String) {
      try { return DateTime.parse(val).toLocal(); } catch (_) { return null; }
    }
    if (val is int) return DateTime.fromMillisecondsSinceEpoch(val).toLocal();
    try { return (val as dynamic).toDate().toLocal(); } catch (_) { return null; }
  }

  static void _calculateStudentBalances(List students, List payments) {
    final now = DateTime.now();
    final Map<String, num> currentMonthCollectionsByStudent = {};
    for (var p in payments) {
      final pDate = _parseDate(p['paymentDate'] ?? p['createdAt']);
      if (pDate != null && pDate.year == now.year && pDate.month == now.month) {
        final sId = (p['studentId'] ?? p['student'] ?? '').toString();
        if (sId.isNotEmpty) {
          final amt = _safeNum(p['amount'] ?? p['amountPaid']);
          currentMonthCollectionsByStudent[sId] = (currentMonthCollectionsByStudent[sId] ?? 0) + amt;
        }
      }
    }

    for (var s in students) {
      num tf = 0;
      final feeDetails = s['feeDetails'];
      if (feeDetails is Map) {
        tf = _safeNum(feeDetails['feeAmount']);
      } else {
        tf = _safeNum(s['totalFees'] ?? s['totalFee'] ?? s['feeAmount'] ?? s['monthlyFee']);
      }

      final sId = (s['id'] ?? s['_id'] ?? '').toString();
      final collectedThisMonth = currentMonthCollectionsByStudent[sId] ?? 0;
      final bal = (tf - collectedThisMonth) > 0 ? (tf - collectedThisMonth) : 0;
      
      s['isPaidCurrentMonth'] = (bal <= 0 && tf > 0);
      s['balance'] = bal;
      s['pendingBalance'] = bal;
    }
  }

  // Get dashboard statistics
  static Future<Map<String, dynamic>> getDashboardStats({bool useCache = true}) async {
    if (useCache && _cachedHomeData != null && _cachedHomeData!['stats'] != null) {
      return {
        'success': true,
        'message': 'Fetched from cache',
        'data': _cachedHomeData!['stats'],
        'monthlyEarnings': _cachedHomeData!['monthlyEarnings'] ?? [],
      };
    }

    try {
      final studentsRes = await getStudents(useCache: useCache);
      final List students = studentsRes['data'] ?? [];

      final paymentsRes = await getPayments(useCache: useCache);
      final List payments = paymentsRes['data'] ?? [];

      _calculateStudentBalances(students, payments);

      int totalStudents = 0;
      num totalFees = 0;
      num totalCollected = 0;
      num totalPending = 0;

      for (var s in students) {
        final status = s['status'] ?? 'Active';
        if (status != 'Active') continue;

        totalStudents++;

        num tf = 0;
        final feeDetails = s['feeDetails'];
        if (feeDetails is Map) {
          tf = _safeNum(feeDetails['feeAmount']);
        } else {
          tf = _safeNum(s['totalFees'] ?? s['totalFee'] ?? s['feeAmount'] ?? s['monthlyFee']);
        }

        num bal = _safeNum(s['balance'] ?? s['pendingBalance'] ?? tf);
        totalFees += tf;
        totalPending += bal;
      }

      final now = DateTime.now();
      num collectedToday = 0;
      int transactionsToday = 0;

      for (var p in payments) {
        final amt = _safeNum(p['amount'] ?? p['amountPaid']);
        totalCollected += amt;

        final pDate = _parseDate(p['paymentDate'] ?? p['createdAt']);
        if (pDate != null) {
          if (pDate.year == now.year && pDate.month == now.month && pDate.day == now.day) {
            collectedToday += amt;
            transactionsToday++;
          }
        }
      }

      // Group payments by month and year for monthly earnings (last 6 months)
      final Map<String, num> groupedCollected = {};
      for (var p in payments) {
        final pDate = _parseDate(p['paymentDate'] ?? p['createdAt']);
        if (pDate != null) {
          final key = "${pDate.year}-${pDate.month}";
          final amt = _safeNum(p['amount'] ?? p['amountPaid']);
          groupedCollected[key] = (groupedCollected[key] ?? 0) + amt;
        }
      }

      final List<Map<String, dynamic>> monthlyEarnings = [];
      for (int i = 0; i < 6; i++) {
        final date = DateTime(now.year, now.month - i, 1);
        final key = "${date.year}-${date.month}";
        final collected = groupedCollected[key] ?? 0;
        
        monthlyEarnings.add({
          '_id': {
            'month': date.month,
            'year': date.year,
          },
          'collected': collected.toDouble(),
          'expected': totalFees.toDouble(), // current totalFees as baseline
        });
      }

      final stats = {
        'totalStudents': totalStudents,
        'totalFees': totalFees,
        'pendingFees': totalPending,
        'totalPending': totalPending,
        'totalCollection': totalCollected,
        'totalCollected': totalCollected,
        'totalPayments': payments.length,
        'collectedToday': collectedToday,
        'transactionsToday': transactionsToday,
      };

      return {
        'success': true,
        'message': 'Dashboard stats calculated',
        'data': stats,
        'monthlyEarnings': monthlyEarnings,
      };
    } catch (e) {
      return {'success': false, 'message': 'Failed to calculate stats: ${e.toString()}'};
    }
  }

  // Get user profile
  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {'success': false, 'message': 'No logged in user found'};
      }

      final doc = await _db.collection('users').doc(user.uid).get();
      Map<String, dynamic> userData = doc.exists ? (doc.data() ?? {}) : {};

      userData['email'] = user.email ?? userData['email'];
      userData['username'] = userData['username'] ?? user.email?.split('@').first ?? 'Admin';

      return {
        'success': true,
        'message': 'Profile fetched successfully',
        'data': userData,
      };
    } catch (e) {
      return {'success': false, 'message': 'Failed to fetch profile: ${e.toString()}'};
    }
  }

  // Update user profile
  static Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> userData) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {'success': false, 'message': 'No logged in user found'};
      }

      await _db.collection('users').doc(user.uid).set(userData, SetOptions(merge: true));

      return {
        'success': true,
        'message': 'Profile updated successfully',
        'data': userData,
      };
    } catch (e) {
      return {'success': false, 'message': 'Failed to update profile: ${e.toString()}'};
    }
  }
}
