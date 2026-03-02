// lib/screens/memo_edit_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_theme.dart';

class MemoEditScreen extends StatefulWidget {
  final Map<String, dynamic>? memo;
  const MemoEditScreen({super.key, this.memo});

  @override
  State<MemoEditScreen> createState() => _MemoEditScreenState();
}

class _MemoEditScreenState extends State<MemoEditScreen> {
  late TextEditingController _titleCtrl;
  late TextEditingController _contentCtrl;
  List<String> _selectedPhotos = [];

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.memo?['title'] ?? '');
    _contentCtrl = TextEditingController(text: widget.memo?['content'] ?? '');
    if (widget.memo != null) {
      _selectedPhotos = List<String>.from(widget.memo!['photos'] ?? []);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  void _saveMemo() {
    FocusScope.of(context).unfocus(); 
    
    String title = _titleCtrl.text.trim();
    String content = _contentCtrl.text.trim();

    if (content.isEmpty && _selectedPhotos.isEmpty) {
      Get.snackbar('알림', '내용이나 사진을 추가해주세요.');
      return;
    }

    if (title.isEmpty) {
      title = content.split('\n').first;
      if (title.length > 20) title = '${title.substring(0, 20)}...';
      if (title.isEmpty) title = '새 메모';
    }

    final box = Hive.box('preferences');
    List<dynamic> raw = box.get('quick_memos', defaultValue: []);
    List<Map<String, dynamic>> allMemos = raw.map((e) => Map<String, dynamic>.from(e)).toList();

    if (widget.memo == null) {
      allMemos.add({
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'title': title,
        'content': content,
        'date': DateTime.now().toIso8601String(),
        'photos': _selectedPhotos,
      });
    } else {
      int targetIndex = allMemos.indexWhere((m) => m['id'] == widget.memo!['id']);
      if (targetIndex != -1) {
        allMemos[targetIndex]['title'] = title;
        allMemos[targetIndex]['content'] = content;
        allMemos[targetIndex]['date'] = DateTime.now().toIso8601String();
        allMemos[targetIndex]['photos'] = _selectedPhotos;
      }
    }

    box.put('quick_memos', allMemos);
    Get.back(result: true); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.memo == null ? '새 메모 작성' : '메모 수정', style: const TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: AppTheme.primaryColor, size: 28),
            onPressed: _saveMemo,
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _titleCtrl,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(hintText: '제목 (입력하지 않으면 내용 첫 줄 자동 지정)', border: InputBorder.none),
                    ),
                    const Divider(),
                    TextField(
                      controller: _contentCtrl,
                      style: const TextStyle(fontSize: 16, height: 1.5),
                      maxLines: null,
                      minLines: 10,
                      decoration: const InputDecoration(hintText: '메모 내용을 입력하세요...', border: InputBorder.none),
                    ),
                  ],
                ),
              ),
            ),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -3))]),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () async { 
                      try {
                        final images = await ImagePicker().pickMultiImage(); 
                        if (images.isNotEmpty) setState(() => _selectedPhotos.addAll(images.map((e) => e.path))); 
                      } catch (e) {
                        Get.snackbar('오류', '사진첩 접근 권한을 확인해주세요.');
                      }
                    },
                    child: Container(width: 60, height: 60, decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.grey)), child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo, size: 20, color: Colors.grey), SizedBox(height: 2), Text('사진 추가', style: TextStyle(fontSize: 9, color: Colors.grey))])),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 60,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedPhotos.length,
                        itemBuilder: (context, i) {
                          return Container(
                            width: 60, margin: const EdgeInsets.only(right: 10),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(File(_selectedPhotos[i]), fit: BoxFit.cover)),
                                Positioned(top: 2, right: 2, child: GestureDetector(onTap: () => setState(() => _selectedPhotos.removeAt(i)), child: Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: const Icon(Icons.close, size: 12, color: Colors.white)))),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    onPressed: _saveMemo,
                    child: const Text('저장', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}