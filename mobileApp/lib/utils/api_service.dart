import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // static const String baseUrl = 'https://megha-tuition.onrender.com/api/v1';
  static const String baseUrl = 'http://localhost:5000/api/v1';

  // Persistent client for connection pooling (reduces TLS handshake overhead)
  static final http.Client _client = http.Client();
  
  // In-memory token cache to avoid Repeated SharedPreferences disk access
  static String? _cachedToken;

  static const Duration _timeout = Duration(seconds: 30);

  // In-memory cache for all home data
  static Map<String, dynamic>? _cachedHomeData;

  // Getter for cached home data
  static Map<String, dynamic>? get allHomeData => _cachedHomeData;

  // Clear all cache
  static void clearCache() {
    _cachedHomeData = null;
  }

  // Save token to local storage
  static Future<void> saveToken(String token) async {
    _cachedToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  // Get token from local storage
  static Future<String?> getToken() async {
    if (_cachedToken != null) return _cachedToken;
    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString('jwt_token');
    return _cachedToken;
  }

  // Clear token (logout)
  static Future<void> clearToken() async {
    _cachedToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }

  // Login method
  static Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await _client.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      ).timeout(_timeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Success
        final token = data['data']['token'];
        await saveToken(token);
        return {'success': true, 'message': 'Login successful'};
      } else {
        // Failure
        return {
          'success': false,
          'message': data['message'] ?? 'Invalid credentials'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connectivity problem. Please check if the server is running.'
      };
    }
  }

  // Create Student method
  static Future<Map<String, dynamic>> createStudent(Map<String, dynamic> studentData) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'No authentication token found'};
      }

      final response = await _client.post(
        Uri.parse('$baseUrl/students'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(studentData),
      ).timeout(_timeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {'success': true, 'message': data['message'] ?? 'Student created successfully'};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to create student'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connectivity problem. Please check if the server is running.'
      };
    }
  }

  // Get Sync Data (Full home bundle)
  static Future<Map<String, dynamic>> getSyncData({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedHomeData != null) {
      return {'success': true, 'message': 'Loaded from cache', 'data': _cachedHomeData};
    }

    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'No authentication token found'};
      }

      final response = await _client.get(
        Uri.parse('$baseUrl/students/sync'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(_timeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        _cachedHomeData = data['data'];
        return {
          'success': true, 
          'message': 'Sync successful',
          'data': data['data']
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to sync data'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connectivity problem. Please check if the server is running.'
      };
    }
  }

  // Get Students method
  static Future<Map<String, dynamic>> getStudents({bool useCache = true}) async {
    if (useCache && _cachedHomeData != null && _cachedHomeData!['students'] != null) {
        return {
          'success': true, 
          'message': 'Fetched from cache',
          'data': _cachedHomeData!['students']
        };
    }
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'No authentication token found'};
      }

      final response = await _client.get(
        Uri.parse('$baseUrl/students'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(_timeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true, 
          'message': 'Fetched successfully',
          'data': data['data']
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch students'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connectivity problem. Please check if the server is running.'
      };
    }
  }

  // Get single student by ID
  static Future<Map<String, dynamic>> getStudentById(String id) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'No authentication token found'};
      }

      final response = await _client.get(
        Uri.parse('$baseUrl/students/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(_timeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true, 
          'message': 'Fetched successfully',
          'data': data['data']
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch student details'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connectivity problem. Please check if the server is running.'
      };
    }
  }

  // Update student
  static Future<Map<String, dynamic>> updateStudent(String id, Map<String, dynamic> studentData) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'No authentication token found'};
      }

      final response = await _client.put(
        Uri.parse('$baseUrl/students/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(studentData),
      ).timeout(_timeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true, 
          'message': data['message'] ?? 'Updated successfully',
          'data': data['data']
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update student'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connectivity problem. Please check if the server is running.'
      };
    }
  }

  // Get dashboard statistics
  static Future<Map<String, dynamic>> getDashboardStats({bool useCache = true}) async {
    if (useCache && _cachedHomeData != null && _cachedHomeData!['stats'] != null) {
        return {
          'success': true, 
          'message': 'Fetched from cache',
          'data': _cachedHomeData!['stats']
        };
    }
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'No authentication token found'};
      }

      final response = await _client.get(
        Uri.parse('$baseUrl/students/stats'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(_timeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true, 
          'message': data['message'],
          'data': data['data']
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch statistics'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connectivity problem. Please check if the server is running.'
      };
    }
  }

  // Get recent payments/transactions
  static Future<Map<String, dynamic>> getPayments({bool useCache = true}) async {
    if (useCache && _cachedHomeData != null && _cachedHomeData!['payments'] != null) {
        return {
          'success': true, 
          'message': 'Fetched from cache',
          'data': _cachedHomeData!['payments']
        };
    }
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'No authentication token found'};
      }

      final response = await _client.get(
        Uri.parse('$baseUrl/students/payments'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(_timeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true, 
          'message': data['message'],
          'data': data['data']
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch payments'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connectivity problem. Please check if the server is running.'
      };
    }
  }

  // Collect fee payment
  static Future<Map<String, dynamic>> collectFee(Map<String, dynamic> paymentData) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'No authentication token found'};
      }

      final response = await _client.post(
        Uri.parse('$baseUrl/students/collect-fee'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(paymentData),
      ).timeout(_timeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {
          'success': true, 
          'message': data['message'],
          'data': data['data']
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to collect payment'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connectivity problem. Please check if the server is running.'
      };
    }
  }
  // Get payments for a specific student
  static Future<Map<String, dynamic>> getStudentPayments(String studentId) async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'No authentication token found'};
      }

      final response = await _client.get(
        Uri.parse('$baseUrl/students/$studentId/payments'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(_timeout);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true, 
          'message': data['message'],
          'data': data['data']
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch student payments'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Connectivity problem. Please check if the server is running.'
      };
    }
  }
}
