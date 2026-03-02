// lib/screens/board_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // 🌟 갤러리 '항상' 선택을 위해 원상 복구
import 'package:screenshot/screenshot.dart';
import 'package:gal/gal.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';

import '../theme/app_theme.dart';
import '../widgets/board_overlay.dart'; 

class BoardScreen extends StatefulWidget {
  const BoardScreen({super.key});
  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  final _box = Hive.box('preferences');
  final ScreenshotController _screenshotController = ScreenshotController();
  File? _image; double _boardX = 10; double _boardY = 10; 
  List<Map<String, dynamic>> _fields = [];
  final Map<int, TextEditingController> _labelCtrls = {};
  final Map<int, TextEditingController> _valueCtrls = {};

  @override
  void initState() {
    super.initState();
    _loadBoardData();
    String? lastImagePath = _box.get('last_board_image');
    if (lastImagePath != null && File(lastImagePath).existsSync()) {
      _image = File(lastImagePath); _boardX = _box.get('last_board_x', defaultValue: 10.0); _boardY = _box.get('last_board_y', defaultValue: 10.0);
    }
  }

  void _loadBoardData() {
    final savedFields = _box.get('board_fields');
    if (savedFields != null) {
      _fields = List<Map<String, dynamic>>.from(savedFields.map((e) => Map<String, dynamic>.from(e)));
    } else {
      _fields = [
        {'label': '현장명', 'value': '', 'history': <String>[]}, {'label': '일시', 'value': DateFormat('yyyy.MM.dd').format(DateTime.now()), 'history': <String>[]},
        {'label': '동 호수', 'value': '', 'history': <String>[]}, {'label': '위치', 'value': '', 'history': <String>[]},
        {'label': '하자원인', 'value': '', 'history': <String>[]}, {'label': '조치내역', 'value': '', 'history': <String>[]},
      ];
    }
    for (int i = 0; i < _fields.length; i++) {
      _labelCtrls[i] = TextEditingController(text: _fields[i]['label']); _valueCtrls[i] = TextEditingController(text: _fields[i]['value']);
    }
    _valueCtrls[1]!.text = DateFormat('yyyy.MM.dd').format(DateTime.now()); _fields[1]['value'] = _valueCtrls[1]!.text;
    setState(() {});
  }

  void _syncTextToState(int index, String val) {
    _fields[index]['value'] = val; _fields[index]['label'] = _labelCtrls[index]!.text; _box.put('board_fields', _fields); setState(() {}); 
  }

  void _saveToHistory() {
    for (int i = 0; i < _fields.length; i++) {
      String val = _valueCtrls[i]!.text.trim();
      if (val.isNotEmpty) {
        List<String> history = List<String>.from(_fields[i]['history'] ?? []);
        if (!history.contains(val)) { history.insert(0, val); if (history.length > 20) history = history.sublist(0, 20); _fields[i]['history'] = history; }
      }
    }
    _box.put('board_fields', _fields);
  }

  // 🌟 구글 포토 대신 시스템 앱 선택기(App Chooser)를 띄워 '삼성 갤러리 - 항상' 설정이 가능하도록 변경
  Future<void> _pickImage(ImageSource source) async {
    FocusScope.of(context).unfocus(); 
    _saveToHistory(); 
    try {
      final picked = await ImagePicker().pickImage(source: source, imageQuality: 100, maxWidth: 4080, maxHeight: 3060);
      if (picked != null) {
        if (source == ImageSource.camera) { try { await Gal.putImage(picked.path, album: 'Maru_원본'); } catch (e) {} }
        setState(() { _image = File(picked.path); _boardX = 10; _boardY = 10; });
        _box.put('last_board_image', picked.path); _box.put('last_board_x', _boardX); _box.put('last_board_y', _boardY);
        Future.delayed(const Duration(milliseconds: 500), () => _autoSaveToGallery());
      }
    } catch (e) { Get.snackbar('오류', '권한을 확인해주세요.'); }
  }

  Future<void> _autoSaveToGallery() async {
    if (_image == null) return;
    try {
      final imageBytes = await _screenshotController.capture(delay: const Duration(milliseconds: 100));
      if (imageBytes != null) {
        String siteName = _valueCtrls[0]!.text.trim();
        await Gal.putImageBytes(imageBytes, album: siteName.isEmpty ? '동산보드' : siteName);
      }
    } catch (e) {}
  }

  void _showHistoryModal(int index) {
    FocusScope.of(context).unfocus();
    List<String> history = List<String>.from(_fields[index]['history'] ?? []);
    if (history.isEmpty) { Get.snackbar('알림', '최근 입력한 기록이 없습니다.'); return; }
    Get.bottomSheet(
      StatefulBuilder(builder: (context, setModalState) {
        return SafeArea(
          child: Container(
            height: 250, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15), decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 40, height: 5, margin: const EdgeInsets.only(bottom: 10), decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
                Text('${_labelCtrls[index]!.text} 최근 기록', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)), const SizedBox(height: 5),
                Expanded(child: ListView.builder(itemCount: history.length, itemBuilder: (context, i) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero, dense: true, leading: const Icon(Icons.history, color: Colors.grey, size: 18), title: Text(history[i], style: const TextStyle(fontSize: 14)),
                    onTap: () { _valueCtrls[index]!.text = history[i]; _syncTextToState(index, history[i]); Get.back(); },
                    trailing: IconButton(icon: const Icon(Icons.close, color: Colors.redAccent, size: 16), onPressed: () { setModalState(() { history.removeAt(i); _fields[index]['history'] = history; _box.put('board_fields', _fields); }); }),
                  );
                }))
              ]
            )
          )
        );
      }),
      isScrollControlled: true, 
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          bottom: false, 
          child: Stack(
            children: [
              Column(
                children: [
                  Container(
                    height: 240, 
                    padding: const EdgeInsets.only(left: 45.0, right: 45.0, top: 40.0, bottom: 5.0),
                    child: Container(
                      // 🌟 [디자인 변경] 두꺼운 검은 테두리 대신 부드러운 둥근 모서리와 옅은 그림자로 고급스럽게!
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
                        border: Border.all(color: Colors.grey.shade300, width: 1.0),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Column(
                          children: List.generate(_fields.length, (index) {
                            return Expanded( 
                              child: Container(
                                decoration: BoxDecoration(border: index < _fields.length - 1 ? Border(bottom: BorderSide(color: Colors.grey.shade200, width: 1.0)) : null),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Container(
                                      width: 70, 
                                      // 🌟 라벨 배경에 은은한 보랏빛 투명도를 주어 구분감 향상
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor.withOpacity(0.05), 
                                        border: Border(right: BorderSide(color: Colors.grey.shade300, width: 1.0))
                                      ), 
                                      child: Center(
                                        // 🌟 [수정] 라벨 폰트 크기 증가 및 중앙 정렬 완벽 적용
                                        child: TextField(controller: _labelCtrls[index], textAlign: TextAlign.center, textAlignVertical: TextAlignVertical.center, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87), decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero), onChanged: (val) => _syncTextToState(index, val))
                                      )
                                    ),
                                    Expanded(
                                      child: Center(
                                        // 🌟 [수정] 내용 폰트 크기 증가 및 중앙 정렬 완벽 적용
                                        child: TextField(controller: _valueCtrls[index], textAlignVertical: TextAlignVertical.center, style: const TextStyle(fontSize: 14, color: Colors.black87), decoration: InputDecoration(border: InputBorder.none, isDense: true, contentPadding: const EdgeInsets.symmetric(horizontal: 10), suffixIconConstraints: const BoxConstraints(minWidth: 30, minHeight: 30), suffixIcon: IconButton(icon: const Icon(Icons.arrow_drop_down_circle, color: AppTheme.primaryColor, size: 18), padding: EdgeInsets.zero, onPressed: () => _showHistoryModal(index))), onChanged: (val) => _syncTextToState(index, val))
                                      )
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      width: double.infinity, 
                      // 🌟 [수정] 하단 여백을 검은색에서 앱 기본 배경색으로 통일하여 일체감 형성
                      color: Theme.of(context).scaffoldBackgroundColor, 
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 30.0, right: 30.0, top: 15.0, bottom: 10.0),
                            child: Row(
                              children: [
                                Expanded(child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), onPressed: () => _pickImage(ImageSource.camera), icon: const Icon(Icons.camera_alt, size: 18), label: const Text('촬영하기', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))), const SizedBox(width: 10),
                                // 배경이 하얘졌으므로 불러오기 버튼 색상도 파란색(기본)으로 변경
                                Expanded(child: OutlinedButton.icon(style: OutlinedButton.styleFrom(foregroundColor: AppTheme.primaryColor, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), side: const BorderSide(color: AppTheme.primaryColor)), onPressed: () => _pickImage(ImageSource.gallery), icon: const Icon(Icons.photo_library, size: 18), label: const Text('불러오기', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)))),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 40.0), 
                              child: _image == null 
                                  ? const Center(child: Text('사진을 촬영하거나 불러오세요.', style: TextStyle(color: Colors.grey)))
                                  : Center(
                                      child: Screenshot(
                                        controller: _screenshotController,
                                        child: Stack(
                                          children: [
                                            Image.file(_image!, fit: BoxFit.contain), 
                                            Positioned(
                                              left: _boardX, bottom: _boardY,
                                              child: GestureDetector(
                                                onPanUpdate: (details) { setState(() { _boardX += details.delta.dx; _boardY -= details.delta.dy; }); _box.put('last_board_x', _boardX); _box.put('last_board_y', _boardY); },
                                                child: Transform.scale(scale: 0.7, alignment: Alignment.bottomLeft, child: BoardOverlay(fields: _fields)),
                                              ),
                                            )
                                          ],
                                        ),
                                      ),
                                    ),
                            ),
                          )
                        ],
                      ),
                    ),
                  )
                ],
              ),
              Positioned(top: 5, left: 5, child: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 22), onPressed: () => Get.back()))
            ],
          ),
        ),
      ),
    );
  }
}