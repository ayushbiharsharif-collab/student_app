import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:student_app/api_service.dart';
import 'package:student_app/homework/homework_detail_page.dart';

class HomeworkPage extends StatefulWidget {
  const HomeworkPage({super.key});

  @override
  State<HomeworkPage> createState() => _HomeworkPageState();
}

class _HomeworkPageState extends State<HomeworkPage> {
  List<dynamic> homeworks = [];
  bool isLoading = true;
  bool _isDownloading = false;

  @override
  void initState() {
    super.initState();
    fetchHomework();
  }

  // =========================
  // 📡 FETCH HOMEWORK
  // =========================
  Future<void> fetchHomework() async {
    try {
      final response = await ApiService.post(context, '/student/homework');

      // 🔴 Token expired / auto logout
      if (response == null) {
        if (!mounted) return;
        setState(() => isLoading = false);
        return;
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (!mounted) return;
        setState(() {
          homeworks = data;
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load homework");
      }
    } catch (e) {
      debugPrint("❌ fetchHomework error: $e");

      if (!mounted) return;
      setState(() {
        isLoading = false;
        homeworks = [];
      });
    }
  }

  // =========================
  // 📅 DATE FORMAT
  // =========================
  String formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    try {
      return DateFormat('dd-MM-yyyy').format(DateTime.parse(dateStr));
    } catch (_) {
      return dateStr;
    }
  }

  // =========================
  // 📥 SAFE FILE DOWNLOAD
  // =========================
  Future<void> downloadFile(BuildContext context, String filePath) async {
    if (_isDownloading) return;
    _isDownloading = true;

    try {
      // Backend se already full URL aa raha hai
      final String fileUrl = filePath.trim();

      if (fileUrl.isEmpty) {
        debugPrint("❌ Attachment URL is empty");
        return;
      }

      debugPrint("📎 Attachment URL => $fileUrl");

      // Signed URL se proper filename nikalo
      final Uri uri = Uri.parse(fileUrl);

      String fileName = uri.pathSegments.isNotEmpty
          ? uri.pathSegments.last
          : "download_${DateTime.now().millisecondsSinceEpoch}";

      final dio = Dio();
      late String savePath;

      // ================= ANDROID =================
      if (Platform.isAndroid) {
        final downloadsDir = Directory('/storage/emulated/0/Download');

        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }

        savePath = '${downloadsDir.path}/$fileName';

        await dio.download(fileUrl, savePath);

        await OpenFile.open(savePath);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("📥 Downloaded & Preview opened")),
          );
        }
      }
      // ================= iOS =================
      else if (Platform.isIOS) {
        final dir = await getApplicationDocumentsDirectory();

        savePath = '${dir.path}/$fileName';

        await dio.download(fileUrl, savePath);

        await OpenFile.open(savePath);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("📥 Downloaded & Preview opened")),
          );
        }
      }
    } on DioException catch (e) {
      debugPrint("❌ Dio Error: ${e.message}");
      debugPrint("❌ Status Code: ${e.response?.statusCode}");
      debugPrint("❌ Response: ${e.response?.data}");

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("❌ ${e.message}")));
      }
    } catch (e) {
      debugPrint("❌ Error: $e");

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("❌ $e")));
      }
    } finally {
      _isDownloading = false;
    }
  }

  // =========================
  // 🧱 UI (UNCHANGED)
  // =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Homeworks', style: TextStyle(color: Colors.white)),
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.appBarGradient),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : homeworks.isEmpty
          ? const Center(child: Text("No homework available"))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: homeworks.length,
              itemBuilder: (context, index) {
                final hw = homeworks[index];
                final attachmentUrl = hw['Attachment'];

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => HomeworkDetailPage(homework: hw),
                      ),
                    );
                  },
                  child: Card(
                    elevation: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hw['HomeworkTitle'] ?? 'Untitled',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  "📅 ${formatDate(hw['WorkDate'])}",
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                              Flexible(
                                child: Text(
                                  "Submission: ${formatDate(hw['SubmissionDate'])}",
                                  style: const TextStyle(fontSize: 13),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          if ((hw['Remark'] ?? '').isNotEmpty)
                            Text(
                              "📝 ${(hw['Remark'] as String).length > 150 ? hw['Remark'].substring(0, 150) + '...' : hw['Remark']}",
                              style: const TextStyle(fontSize: 13),
                            ),
                          if (attachmentUrl != null)
                            Align(
                              alignment: Alignment.bottomRight,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.download_rounded,
                                  color: AppColors.primary,
                                ),
                                onPressed: () {
                                  downloadFile(context, attachmentUrl);
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
