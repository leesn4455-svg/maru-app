// lib/screens/chat_room_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../providers/app_provider.dart';
import 'chat_room_screen.dart';

class ChatRoomListScreen extends ConsumerStatefulWidget {
  const ChatRoomListScreen({super.key});
  @override
  ConsumerState<ChatRoomListScreen> createState() => _ChatRoomListScreenState();
}

class _ChatRoomListScreenState extends ConsumerState<ChatRoomListScreen> {
  String? _companyCode;
  User? _currentUser;

  @override
  void initState() {
    super.initState();
    _companyCode = ref.read(appSettingsProvider).companyCode;
    _currentUser = FirebaseAuth.instance.currentUser;
    _registerUserToCompany();
  }

  Future<void> _registerUserToCompany() async {
    if (_companyCode == null || _currentUser == null) return;
    await FirebaseFirestore.instance.collection('companies').doc(_companyCode).collection('users').doc(_currentUser!.uid).set({
      'uid': _currentUser!.uid,
      'name': ref.read(appSettingsProvider).userName ?? '익명',
      'email': _currentUser!.email,
    }, SetOptions(merge: true));
  }

  void _showCreateRoomModal() async {
    final snapshot = await FirebaseFirestore.instance.collection('companies').doc(_companyCode).collection('users').get();
    final allUsers = snapshot.docs.where((doc) => doc.id != _currentUser!.uid).toList();
    
    List<String> selectedUids = [_currentUser!.uid]; 
    String roomName = "새로운 채팅방";

    // 🌟 [해결] 키보드에 밀려 찌그러지지 않도록 팝업창을 화면 중앙 Dialog로 변경!
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              // 기기 화면 높이의 60%를 차지하도록 고정하여 찌그러짐 방지
              height: MediaQuery.of(context).size.height * 0.6,
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('새 채팅방 만들기', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  TextField(
                    autofocus: true,
                    decoration: InputDecoration(labelText: '채팅방 이름 (예: A현장 팀)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10))), 
                    onChanged: (val) => roomName = val
                  ),
                  const SizedBox(height: 20),
                  const Text('초대할 팀원 선택', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(10)),
                      child: ListView.builder(
                        itemCount: allUsers.length,
                        itemBuilder: (context, i) {
                          final u = allUsers[i].data();
                          final isSelected = selectedUids.contains(u['uid']);
                          return CheckboxListTile(
                            title: Text(u['name'] ?? '알 수 없음'), subtitle: Text(u['email'] ?? ''), value: isSelected,
                            onChanged: (val) { setModalState(() { if (val!) selectedUids.add(u['uid']); else selectedUids.remove(u['uid']); }); },
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5A55F5), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                    onPressed: () async {
                      FocusScope.of(context).unfocus(); // 키보드 먼저 숨기기
                      if (selectedUids.length < 2) { Get.snackbar('알림', '최소 1명 이상 초대해주세요.'); return; }
                      final roomRef = FirebaseFirestore.instance.collection('companies').doc(_companyCode).collection('chatRooms').doc();
                      await roomRef.set({
                        'id': roomRef.id, 'name': roomName, 'participants': selectedUids,
                        'lastMessage': '채팅방이 생성되었습니다.', 'createdAt': FieldValue.serverTimestamp(), 'updatedAt': FieldValue.serverTimestamp()
                      });
                      Get.back(); Get.to(() => ChatRoomScreen(roomId: roomRef.id, roomName: roomName, companyCode: _companyCode!));
                    },
                    child: const Text('채팅방 만들기', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  )
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_companyCode == null || _currentUser == null) return Scaffold(appBar: AppBar(title: const Text('채팅방 목록')), body: const Center(child: Text('회사 코드가 없거나 로그인이 필요합니다.')));

    return Scaffold(
      appBar: AppBar(title: const Text('우리 회사 채팅', style: TextStyle(fontWeight: FontWeight.bold)), centerTitle: true),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('companies').doc(_companyCode).collection('chatRooms').where('participants', arrayContains: _currentUser!.uid).orderBy('updatedAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final rooms = snapshot.data!.docs;
          if (rooms.isEmpty) return const Center(child: Text('참여 중인 채팅방이 없습니다.\n우측 하단 버튼을 눌러 생성해보세요.'));

          return ListView.builder(
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index].data() as Map<String, dynamic>;
              return ListTile(
                leading: const CircleAvatar(backgroundColor: Color(0xFF5A55F5), child: Icon(Icons.group, color: Colors.white)),
                title: Text(room['name'] ?? '이름 없음', style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(room['lastMessage'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                onTap: () => Get.to(() => ChatRoomScreen(roomId: room['id'], roomName: room['name'], companyCode: _companyCode!)),
              );
            },
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 20.0), 
        child: FloatingActionButton(
          backgroundColor: const Color(0xFF5A55F5), 
          onPressed: _showCreateRoomModal, 
          child: const Icon(Icons.add_comment, color: Colors.white)
        ),
      ),
    );
  }
}