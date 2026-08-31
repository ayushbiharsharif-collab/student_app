import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:student_app/api_service.dart';
import 'package:student_app/homework/homework_detail_page.dart';
import 'package:student_app/homework/homework_page.dart';

bool _isDownloading = false; // 🔒 download lock (logic only)

// ====================================================
// 📅 DATE FORMAT (SAFE)
// ====================================================
String formatDate(String? inputDate) {
  if (inputDate == null || inputDate.isEmpty) return '';
  try {
    return DateFormat('dd-MM-yyyy').format(DateTime.parse(inputDate));
  } catch (_) {
    return inputDate;
  }
}

// ====================================================
// 📥 SAFE FILE DOWNLOAD (iOS + Android)
// ====================================================
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

// ====================================================
// 📝 RECENT HOMEWORKS WIDGET (UI UNCHANGED)
// ====================================================
Widget buildRecentHomeworks(
  BuildContext context,
  List<Map<String, dynamic>> homeworks,
) {
  final limitedHomeworks = homeworks.take(3).toList();

  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(.06),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, Color(0xff4F8EF7)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),

            const SizedBox(width: 12),

            const Expanded(
              child: Text(
                "Recent Homeworks",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),

            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeworkPage()),
                );
              },
              child: const Text(
                "View All",
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 15),

        if (limitedHomeworks.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 30),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Column(
              children: [
                Icon(Icons.assignment_outlined, size: 45, color: Colors.grey),
                SizedBox(height: 10),
                Text(
                  "No Homeworks Available",
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: limitedHomeworks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final hw = limitedHomeworks[index];

              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HomeworkDetailPage(homework: hw),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      /// Icon
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.book_rounded,
                          color: AppColors.primary,
                        ),
                      ),

                      const SizedBox(width: 14),

                      /// Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              hw['HomeworkTitle'] ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),

                            const SizedBox(height: 6),

                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    "Submission : ${formatDate(hw['SubmissionDate'])}",
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            if ((hw['SubjectName'] ?? "").toString().isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    hw['SubjectName'],
                                    style: TextStyle(
                                      color: Colors.blue.shade800,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 10),

                      /// Download / Arrow
                      hw['Attachment'] != null &&
                              hw['Attachment'].toString().isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                downloadFile(context, hw['Attachment']);
                              },
                              icon: const Icon(
                                Icons.download_rounded,
                                color: AppColors.primary,
                              ),
                            )
                          : const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                              color: Colors.grey,
                            ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    ),
  );
}
