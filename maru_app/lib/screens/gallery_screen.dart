// lib/screens/gallery_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import '../providers/work_provider.dart';
import '../models/app_models.dart';

class PhotoItem {
  final WorkRecord record;
  final String path;
  final int index;
  PhotoItem({required this.record, required this.path, required this.index});
}

class GalleryScreen extends ConsumerWidget {
  const GalleryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(workProvider);
    
    // 🌟 다중 사진 분리 로직 탑재
    List<PhotoItem> allPhotos = [];
    for (var r in records) {
      if (r.photoPaths != null && r.photoPaths!.isNotEmpty) {
        for (int i = 0; i < r.photoPaths!.length; i++) { allPhotos.add(PhotoItem(record: r, path: r.photoPaths![i], index: i)); }
      } else if (r.photoPath != null && r.photoPath!.isNotEmpty) {
        allPhotos.add(PhotoItem(record: r, path: r.photoPath!, index: -1));
      }
    }
    allPhotos.sort((a, b) => b.record.date.compareTo(a.record.date));

    return Scaffold(
      appBar: AppBar(title: const Text('현장 전체 사진첩', style: TextStyle(fontWeight: FontWeight.bold))),
      body: allPhotos.isEmpty
          ? const Center(child: Text('저장된 현장 사진이 없습니다.', style: TextStyle(color: Colors.grey)))
          : GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
              itemCount: allPhotos.length,
              itemBuilder: (context, index) {
                final item = allPhotos[index];
                return GestureDetector(
                  onTap: () => _showPhotoDetail(context, item.record, item.path),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(File(item.path), fit: BoxFit.cover),
                        Positioned(bottom: 0, left: 0, right: 0, child: Container(color: Colors.black54, padding: const EdgeInsets.symmetric(vertical: 4), alignment: Alignment.center, child: Text(DateFormat('MM/dd').format(item.record.date), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)))),
                        Positioned(top: 4, right: 4, child: GestureDetector(
                          onTap: () {
                            Get.defaultDialog(
                              title: '사진 삭제', middleText: '사진을 삭제하시겠습니까?\n(공수 기록은 유지됩니다)', textConfirm: '삭제', textCancel: '취소', confirmTextColor: Colors.white, buttonColor: Colors.redAccent, cancelTextColor: Colors.black,
                              onConfirm: () async {
                                if (item.index == -1) item.record.photoPath = null;
                                else item.record.photoPaths!.removeAt(item.index);
                                await ref.read(workProvider.notifier).updateRecord(item.record);
                                Get.back();
                              }
                            );
                          },
                          child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: const Icon(Icons.delete_outline, color: Colors.white, size: 16)),
                        ))
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  void _showPhotoDetail(BuildContext context, WorkRecord record, String currentPath) {
    Get.dialog(
      Dialog(
        backgroundColor: Colors.transparent,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(borderRadius: BorderRadius.circular(15), child: Image.file(File(currentPath))),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(15)),
                  child: Column(
                    children: [
                      Text(DateFormat('yyyy년 MM월 dd일').format(record.date), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)), const SizedBox(height: 8),
                      Text('${record.siteName} | ${record.workHours}공수', style: const TextStyle(color: Color(0xFF5A55F5), fontWeight: FontWeight.bold)),
                      if (record.memo != null && record.memo!.isNotEmpty) ...[const Divider(), Text(record.memo!)]
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 30), onPressed: () => Get.back()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}