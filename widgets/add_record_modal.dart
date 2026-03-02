// lib/widgets/add_record_modal.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart'; 
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart'; 
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/app_models.dart';
import '../providers/work_provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../utils/app_utils.dart';
import '../services/api_service.dart'; // 🌟 서버 통신 파일 임포트

class AddRecordModal extends ConsumerStatefulWidget {
  final DateTime selectedDate;
  const AddRecordModal({super.key, required this.selectedDate});

  @override
  ConsumerState<AddRecordModal> createState() => _AddRecordModalState();
}

class _AddRecordModalState extends ConsumerState<AddRecordModal> {
  late TextEditingController siteC;
  late TextEditingController wageC;
  late TextEditingController hoursC;
  late TextEditingController memoC;
  
  List<String> selectedPhotos = []; 
  String? selectedWeather; 
  bool isBatchInput = false; 
  late DateTime batchStartDate; 
  late DateTime batchEndDate; 
  bool isScheduleMode = false;

  // 🌟 서버에서 불러온 현장 정보를 담을 변수
  List<dynamic> serverSites = [];
  bool isSitesLoading = true;

  @override
  void initState() {
    super.initState();
    final appSettings = ref.read(appSettingsProvider);
    siteC = TextEditingController();
    wageC = TextEditingController(text: appSettings.defaultWage != null && appSettings.defaultWage! > 0 ? NumberFormat('#,###').format(appSettings.defaultWage) : '');
    hoursC = TextEditingController(text: '1.0');
    memoC = TextEditingController();
    batchStartDate = widget.selectedDate; 
    batchEndDate = widget.selectedDate;

    // 🌟 모달이 열릴 때 서버에서 현장 목록을 가져옵니다.
    _fetchSites();
  }

  Future<void> _fetchSites() async {
    final data = await ApiService.getSites();
    if (mounted) {
      setState(() {
        serverSites = data;
        isSitesLoading = false;
      });
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
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(isScheduleMode ? '일정 등록' : '공수 추가', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)), Row(children: [const Text('기간 일괄 입력', style: TextStyle(fontSize: 12, color: Colors.grey)), Switch(value: isBatchInput, activeColor: AppTheme.primaryColor, onChanged: (val) => setState(() => isBatchInput = val))])]),
              if (isBatchInput) Row(children: [Expanded(child: OutlinedButton(onPressed: () async { final d = await showDatePicker(context: context, initialDate: batchStartDate, firstDate: DateTime(2020), lastDate: DateTime(2030)); if(d!=null) setState(()=>batchStartDate=d); }, child: Text(DateFormat('yyyy-MM-dd').format(batchStartDate)))), const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('~')), Expanded(child: OutlinedButton(onPressed: () async { final d = await showDatePicker(context: context, initialDate: batchEndDate, firstDate: DateTime(2020), lastDate: DateTime(2030)); if(d!=null) setState(()=>batchEndDate=d); }, child: Text(DateFormat('yyyy-MM-dd').format(batchEndDate))))]),
              const SizedBox(height: 15),
              
              // 🌟 서버 현장 정보 리스트 UI
              if (isSitesLoading) const Center(child: CircularProgressIndicator()),
              if (!isSitesLoading && serverSites.isNotEmpty) ...[
                const Text('등록된 현장 (원터치 자동 입력)', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: serverSites.length,
                    itemBuilder: (context, index) {
                      final site = serverSites[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ActionChip(
                          backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                          side: BorderSide.none,
                          labelStyle: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                          label: Text(site['site_name'] ?? '알 수 없음'),
                          onPressed: () {
                            setState(() {
                              siteC.text = site['site_name'] ?? '';
                              if (site['default_wage'] != null) {
                                int wageVal = int.tryParse(site['default_wage'].toString()) ?? 0;
                                if (wageVal > 0) {
                                  wageC.text = NumberFormat('#,###').format(wageVal);
                                }
                              }
                            });
                            Get.snackbar('적용 완료', '${site['site_name']} 현장이 입력되었습니다.', duration: const Duration(seconds: 1), snackPosition: SnackPosition.TOP);
                          },
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 15),
              ],

              TextField(controller: siteC, decoration: InputDecoration(labelText: '현장명 (필수)', prefixIcon: const Icon(Icons.business), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 15),
              Row(children: [Expanded(child: TextField(controller: hoursC, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: isScheduleMode ? '예상 공수' : '공수', prefixIcon: const Icon(Icons.access_time), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))), const SizedBox(width: 15), Expanded(child: TextField(controller: wageC, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly, ThousandsFormatter()], decoration: InputDecoration(labelText: isScheduleMode ? '예상 단가 (필수)' : '단가 (필수)', prefixIcon: const Icon(Icons.attach_money), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))) ]),
              const SizedBox(height: 8),
              Wrap(spacing: 10, alignment: WrapAlignment.center, children: [0.5, 1.0, 1.5, 2.0].map((e) => ActionChip(backgroundColor: const Color(0xFFEEF0FF), side: BorderSide.none, label: Text('$e공수', style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)), onPressed: () => setState(() => hoursC.text = e.toString()))).toList()),
              const SizedBox(height: 15),
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: ['☀️', '☁️', '🌧️', '❄️'].map((w) => GestureDetector(onTap: () => setState(() => selectedWeather = w), child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: selectedWeather == w ? AppTheme.primaryColor.withOpacity(0.2) : Colors.transparent, borderRadius: BorderRadius.circular(8)), child: Text(w, style: const TextStyle(fontSize: 24))))).toList()),
              const SizedBox(height: 15),
              TextField(controller: memoC, decoration: InputDecoration(labelText: '메모', prefixIcon: const Icon(Icons.note), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
              const SizedBox(height: 20),
              
              const Text('현장 사진 (가로로 스와이프, 여러 장 가능)', style: TextStyle(color: Colors.grey, fontSize: 12)),
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
                        child: Container(width: 100, margin: const EdgeInsets.only(left: 8), decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey)), child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo, size: 30, color: Colors.grey), Text('사진 추가', style: TextStyle(color: Colors.grey))])),
                      );
                    }
                    return Container(
                      width: 100, margin: const EdgeInsets.only(right: 10),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(selectedPhotos[index]), fit: BoxFit.cover)),
                          Positioned(top: 4, right: 4, child: GestureDetector(onTap: () => setState(() => selectedPhotos.removeAt(index)), child: Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle), child: const Icon(Icons.close, size: 16, color: Colors.white)))),
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
                  if (siteC.text.isEmpty || wageC.text.isEmpty) { Get.snackbar('오류', '현장명과 단가를 입력하세요', backgroundColor: Colors.redAccent, colorText: Colors.white); return; }
                  int wage = int.tryParse(wageC.text.replaceAll(',', '')) ?? 0; double hours = double.tryParse(hoursC.text) ?? 1.0;
                  
                  final photoPathFallback = selectedPhotos.isNotEmpty ? selectedPhotos.first : null;

                  if (isBatchInput) {
                    for (DateTime d = batchStartDate; d.isBefore(batchEndDate.add(const Duration(days: 1))); d = d.add(const Duration(days: 1))) {
                      await ref.read(workProvider.notifier).addRecord(WorkRecord(date: d, workHours: hours, dailyWage: wage, siteName: siteC.text, memo: memoC.text, photoPath: photoPathFallback, photoPaths: selectedPhotos, weather: selectedWeather, isSchedule: isScheduleMode));
                    }
                  } else { 
                    await ref.read(workProvider.notifier).addRecord(WorkRecord(date: widget.selectedDate, workHours: hours, dailyWage: wage, siteName: siteC.text, memo: memoC.text, photoPath: photoPathFallback, photoPaths: selectedPhotos, weather: selectedWeather, isSchedule: isScheduleMode)); 
                  }
                  Get.back(); Get.snackbar('저장 완료', '성공적으로 추가되었습니다.');
                },
                child: Text(isScheduleMode ? '일정 저장하기' : '공수 저장하기', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}