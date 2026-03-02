// lib/screens/work_log_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart'; // 🌟 [추가] 파일을 바로 열어주는 라이브러리
import 'package:hive_flutter/hive_flutter.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';

class WorkLogScreen extends StatefulWidget {
  const WorkLogScreen({super.key});

  @override
  State<WorkLogScreen> createState() => _WorkLogScreenState();
}

class _WorkLogScreenState extends State<WorkLogScreen> {
  final _box = Hive.box('preferences');
  List<Map<String, dynamic>> _savedFiles = [];

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  void _loadFiles() {
    final stored = _box.get('work_logs', defaultValue: []);
    _savedFiles = List<Map<String, dynamic>>.from(stored.map((e) => Map<String, dynamic>.from(e)));
    setState(() {});
  }

  Future<void> _addFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      String fileName = result.files.single.name;

      final directory = await getApplicationDocumentsDirectory();
      final savedPath = '${directory.path}/$fileName';
      await file.copy(savedPath);

      _savedFiles.add({
        'name': fileName,
        'path': savedPath,
        'date': DateTime.now().toIso8601String(),
      });
      _box.put('work_logs', _savedFiles);
      _loadFiles();
      Get.snackbar('저장 완료', '파일이 보관함에 추가되었습니다.', backgroundColor: Colors.green, colorText: Colors.white);
    }
  }

  // 🌟 [핵심 변경] 클릭 시 기기에 설치된 앱(갤러리, 엑셀 뷰어, 한글 등)으로 바로 엽니다!
  void _openFile(String path) async {
    if (File(path).existsSync()) {
      final result = await OpenFilex.open(path);
      if (result.type != ResultType.done) {
        Get.snackbar('열기 실패', '이 파일을 열 수 있는 앱(뷰어)이 기기에 없습니다.');
      }
    } else {
      Get.snackbar('오류', '파일을 찾을 수 없습니다.');
    }
  }

  // 공유 버튼을 눌렀을 때만 카톡 등으로 내보냅니다.
  void _shareFile(String path, String name) {
    if (File(path).existsSync()) {
      Share.shareXFiles([XFile(path)], text: '$name 파일 공유');
    } else {
      Get.snackbar('오류', '파일을 찾을 수 없습니다.');
    }
  }

  void _deleteFile(int index) {
    Get.defaultDialog(
      title: '파일 삭제', middleText: '이 양식을 보관함에서 삭제할까요?',
      textConfirm: '삭제', textCancel: '취소', confirmTextColor: Colors.white, buttonColor: Colors.redAccent, cancelTextColor: Colors.black,
      onConfirm: () {
        File file = File(_savedFiles[index]['path']);
        if (file.existsSync()) file.deleteSync(); 
        
        _savedFiles.removeAt(index);
        _box.put('work_logs', _savedFiles);
        _loadFiles();
        Get.back();
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('작업일지 양식 보관함', style: TextStyle(fontWeight: FontWeight.bold))),
      body: _savedFiles.isEmpty
          ? const Center(child: Text('저장된 양식이나 파일이 없습니다.\n우측 하단 + 버튼을 눌러 추가하세요.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _savedFiles.length,
              itemBuilder: (context, index) {
                final fileData = _savedFiles[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: const CircleAvatar(backgroundColor: Color(0xFFEEF0FF), child: Icon(Icons.insert_drive_file, color: AppTheme.primaryColor)),
                    title: Text(fileData['name'], style: const TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text('추가일: ${DateFormat('yyyy.MM.dd').format(DateTime.parse(fileData['date']))}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    // 🌟 클릭 시 파일 바로 열기 실행
                    onTap: () => _openFile(fileData['path']), 
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.share, color: Colors.blueAccent), onPressed: () => _shareFile(fileData['path'], fileData['name'])),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: () => _deleteFile(index)),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addFile,
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('파일 불러오기', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}