import 'package:student_app/leave/list_leaveApproval.dart';
import 'package:student_app/teacher/roll_no.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:student_app/api_service.dart';
import 'package:student_app/login_page.dart';
import 'package:student_app/alert/stu_alert.dart';
import 'package:student_app/connect_teacher/teacher_chat_list.dart';
import 'package:student_app/payment/payment_teacher_screen.dart';
import 'package:student_app/school_info_page.dart';
import 'package:student_app/syllabus/syllabus.dart';
import 'package:student_app/teacher/AssignMarksPage.dart';
import 'package:student_app/teacher/AssignSkillsPage.dart';
import 'package:student_app/teacher/ResultcardPage.dart';
import 'package:student_app/Attendance_UI/mark_attendance_page.dart';
import 'package:student_app/teacher/complaint_teacher/teacher_complaint_list_page.dart';
import 'package:student_app/Attendance_UI/teacher_attendance_screen.dart';
import 'package:student_app/teacher/teacher_dashboard_screen.dart';
import 'package:student_app/teacher/teacher_homework_page.dart';
import 'package:student_app/teacher/teacher_profile_page.dart';
import 'package:student_app/Attendance_UI/attendance_screen.dart';
import 'package:student_app/teacher/teacher_timetable.dart';
import 'package:student_app/Exam/exam_schedule.dart';

class TeacherSidebarMenu extends StatefulWidget {
  const TeacherSidebarMenu({super.key});

  @override
  State<TeacherSidebarMenu> createState() => _TeacherSidebarMenuState();
}

class _TeacherSidebarMenuState extends State<TeacherSidebarMenu> {
  String teacherName = '';
  String teacherPhoto = '';
  String teacherClass = '';
  String teacherSection = '';

  @override
  void initState() {
    super.initState();
    loadTeacherInfo();
  }

  Future<void> loadTeacherInfo() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      teacherName = prefs.getString('teacher_name') ?? '';
      teacherPhoto = prefs.getString('teacher_photo') ?? '';
      teacherClass = prefs.getString('teacher_class') ?? '';
      teacherSection = prefs.getString('teacher_section') ?? '';
    });
  }

  String getPhotoUrl(String photo) {
    return photo.trim();
  }

  void _navigate(BuildContext context, Widget page) {
    Navigator.pop(context); // ✅ close drawer
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ?? '';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      if (token.isNotEmpty) {

        final String baseUrl = await ApiService.getBaseUrl();

        final response = await http.post(
          Uri.parse('$baseUrl/logout'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        );

        debugPrint("🚪 LOGOUT STATUS: ${response.statusCode}");
        debugPrint("🚪 LOGOUT BODY: ${response.body}");
      }
    } catch (e) {
      debugPrint("❌ Logout API Error: $e");
    }
    await prefs.remove('auth_token');
    await prefs.remove('is_logged_in');

    await prefs.remove('teacher_name');
    await prefs.remove('teacher_photo');
    await prefs.remove('teacher_class');

    await _secureStorage.deleteAll();

    if (!context.mounted) return;

    Navigator.pop(context);

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: [
          Container(
            color: AppColors.primary,
            height: 130,
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundImage: teacherPhoto.isNotEmpty
                      ? NetworkImage(getPhotoUrl(teacherPhoto))
                      : const AssetImage('assets/images/logo.png')
                            as ImageProvider,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        teacherName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text(
                        'Class Teacher',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      Text(
                        '$teacherClass - $teacherSection',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          sidebarItem(
            context,
            Icons.dashboard,
            'Dashboard',
            () => _navigate(context, const TeacherDashboardScreen()),
          ),
          sidebarItem(
            context,
            Icons.format_list_numbered,
            'Update Roll no',
            () => _navigate(context, const UpdateRollNoPage()),
          ),

          sidebarItem(
            context,
            Icons.leave_bags_at_home_rounded,
            'Approve Leave',
            () => _navigate(context, const LeaveApprovalListPage()),
          ),
          sidebarItem(
            context,
            Icons.person,
            'Profile',
            () => _navigate(context, const TeacherProfilePage()),
          ),
          sidebarItem(
            context,
            Icons.playlist_add_check_circle,
            'Mark Attendance',
            () => _navigate(context, MarkAttendancePage()),
          ),
          sidebarItem(
            context,
            Icons.add_chart,
            'Attendance Report',
            () => _navigate(context, const AttendanceScreen()),
          ),
          sidebarItem(
            context,
            Icons.book,
            'Homeworks',
            () => _navigate(context, const TeacherHomeworkPage()),
          ),
          sidebarItem(
            context,
            Icons.add_alert,
            'Student Alert',
            () => _navigate(context, StudentAlertPage()),
          ),
          sidebarItem(
            context,
            Icons.assignment,
            'Assign Marks',
            () => _navigate(context, const AssignMarksPage()),
          ),
          sidebarItem(
            context,
            Icons.book_sharp,
            'Syllabus',
            () => _navigate(context, const SyllabusPage()),
          ),
          sidebarItem(
            context,
            Icons.receipt,
            'Exam Schedule',
            () => _navigate(context, const ExamSchedulePage()),
          ),
          sidebarItem(
            context,
            Icons.star,
            'Assign Skills',
            () => _navigate(context, const AssignSkillsPage()),
          ),
          sidebarItem(
            context,
            Icons.list_alt,
            'Result',
            () => _navigate(context, const ResultCardPage()),
          ),
          sidebarItem(
            context,
            Icons.schedule,
            'Timetable',
            () => _navigate(context, const TeacherTimeTablePage()),
          ),
          sidebarItem(
            context,
            Icons.report,
            'Complaint',
            () => _navigate(context, const TeacherComplaintListPage()),
          ),
          sidebarItem(
            context,
            Icons.payment,
            'Payments',
            () => _navigate(context, const PaymentTeacherScreen()),
          ),
          sidebarItem(
            context,
            Icons.calendar_month,
            'My Attendance',
            () => _navigate(context, const TeacherAttendanceScreen()),
          ),
          sidebarItem(
            context,
            Icons.school,
            'School Info',
            () => _navigate(context, SchoolInfoPage()),
          ),
          sidebarItem(
            context,
            Icons.message,
            'Chat With Students',
            () => _navigate(context, const TeacherChatStudentListPage()),
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Logout"),
                  content: const Text("Are you sure you want to logout?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _logout(context);
                      },
                      child: const Text("Logout"),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  ListTile sidebarItem(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      visualDensity: const VisualDensity(vertical: -3),
      onTap: onTap,
    );
  }
}
