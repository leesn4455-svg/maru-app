// lib/screens/memo_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';

import '../theme/app_theme.dart';
// 분리된 파일들을 불러옵니다!
import 'memo_detail_screen.dart';
import 'memo_edit_screen.dart';

class MemoScreen extends StatefulWidget {
  const MemoScreen({super.key});

  @override
  State<MemoScreen> createState() => _MemoScreenState();
}

class _MemoScreenState extends State<MemoScreen> {
  final _box = Hive.box('preferences');
  List<Map<String, dynamic>> _memos = [];

  @override
  void initState() {
    super.initState();
    _loadMemos();
  }

  void _loadMemos() {
    final stored = _box.get('quick_memos', defaultValue: []);
    _memos = List<Map<String, dynamic>>.from(stored.map((e) => Map<String, dynamic>.from(e)));
    _memos.sort((a, b) => DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])));
    setState(() {});
  }

  void _deleteMemo(String id) {
    Get.defaultDialog(
      title: '삭제', middleText: '이 메모를 삭제하시겠습니까?', textConfirm: '삭제', textCancel: '취소',
      confirmTextColor: Colors.white, buttonColor: Colors.redAccent, cancelTextColor: Colors.black,
      onConfirm: () {
        List<dynamic> raw = _box.get('quick_memos', defaultValue: []);
        List<Map<String, dynamic>> allMemos = raw.map((e) => Map<String, dynamic>.from(e)).toList();
        allMemos.removeWhere((m) => m['id'] == id);
        _box.put('quick_memos', allMemos);
        _loadMemos();
        Get.back();
      }
    );
  }

  void _showPhotoDetail(String path) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          fit: StackFit.expand,
          children: [
            InteractiveViewer(child: Image.file(File(path), fit: BoxFit.contain)),
            Positioned(top: 40, right: 20, child: IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 30), onPressed: () => Get.back())),
          ],
        ),
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('퀵 메모장', style: TextStyle(fontWeight: FontWeight.bold)), centerTitle: true),
      body: _memos.isEmpty
          ? const Center(child: Text('작성된 메모가 없습니다.\n우측 하단 버튼을 눌러 추가해보세요.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.all(12), itemCount: _memos.length,
              itemBuilder: (context, index) {
                final memo = _memos[index];
                final photos = List<String>.from(memo['photos'] ?? []);
                
                String title = memo['title'] ?? '';
                if (title.isEmpty) {
                  title = memo['content']?.toString().split('\n').first ?? '제목 없음';
                  if (title.length > 20) title = '${title.substring(0, 20)}...';
                }

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(15),
                    onTap: () {
                      Get.to(() => MemoDetailScreen(memo: memo))?.then((_) => _loadMemos());
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text(memo['content'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, color: Colors.black54)),
                          const SizedBox(height: 12),
                          
                          if (photos.isNotEmpty) ...[
                            Wrap(
                              spacing: 8,
                              children: photos.take(4).map((p) => GestureDetector(
                                onTap: () => _showPhotoDetail(p),
                                child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(p), width: 50, height: 50, fit: BoxFit.cover)),
                              )).toList()
                            ),
                            const SizedBox(height: 12),
                          ],
                          
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(DateFormat('yyyy년 MM월 dd일 a h:mm', 'ko_KR').format(DateTime.parse(memo['date'])), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              IconButton(
                                constraints: const BoxConstraints(), padding: EdgeInsets.zero,
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20), 
                                onPressed: () => _deleteMemo(memo['id'])
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.primaryColor,
        onPressed: () => Get.to(() => const MemoEditScreen())?.then((_) => _loadMemos()),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}