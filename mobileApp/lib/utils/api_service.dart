import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:5000/api/v1';

  // Save token to local storage
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  // Get token from local storage
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  // Clear token (logout)
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }

  // Login method
  static Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

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

      final response = await http.post(
        Uri.parse('$baseUrl/students'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(studentData),
      );

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

  // Get Students method
  static Future<Map<String, dynamic>> getStudents() async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'No authentication token found'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/students'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

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

      final response = await http.get(
        Uri.parse('$baseUrl/students/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

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

      final response = await http.put(
        Uri.parse('$baseUrl/students/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(studentData),
      );

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
  static Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'No authentication token found'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/students/stats'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

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
  static Future<Map<String, dynamic>> getPayments() async {
    try {
      final token = await getToken();
      if (token == null) {
        return {'success': false, 'message': 'No authentication token found'};
      }

      final response = await http.get(
        Uri.parse('$baseUrl/students/payments'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

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

      final response = await http.post(
        Uri.parse('$baseUrl/students/collect-fee'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(paymentData),
      );

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
}
