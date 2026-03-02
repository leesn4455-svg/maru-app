// lib/screens/board_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  
  File? _image;
  double _boardX = 10;
  double _boardY = 10; 

  List<Map<String, dynamic>> _fields = [];
  final Map<int, TextEditingController> _labelCtrls = {};
  final Map<int, TextEditingController> _valueCtrls = {};

  @override
  void initState() {
    super.initState();
    _loadBoardData();
    
    String? lastImagePath = _box.get('last_board_image');
    if (lastImagePath != null && File(lastImagePath).existsSync()) {
      _image = File(lastImagePath);
      _boardX = _box.get('last_board_x', defaultValue: 10.0);
      _boardY = _box.get('last_board_y', defaultValue: 10.0);
    }
  }

  void _loadBoardData() {
    final savedFields = _box.get('board_fields');
    if (savedFields != null) {
      _fields = List<Map<String, dynamic>>.from(savedFields.map((e) => Map<String, dynamic>.from(e)));
    } else {
      _fields = [
        {'label': '현장명', 'value': '', 'history': <String>[]},
        {'label': '일시', 'value': DateFormat('yyyy.MM.dd').format(DateTime.now()), 'history': <String>[]},
        {'label': '동 호수', 'value': '', 'history': <String>[]},
        {'label': '위치', 'value': '', 'history': <String>[]},
        {'label': '하자원인', 'value': '', 'history': <String>[]},
        {'label': '조치내역', 'value': '', 'history': <String>[]},
      ];
    }

    for (int i = 0; i < _fields.length; i++) {
      _labelCtrls[i] = TextEditingController(text: _fields[i]['label']);
      _valueCtrls[i] = TextEditingController(text: _fields[i]['value']);
    }
    _valueCtrls[1]!.text = DateFormat('yyyy.MM.dd').format(DateTime.now());
    _fields[1]['value'] = _valueCtrls[1]!.text;
    setState(() {});
  }

  void _syncTextToState(int index, String val) {
    _fields[index]['value'] = val;
    _fields[index]['label'] = _labelCtrls[index]!.text;
    _box.put('board_fields', _fields);
    setState(() {}); 
  }

  void _saveToHistory() {
    for (int i = 0; i < _fields.length; i++) {
      String val = _valueCtrls[i]!.text.trim();
      if (val.isNotEmpty) {
        List<String> history = List<String>.from(_fields[i]['history'] ?? []);
        if (!history.contains(val)) {
          history.insert(0, val);
          if (history.length > 20) history = history.sublist(0, 20); 
          _fields[i]['history'] = history;
        }
      }
    }
    _box.put('board_fields', _fields);
  }

  Future<void> _pickImage(ImageSource source) async {
    FocusScope.of(context).unfocus(); 
    _saveToHistory(); 

    try {
      final picked = await ImagePicker().pickImage(source: source, imageQuality: 100, maxWidth: 4080, maxHeight: 3060);
      if (picked != null) {
        if (source == ImageSource.camera) {
          try { await Gal.putImage(picked.path, album: 'Maru_원본'); } catch (e) { /* 무시 */ }
        }

        setState(() {
          _image = File(picked.path);
          _boardX = 10;
          _boardY = 10;
        });
        
        _box.put('last_board_image', picked.path);
        _box.put('last_board_x', _boardX);
        _box.put('last_board_y', _boardY);
        
        Future.delayed(const Duration(milliseconds: 500), () {
          _autoSaveToGallery();
        });
      }
    } catch (e) {
      Get.snackbar('오류', '카메라/갤러리 권한을 확인해주세요.');
    }
  }

  Future<void> _autoSaveToGallery() async {
    if (_image == null) return;
    try {
      final imageBytes = await _screenshotController.capture(delay: const Duration(milliseconds: 100));
      if (imageBytes != null) {
        String siteName = _valueCtrls[0]!.text.trim();
        String folderName = siteName.isEmpty ? '동산보드' : siteName;
        await Gal.putImageBytes(imageBytes, album: folderName);
      }
    } catch (e) {
      debugPrint('저장 실패: $e');
    }
  }

  void _showHistoryModal(int index) {
    FocusScope.of(context).unfocus();
    List<String> history = List<String>.from(_fields[index]['history'] ?? []);
    if (history.isEmpty) { Get.snackbar('알림', '최근 입력한 기록이 없습니다.'); return; }

    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setModalState) {
          return SafeArea(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${_labelCtrls[index]!.text} 최근 기록', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: history.length,
                      itemBuilder: (context, i) {
                        return ListTile(
                          leading: const Icon(Icons.history, color: Colors.grey),
                          title: Text(history[i]),
                          onTap: () {
                            _valueCtrls[index]!.text = history[i];
                            _syncTextToState(index, history[i]);
                            Get.back();
                          },
                          trailing: IconButton(
                            icon: const Icon(Icons.close, color: Colors.redAccent, size: 18),
                            onPressed: () {
                              setModalState(() { 
                                history.removeAt(i); 
                                _fields[index]['history'] = history; 
                                _box.put('board_fields', _fields); 
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      ),
      isScrollControlled: true, 
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(title: const Text('동산보드', style: TextStyle(fontWeight: FontWeight.bold)), centerTitle: true),
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          child: Column(
            children: [
              // 🌟 [수정] 상단 입력 영역 (비율을 45% -> 35%로 줄여서 더 슬림하게 만듦)
              Expanded(
                flex: 35, 
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(border: Border.all(color: Colors.black, width: 1.0)),
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            itemCount: _fields.length,
                            itemBuilder: (context, index) {
                              return Container(
                                height: 38, 
                                decoration: BoxDecoration(border: index < _fields.length - 1 ? const Border(bottom: BorderSide(color: Colors.black, width: 0.5)) : null),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 70,
                                      decoration: const BoxDecoration(color: Color(0xFFF5F6F8), border: Border(right: BorderSide(color: Colors.black, width: 0.5))),
                                      child: TextField(
                                        controller: _labelCtrls[index],
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                        decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 10)),
                                        onChanged: (val) => _syncTextToState(index, val),
                                      ),
                                    ),
                                    Expanded(
                                      child: TextField(
                                        controller: _valueCtrls[index],
                                        style: const TextStyle(fontSize: 14),
                                        decoration: InputDecoration(
                                          border: InputBorder.none, isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                                          suffixIconConstraints: const BoxConstraints(minWidth: 35, minHeight: 30),
                                          suffixIcon: IconButton(icon: const Icon(Icons.arrow_drop_down_circle, color: AppTheme.primaryColor, size: 20), padding: EdgeInsets.zero, onPressed: () => _showHistoryModal(index)),
                                        ),
                                        onChanged: (val) => _syncTextToState(index, val),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), onPressed: () => _pickImage(ImageSource.camera), icon: const Icon(Icons.camera_alt, size: 20), label: const Text('촬영하기', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)))),
                          const SizedBox(width: 8),
                          Expanded(child: OutlinedButton.icon(style: OutlinedButton.styleFrom(foregroundColor: AppTheme.primaryColor, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), side: const BorderSide(color: AppTheme.primaryColor)), onPressed: () => _pickImage(ImageSource.gallery), icon: const Icon(Icons.photo_library, size: 20), label: const Text('불러오기', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)))),
                        ],
                      ),
                      const SizedBox(height: 6),
                    ],
                  ),
                ),
              ),

              // 🌟 [수정] 하단 사진 영역 (비율을 55% -> 65%로 늘려서 더 시원하게 보임)
              Expanded(
                flex: 65, 
                child: Container(
                  width: double.infinity,
                  color: Colors.black, 
                  child: _image == null 
                      ? const Center(child: Text('사진을 촬영하거나 불러오세요.', style: TextStyle(color: Colors.white54)))
                      : Screenshot(
                          controller: _screenshotController,
                          child: Stack(
                            fit: StackFit.expand, 
                            children: [
                              Image.file(_image!, fit: BoxFit.cover),
                              Positioned(
                                left: _boardX, bottom: _boardY,
                                child: GestureDetector(
                                  onPanUpdate: (details) { 
                                    setState(() { 
                                      _boardX += details.delta.dx; 
                                      _boardY -= details.delta.dy; 
                                    }); 
                                    _box.put('last_board_x', _boardX);
                                    _box.put('last_board_y', _boardY);
                                  },
                                  child: BoardOverlay(fields: _fields), 
                                ),
                              )
                            ],
                          ),
                        ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}