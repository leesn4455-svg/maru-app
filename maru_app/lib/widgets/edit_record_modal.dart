// lib/widgets/edit_record_modal.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart'; 
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get/get.dart';

import '../models/app_models.dart';
import '../providers/work_provider.dart';
import '../theme/app_theme.dart';
import '../utils/app_utils.dart';

class EditRecordModal extends ConsumerStatefulWidget {
  final WorkRecord record;
  const EditRecordModal({super.key, required this.record});
  @override
  ConsumerState<EditRecordModal> createState() => _EditRecordModalState();
}

class _EditRecordModalState extends ConsumerState<EditRecordModal> {
  late TextEditingController siteC; 
  late TextEditingController wageC; 
  late TextEditingController hoursC; 
  late TextEditingController memoC;
  
  // 🌟 여러 장 사진 관리 리스트
  List<String> selectedPhotos = []; 
  String? selectedWeather; 
  late bool isScheduleMode;

  @override
  void initState() {
    super.initState();
    siteC = TextEditingController(text: widget.record.siteName);
    wageC = TextEditingController(text: NumberFormat('#,###').format(widget.record.dailyWage));
    hoursC = TextEditingController(text: widget.record.workHours.toString());
    memoC = TextEditingController(text: widget.record.memo);
    selectedWeather = widget.record.weather; 
    isScheduleMode = widget.record.isSchedule;

    // 기존 데이터에서 사진 불러오기
    if (widget.record.photoPaths != null && widget.record.photoPaths!.isNotEmpty) {
      selectedPhotos = List<String>.from(widget.record.photoPaths!);
    } else if (widget.record.photoPath != null) {
      selectedPhotos = [widget.record.photoPath!];
    }
  }

  @override
  void dispose() { 
    siteC.dispose(); wageC.dispose(); hoursC.dispose(); memoC.dispose(); super.dispose(); 
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: CupertinoSlidingSegmentedControl<bool>(groupValue: isScheduleMode, children: const {false: Padding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8), child: Text('공수 (완료)')), true: Padding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8), child: Text('일정 (예정)'))}, onValueChanged: (val) => setState(() => isScheduleMode = val!))),
              const SizedBox(height: 20),
              Text(isScheduleMode ? '일정 수정' : '공수 수정', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(controller: siteC, decoration: InputDecoration(labelText: '현장명', prefixIcon: const Icon(Icons.business), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 15),
              Row(children: [Expanded(child: TextField(controller: hoursC, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: '공수', prefixIcon: const Icon(Icons.access_time), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))), const SizedBox(width: 15), Expanded(child: TextField(controller: wageC, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly, ThousandsFormatter()], decoration: InputDecoration(labelText: '단가', prefixIcon: const Icon(Icons.attach_money), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))) ]),
              const SizedBox(height: 8),
              Wrap(spacing: 10, alignment: WrapAlignment.center, children: [0.5, 1.0, 1.5, 2.0].map((e) => ActionChip(backgroundColor: const Color(0xFFEEF0FF), side: BorderSide.none, label: Text('$e공수', style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)), onPressed: () => setState(() => hoursC.text = e.toString()))).toList()),
              const SizedBox(height: 15),
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: ['☀️', '☁️', '🌧️', '❄️'].map((w) => GestureDetector(onTap: () => setState(() => selectedWeather = w), child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: selectedWeather == w ? AppTheme.primaryColor.withOpacity(0.2) : Colors.transparent, borderRadius: BorderRadius.circular(8)), child: Text(w, style: const TextStyle(fontSize: 24))))).toList()),
              const SizedBox(height: 15),
              TextField(controller: memoC, decoration: InputDecoration(labelText: '메모', prefixIcon: const Icon(Icons.note), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 20),
              
              // 🌟 [해결 2] 현장 사진 리스트 렌더링 및 개별 삭제 버튼 탑재
              const Text('현장 사진 (가로로 스와이프)', style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: selectedPhotos.length + 1,
                  itemBuilder: (context, index) {
                    if (index == selectedPhotos.length) {
                      return GestureDetector(
                        onTap: () async { 
                          final images = await ImagePicker().pickMultiImage(); 
                          if (images.isNotEmpty) setState(() => selectedPhotos.addAll(images.map((e) => e.path))); 
                        },
                        child: Container(width: 100, margin: const EdgeInsets.only(left: 8), decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey)), child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo, size: 30, color: Colors.grey), Text('추가', style: TextStyle(color: Colors.grey))])),
                      );
                    }
                    return Container(
                      width: 100, margin: const EdgeInsets.only(right: 10),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(selectedPhotos[index]), fit: BoxFit.cover)),
                          Positioned(
                            top: 4, right: 4, 
                            child: GestureDetector(
                              onTap: () => setState(() => selectedPhotos.removeAt(index)), 
                              child: Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: const Icon(Icons.close, size: 14, color: Colors.white))
                            )
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: isScheduleMode ? Colors.blueAccent : AppTheme.primaryColor, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                onPressed: () async {
                  if (siteC.text.isEmpty || wageC.text.isEmpty) return;
                  widget.record.siteName = siteC.text; 
                  widget.record.dailyWage = int.tryParse(wageC.text.replaceAll(',', '')) ?? 0; 
                  widget.record.workHours = double.tryParse(hoursC.text) ?? 1.0; 
                  widget.record.memo = memoC.text; // 🌟 [해결 5] 메모 확실히 덮어쓰기 완료!
                  widget.record.photoPath = selectedPhotos.isNotEmpty ? selectedPhotos.first : null; 
                  widget.record.photoPaths = selectedPhotos; 
                  widget.record.weather = selectedWeather; 
                  widget.record.isSchedule = isScheduleMode; 
                  
                  await ref.read(workProvider.notifier).updateRecord(widget.record); 
                  Get.back(); 
                  Get.snackbar('완료', '수정되었습니다.');
                },
                child: const Text('수정 완료', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}