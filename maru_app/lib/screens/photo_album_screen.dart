// lib/screens/photo_album_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import '../providers/work_provider.dart';
import '../models/app_models.dart';

// 🌟 다중 사진을 다루기 위한 보조 상자
class PhotoItem {
  final WorkRecord record;
  final String path;
  final int index; // -1: 단일 사진, 0~N: 다중 사진 인덱스
  PhotoItem({required this.record, required this.path, required this.index});
}

class PhotoAlbumScreen extends ConsumerStatefulWidget {
  const PhotoAlbumScreen({super.key});

  @override
  ConsumerState<PhotoAlbumScreen> createState() => _PhotoAlbumScreenState();
}

class _PhotoAlbumScreenState extends ConsumerState<PhotoAlbumScreen> {
  String? _selectedSiteFolder;
  DateTime? _filterMonth; // 🌟 날짜 검색용 필터

  // 🌟 [해결 1] 하나의 공수에 등록된 N개의 사진을 모두 낱개로 분리해서 가져오는 마법의 함수
  List<PhotoItem> _extractAllPhotos(List<WorkRecord> records) {
    List<PhotoItem> allPhotos = [];
    for (var r in records) {
      if (r.photoPaths != null && r.photoPaths!.isNotEmpty) {
        for (int i = 0; i < r.photoPaths!.length; i++) {
          allPhotos.add(PhotoItem(record: r, path: r.photoPaths![i], index: i));
        }
      } else if (r.photoPath != null && r.photoPath!.isNotEmpty) {
        allPhotos.add(PhotoItem(record: r, path: r.photoPath!, index: -1));
      }
    }
    allPhotos.sort((a, b) => b.record.date.compareTo(a.record.date)); // 최신순
    return allPhotos;
  }

  void _showMonthPicker() {
    DateTime tempDate = _filterMonth ?? DateTime.now();
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 300, color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          children: [
            Container(decoration: BoxDecoration(color: Theme.of(context).cardColor), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [CupertinoButton(child: const Text('필터 해제', style: TextStyle(color: Colors.red)), onPressed: () { setState(() { _filterMonth = null; _selectedSiteFolder = null; }); Get.back(); }), CupertinoButton(child: const Text('확인', style: TextStyle(fontWeight: FontWeight.bold)), onPressed: () { setState(() { _filterMonth = tempDate; _selectedSiteFolder = null; }); Get.back(); })])),
            Expanded(child: SafeArea(top: false, child: CupertinoDatePicker(mode: CupertinoDatePickerMode.monthYear, initialDateTime: tempDate, onDateTimeChanged: (val) => tempDate = val))),
          ],
        ),
      ),
    );
  }

  void _deletePhoto(PhotoItem item) {
    Get.defaultDialog(
      title: '사진 삭제', middleText: '이 사진을 기록에서 삭제하시겠습니까?', textConfirm: '삭제', textCancel: '취소',
      confirmTextColor: Colors.white, buttonColor: Colors.redAccent, cancelTextColor: Colors.black,
      onConfirm: () async {
        if (item.index == -1) item.record.photoPath = null;
        else item.record.photoPaths!.removeAt(item.index);
        await ref.read(workProvider.notifier).updateRecord(item.record);
        Get.back();
        Get.snackbar('삭제 완료', '사진이 삭제되었습니다.');
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    final workRecords = ref.watch(workProvider);
    List<PhotoItem> allPhotos = _extractAllPhotos(workRecords);

    // 날짜 필터가 적용되었다면 해당 달의 사진만 추림
    if (_filterMonth != null) {
      allPhotos = allPhotos.where((p) => p.record.date.year == _filterMonth!.year && p.record.date.month == _filterMonth!.month).toList();
    }

    return Scaffold(
      appBar: AppBar(
        leading: _selectedSiteFolder != null ? IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => setState(() => _selectedSiteFolder = null)) : null,
        title: Text(_selectedSiteFolder ?? (_filterMonth != null ? DateFormat('yyyy년 MM월 사진').format(_filterMonth!) : '현장별 사진첩'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), 
        centerTitle: true,
        actions: [
          // 🌟 [해결 2] 달력 아이콘을 눌러 저장된 월별로 쉽게 찾기!
          IconButton(icon: const Icon(Icons.calendar_month, color: Color(0xFF5A55F5)), onPressed: _showMonthPicker),
          const SizedBox(width: 8)
        ],
      ),
      body: allPhotos.isEmpty
        ? Center(child: Text(_filterMonth != null ? '해당 월에 등록된 사진이 없습니다.' : '첨부된 현장 사진이 없습니다.', style: const TextStyle(color: Colors.grey)))
        : _buildBody(allPhotos),
    );
  }

  Widget _buildBody(List<PhotoItem> allPhotos) {
    // 필터 모드이거나, 특정 폴더 안에 들어왔을 때는 전체 사진 리스트를 격자로 보여줌
    if (_filterMonth != null || _selectedSiteFolder != null) {
      List<PhotoItem> displayPhotos = _selectedSiteFolder != null ? allPhotos.where((p) => p.record.siteName == _selectedSiteFolder).toList() : allPhotos;
      if (displayPhotos.isEmpty && _selectedSiteFolder != null) {
        Future.microtask(() => setState(() => _selectedSiteFolder = null)); // 지워서 비면 폴더 닫기
        return const SizedBox();
      }

      return GridView.builder(
        padding: const EdgeInsets.all(8.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 4.0, mainAxisSpacing: 4.0),
        itemCount: displayPhotos.length,
        itemBuilder: (context, index) {
          final item = displayPhotos[index];
          return Stack(
            fit: StackFit.expand,
            children: [
              GestureDetector(
                onTap: () {
                  Get.dialog(Dialog(backgroundColor: Colors.transparent, insetPadding: EdgeInsets.zero, child: Stack(fit: StackFit.expand, children: [InteractiveViewer(child: Image.file(File(item.path), fit: BoxFit.contain)), Positioned(top: 40, right: 20, child: IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 30), onPressed: () => Get.back())), Positioned(bottom: 40, left: 0, right: 0, child: Text('${DateFormat('yyyy년 MM월 dd일').format(item.record.date)} | ${item.record.siteName}', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, shadows: [Shadow(color: Colors.black, blurRadius: 4)])))])));
                },
                child: ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(File(item.path), fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: Colors.grey, child: const Icon(Icons.broken_image)))),
              ),
              Positioned(bottom: 0, left: 0, right: 0, child: Container(color: Colors.black54, padding: const EdgeInsets.symmetric(vertical: 2), child: Text(DateFormat('MM/dd').format(item.record.date), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center))),
              Positioned(top: 4, right: 4, child: GestureDetector(onTap: () => _deletePhoto(item), child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: const Icon(Icons.delete_outline, color: Colors.white, size: 16))))
            ],
          );
        },
      );
    } 
    // 기본 모드: 현장명으로 묶인 '폴더' 화면
    else {
      final Map<String, List<PhotoItem>> groupedBySite = {};
      for (var p in allPhotos) { groupedBySite.putIfAbsent(p.record.siteName, () => []).add(p); }

      return GridView.builder(
        padding: const EdgeInsets.all(16.0),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 16.0, mainAxisSpacing: 16.0),
        itemCount: groupedBySite.length,
        itemBuilder: (context, index) {
          final siteName = groupedBySite.keys.elementAt(index);
          final photos = groupedBySite[siteName]!;
          final latestPhoto = photos.first.path;

          return GestureDetector(
            onTap: () => setState(() => _selectedSiteFolder = siteName),
            child: Container(
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)], image: DecorationImage(image: FileImage(File(latestPhoto)), fit: BoxFit.cover)),
              child: Container(
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), color: Colors.black.withOpacity(0.5)),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.folder, color: Colors.white, size: 40), const SizedBox(height: 8),
                    Text(siteName.isEmpty ? '미지정 현장' : siteName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text('${photos.length}장', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }
  }
}