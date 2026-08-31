import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page.dart';

class ApiService {
  static const String MasterApi = "https://edusathi.in/api";
  static const Duration timeout = Duration(seconds: 20);

  static final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  // ================= TOKEN =================

  static Future<String> _getToken() async {
    final prefs = await SharedPreferences.getInstance();

    final secureToken = await _secureStorage.read(key: 'auth_token');
    if (secureToken != null && secureToken.isNotEmpty) {
      return secureToken;
    }

    return prefs.getString('auth_token') ?? '';
  }

  static Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();

    final tenantId = prefs.getString("tenant_id") ?? "";

    if (tenantId.isEmpty) {
      return "https://edusathi.in/api";
    }

    final url = "https://$tenantId.edusathi.in/api";

    debugPrint("🌍 BASE URL => $url");

    return url;
  }
  // ================= LOGOUT =================

  static Future<void> forceLogout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final tenantId = prefs.getString('tenant_id');
    final schoolName = prefs.getString('school_name');

    await prefs.clear();
    await _secureStorage.deleteAll();

    if (tenantId != null) {
      await prefs.setString('tenant_id', tenantId);
    }

    if (schoolName != null) {
      await prefs.setString('school_name', schoolName);
    }

    if (!context.mounted) return;

    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => LoginPage()),
      (route) => false,
    );
  }

  static Future<String> getToken() async {
    return await _getToken();
  }

  static Future<Map<String, String>> headers() async {
    return await _headers();
  }
  // ================= HEADERS =================

  static Future<Map<String, String>> _headers() async {
    final token = await _getToken();
    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
  }

  // ================= POST WITHOUT TOKEN (LOGIN / OTP) =================
  static Future<http.Response?> postPublic(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final baseUrl = await getBaseUrl();

      debugPrint("📤 POST URL => $baseUrl$endpoint");
      debugPrint("📤 BODY => ${jsonEncode(body ?? {})}");

      final response = await http
          .post(
            Uri.parse("$baseUrl$endpoint"),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body ?? {}),
          )
          .timeout(timeout);

      debugPrint("✅ STATUS => ${response.statusCode}");
      debugPrint("✅ RESPONSE => ${response.body}");

      return response;
    } on TimeoutException {
      debugPrint("⏱ API TIMEOUT: $endpoint");
      return null;
    } catch (e) {
      debugPrint("🚨 POST ERROR: $e");
      return null;
    }
  }

  // ================= GET =================

  static Future<http.Response?> get(
    BuildContext context,
    String endpoint,
  ) async {
    final token = await _getToken();

    if (token.isEmpty) {
      await forceLogout(context);
      return null;
    }

    try {
      final baseUrl = await getBaseUrl();

      debugPrint("📥 GET URL => $baseUrl$endpoint");

      final response = await http
          .get(Uri.parse("$baseUrl$endpoint"), headers: await _headers())
          .timeout(timeout);

      debugPrint("✅ STATUS => ${response.statusCode}");
      debugPrint("✅ RESPONSE => ${response.body}");

      if (response.statusCode == 401) {
        await forceLogout(context);
        return null;
      }

      return response;
    } on TimeoutException {
      debugPrint("⏱ API TIMEOUT: $endpoint");
      return null;
    } catch (e) {
      debugPrint("🚨 GET ERROR: $e");
      return null;
    }
  }

  // ================= POST =================

  static Future<http.Response?> post(
    BuildContext context,
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final token = await _getToken();

    if (token.isEmpty) {
      await forceLogout(context);
      return null;
    }

    try {
      final baseUrl = await getBaseUrl();

      debugPrint("📤 AUTH POST URL => $baseUrl$endpoint");
      debugPrint("📤 BODY => ${jsonEncode(body ?? {})}");

      final response = await http
          .post(
            Uri.parse("$baseUrl$endpoint"),
            headers: await _headers(),
            body: jsonEncode(body ?? {}),
          )
          .timeout(timeout);

      debugPrint("✅ STATUS => ${response.statusCode}");
      debugPrint("✅ RESPONSE => ${response.body}");

      if (response.statusCode == 401) {
        await forceLogout(context);
        return null;
      }

      return response;
    } on TimeoutException {
      debugPrint("⏱ API TIMEOUT: $endpoint");
      return null;
    } catch (e) {
      debugPrint("🚨 POST ERROR: $e");
      return null;
    }
  }

  static Future<String> getImageBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final tenantId = prefs.getString("tenant_id") ?? "";

    if (tenantId.isEmpty) {
      return "https://edusathi.in";
    }

    return "https://$tenantId.edusathi.in";
  }

  // ================= SAVE SESSIONS =================
  static Future<void> saveSession(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();

    // 🔐 TOKEN
    final String token = data['token'] ?? '';
    await _secureStorage.write(key: 'auth_token', value: token);
    await prefs.setString('auth_token', token);
    await prefs.setBool('is_logged_in', true);

    // 👤 USER TYPE
    final String userType = (data['user_type'] ?? '').toString();
    await prefs.setString('user_type', userType);

    // 👤 PROFILE
    final Map<String, dynamic> profile = Map<String, dynamic>.from(
      data['profile'] ?? {},
    );

    // ================= ADMIN =================
    if (userType.toLowerCase() == 'admin') {
      await prefs.setString('admin_name', profile['name'] ?? '');
      await prefs.setString('school_name', profile['school'] ?? '');
      await prefs.setString('admin_photo', profile['photo'] ?? '');

      debugPrint("🛡 ADMIN LOGIN SAVED");
      debugPrint("Name: ${profile['name']}");
      debugPrint("School: ${profile['school']}");
      debugPrint("Photo: ${profile['photo']}");
    }
    // ================= TEACHER =================
    else if (userType.toLowerCase() == 'teacher') {
      await prefs.setString('teacher_name', profile['name'] ?? '');
      await prefs.setString('teacher_class', profile['class'] ?? '');
      await prefs.setString('teacher_section', profile['section'] ?? '');
      await prefs.setString('school_name', profile['school'] ?? '');
      await prefs.setString('teacher_photo', profile['photo'] ?? '');

      debugPrint("👨‍🏫 TEACHER LOGIN SAVED");
    }
    // ================= STUDENT =================
    else if (userType.toLowerCase() == 'student') {
      await prefs.setString('student_name', profile['student_name'] ?? '');
      await prefs.setString('class_name', profile['class_name'] ?? '');
      await prefs.setString('section', profile['section'] ?? '');
      await prefs.setString('school_name', profile['school_name'] ?? '');
      await prefs.setString('student_photo', profile['student_photo'] ?? '');

      debugPrint("🎓 STUDENT LOGIN SAVED");
    }
  }

  // ================= ATTACHMENTS =================
  static const siblingUrl = 'https://school.edusathi.in/uploads/no_image.png';
}

class AppColors {
  static const primary = Colors.deepPurple;
  static const success = Colors.green;
  static const danger = Colors.red;
  static const info = Colors.blue;
  static const designerColor = Colors.orange;
  static const LinearGradient appBarGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xff5B5FEF), Color(0xff7C4DFF), Color(0xffA855F7)],
  );
}

class AppAssets {
  static const defaultAvatar = 'assets/images/default_avatar.png';
  static const logo = 'assets/images/logo.png';
  static const logo_new = 'assets/images/logo_new.png';

  static const schoolName = "Edusathi School";
  static const schoolDescription =
      "Empowering Education, Simplifying Management.";

  static const websiteName = "www.techinnovationapp.in";
  static const companyWebsite = "https://www.techinnovationapp.in";
}
