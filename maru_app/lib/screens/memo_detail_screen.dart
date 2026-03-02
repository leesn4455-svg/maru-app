// lib/screens/memo_detail_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';

import '../theme/app_theme.dart';
import 'memo_edit_screen.dart';

class MemoDetailScreen extends StatelessWidget {
  final Map<String, dynamic> memo;
  const MemoDetailScreen({super.key, required this.memo});

  void _showPhotoDetail(String path) {
    Get.dialog(Dialog(
      backgroundColor: Colors.transparent, 
      insetPadding: EdgeInsets.zero, 
      child: Stack(
        fit: StackFit.expand, 
        children: [
          InteractiveViewer(child: Image.file(File(path), fit: BoxFit.contain)), 
          Positioned(top: 40, right: 20, child: IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 30), onPressed: () => Get.back()))
        ]
      )
    ));
  }

  @override
  Widget build(BuildContext context) {
    final photos = List<String>.from(memo['photos'] ?? []);
    String title = memo['title'] ?? '';
    if (title.isEmpty) {
      title = memo['content']?.toString().split('\n').first ?? '제목 없음';
      if (title.length > 20) title = '${title.substring(0, 20)}...';
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('메모 보기', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: () {
              // 현재 화면(읽기)을 지우고 수정 화면으로 이동합니다.
              Get.off(() => MemoEditScreen(memo: memo)); 
            }, 
            child: const Text('수정', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 16))
          ),
          const SizedBox(width: 8)
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(DateFormat('yyyy. MM. dd a h:mm', 'ko_KR').format(DateTime.parse(memo['date'])), style: const TextStyle(color: Colors.grey)),
            const Divider(height: 30),
            
            Text(memo['content'] ?? '', style: const TextStyle(fontSize: 16, height: 1.5)),
            const SizedBox(height: 30),

            if (photos.isNotEmpty) ...[
              const Text('첨부 사진', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10, runSpacing: 10,
                children: photos.map((p) => GestureDetector(
                  onTap: () => _showPhotoDetail(p),
                  child: ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(File(p), width: 100, height: 100, fit: BoxFit.cover)),
                )).toList()
              )
            ]
          ],
        ),
      ),
    );
  }
}