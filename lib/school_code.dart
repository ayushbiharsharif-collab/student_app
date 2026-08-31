import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_app/api_service.dart';
import 'package:student_app/login_page.dart';

class SchoolCodePage extends StatefulWidget {
  const SchoolCodePage({super.key});

  @override
  State<SchoolCodePage> createState() => _SchoolCodePageState();
}

class _SchoolCodePageState extends State<SchoolCodePage> {
  final TextEditingController codeController = TextEditingController();

  bool isLoading = false;

  Future<void> checkSchoolCode() async {
    try {
      setState(() => isLoading = true);

      final code = codeController.text.trim();

      debugPrint("📌 School App Code Entered: $code");
      final response = await http.get(
        Uri.parse("${ApiService.MasterApi}/check-school-code?sin=$code"),
      );

      debugPrint("📌 Status Code: ${response.statusCode}");
      debugPrint("📌 Raw Response: ${response.body}");

      final data = jsonDecode(response.body);

      debugPrint("📌 Decoded Response: $data");

      if (data["status"] == "success") {
        final tenantId = data["tenant_id"];
        final schoolName = data["school_name"];

        debugPrint("✅ Tenant ID: $tenantId");
        debugPrint("✅ School Name: $schoolName");

        final prefs = await SharedPreferences.getInstance();

        await prefs.setString("tenant_id", tenantId);
        await prefs.setString("school_name", schoolName);



        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => LoginPage()),
        );
      } else {
        debugPrint("❌ Invalid School App Code");

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Invalid School App Code")),
        );
      }
    } catch (e) {
      debugPrint("🚨 ERROR: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F7FC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(.06),
                    blurRadius: 25,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 72,
                    width: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(.1),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      size: 38,
                      color: AppColors.primary,
                    ),
                  ),

                  const SizedBox(height: 18),

                  const Text(
                    "EduSathi",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: .3,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    "Enter your school App Code to continue",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),

                  const SizedBox(height: 28),

                  TextField(
                    controller: codeController,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => checkSchoolCode(),
                    decoration: InputDecoration(
                      hintText: "School App Code",
                      prefixIcon: const Icon(Icons.qr_code_rounded),
                      filled: true,
                      fillColor: const Color(0xffF7F9FC),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : checkSchoolCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              "Continue",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    "Powered by: TechInnovation App Pvt. Ltd.®",
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
