import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:student_app/auth_helper.dart';
import 'package:student_app/complaint/complaint_detail_page.dart';
import 'package:student_app/dashboard/dashboard_screen.dart';
import 'package:student_app/Attendance_UI/stu_attendance_page.dart';
import 'package:student_app/homework/homework_detail_page.dart';

class NotificationListPage extends StatefulWidget {
  const NotificationListPage({super.key});

  @override
  State<NotificationListPage> createState() => _NotificationListPageState();
}

class _NotificationListPageState extends State<NotificationListPage> {
  List<dynamic> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    try {
      final response = await AuthHelper.post(
        context,
        "https://school.edusathi.in/api/student/notifications",
      );

     
      if (response == null) return;

      if (!mounted) return;

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        setState(() {
          notifications = decoded['data'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  void handleNotificationTap(Map<String, dynamic> item) {
    final type = item['type'] ?? '';
    final id = item['id'];

    switch (type) {
      case 'homework':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => HomeworkDetailPage(homework: item)),
        );
        break;

      case 'attendance':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AttendanceAnalyticsPage()),
        );
        break;

      case 'complaint':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ComplaintDetailPage(
              complaintId: id,
              date: item['date'] ?? '',
              description: item['description'] ?? '',
              status: item['status'] ?? 0,
            ),
          ),
        );
        break;

      case 'notice':
      case 'event':
      case 'student alert':
      case 'due reminder':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => DashboardScreen()),
        );
        break;

      default:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No screen mapped for type: $type")),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text(
          "Notifications",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : notifications.isEmpty
          ? const Center(child: Text("No notifications available"))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final item = notifications[index];
                final type = item['type'] ?? '';

                final title = type == "homework"
                    ? item['HomeworkTitle'] ?? item['title'] ?? "Homework"
                    : item['title'] ?? "Notification";

                final description = type == "homework"
                    ? item['Remark'] ?? item['description'] ?? ''
                    : item['description'] ?? '';

                return GestureDetector(
                  onTap: () => handleNotificationTap(item),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: type == "homework"
                              ? Colors.pink.shade50
                              : type == "attendance"
                              ? Colors.blue.shade50
                              : Colors.orange.shade50,
                          child: Icon(
                            type == "homework"
                                ? Icons.menu_book_rounded
                                : type == "attendance"
                                ? Icons.check_circle_outline
                                : Icons.notifications_active_outlined,
                            color: type == "homework"
                                ? Colors.pink
                                : type == "attendance"
                                ? Colors.blue
                                : Colors.orange,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                description,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    item['date'] ?? '',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                  const SizedBox(width: 10),
                                  const Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    item['time'] ?? '',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
