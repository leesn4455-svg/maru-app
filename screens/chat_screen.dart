// lib/screens/chat_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../services/api_service.dart';
import '../theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  
  List<dynamic> chatMessages = [];
  String myId = "";
  String myName = "";
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // 내 정보 꺼내기
    final box = Hive.box('preferences');
    myId = box.get('user_login_id', defaultValue: '');
    myName = box.get('user_name', defaultValue: '알 수 없음');

    _fetchChats(); // 처음 열릴 때 한 번 불러오기
    
    // 🌟 카카오톡처럼 실시간으로 보일 수 있게 2초마다 서버에서 새 메시지 확인!
    _timer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _fetchChats(isBackground: true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel(); // 화면 나가면 타이머 정지 (배터리 절약)
    _msgCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchChats({bool isBackground = false}) async {
    final data = await ApiService.getChats();
    if (mounted) {
      setState(() {
        chatMessages = data;
      });
      // 데이터가 오면 스크롤을 맨 밑으로 (최신 메시지로) 내립니다.
      if (!isBackground) {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (_scrollCtrl.hasClients) {
            _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
          }
        });
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty) return;
    
    _msgCtrl.clear(); // 입력창 비우기
    bool success = await ApiService.sendChat(myId, myName, text);
    if (success) {
      await _fetchChats(); // 보낸 직후 바로 화면 새로고침
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
      }
    } else {
      Get.snackbar('오류', '메시지 전송에 실패했습니다.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text('사내 실시간 채팅', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black), onPressed: () => Get.back()),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                itemCount: chatMessages.length,
                itemBuilder: (context, index) {
                  final chat = chatMessages[index];
                  bool isMe = (chat['sender_id'] == myId); // 내가 보낸 건지 남이 보낸 건지 확인
                  
                  // 시간 포맷 (예: 14:30)
                  String timeStr = "";
                  if (chat['created_at'] != null) {
                    timeStr = chat['created_at'].toString().substring(11, 16);
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (!isMe) ...[
                          CircleAvatar(
                            backgroundColor: Colors.grey.shade300,
                            radius: 16,
                            child: Text(chat['sender_name']?.substring(0, 1) ?? '', style: const TextStyle(fontSize: 12, color: Colors.black, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 8),
                        ],
                        
                        if (isMe) Padding(padding: const EdgeInsets.only(right: 8, bottom: 2), child: Text(timeStr, style: const TextStyle(fontSize: 10, color: Colors.grey))),
                        
                        Flexible(
                          child: Column(
                            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              if (!isMe) Padding(padding: const EdgeInsets.only(bottom: 4, left: 4), child: Text(chat['sender_name'] ?? '알 수 없음', style: const TextStyle(fontSize: 12, color: Colors.black54))),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isMe ? AppTheme.primaryColor : Colors.white,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(16),
                                    topRight: const Radius.circular(16),
                                    bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                                    bottomRight: isMe ? Radius.zero : const Radius.circular(16),
                                  ),
                                  border: isMe ? null : Border.all(color: Colors.grey.shade300)
                                ),
                                child: Text(chat['message'] ?? '', style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 14)),
                              ),
                            ],
                          ),
                        ),
                        
                        if (!isMe) Padding(padding: const EdgeInsets.only(left: 8, bottom: 2), child: Text(timeStr, style: const TextStyle(fontSize: 10, color: Colors.grey))),
                      ],
                    ),
                  );
                },
              ),
            ),
            
            // 🌟 메시지 입력창
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), offset: const Offset(0, -2), blurRadius: 10)]),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      decoration: InputDecoration(
                        hintText: '메시지를 입력하세요...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                        filled: true,
                        fillColor: const Color(0xFFF5F6F8),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  CircleAvatar(
                    backgroundColor: AppTheme.primaryColor,
                    child: IconButton(icon: const Icon(Icons.send, color: Colors.white, size: 20), onPressed: _sendMessage),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}