// lib/screens/chat_room_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../providers/app_provider.dart';

class ChatRoomScreen extends ConsumerStatefulWidget {
  final String roomId;
  final String roomName;
  final String companyCode;

  const ChatRoomScreen({super.key, required this.roomId, required this.roomName, required this.companyCode});

  @override
  ConsumerState<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends ConsumerState<ChatRoomScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final User? _user = FirebaseAuth.instance.currentUser;

  void _sendMessage() async {
    if (_msgCtrl.text.trim().isEmpty || _user == null) return;
    final text = _msgCtrl.text.trim();
    _msgCtrl.clear();

    final roomRef = FirebaseFirestore.instance.collection('companies').doc(widget.companyCode).collection('chatRooms').doc(widget.roomId);
    
    // 1. 메시지 저장
    await roomRef.collection('messages').add({
      'senderId': _user!.uid, 'senderName': ref.read(appSettingsProvider).userName ?? '익명', 'text': text, 'timestamp': FieldValue.serverTimestamp(),
    });
    // 2. 방의 최근 메시지 갱신 (목록 화면용)
    await roomRef.update({'lastMessage': text, 'updatedAt': FieldValue.serverTimestamp()});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.roomName), centerTitle: true),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('companies').doc(widget.companyCode).collection('chatRooms').doc(widget.roomId).collection('messages').orderBy('timestamp', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final msgs = snapshot.data!.docs;
                return ListView.builder(
                  reverse: true, itemCount: msgs.length,
                  itemBuilder: (context, index) {
                    final msg = msgs[index].data() as Map<String, dynamic>;
                    final isMe = msg['senderId'] == _user?.uid;
                    final time = msg['timestamp'] != null ? DateFormat('a h:mm', 'ko_KR').format((msg['timestamp'] as Timestamp).toDate()) : '';

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Column(
                        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          if (!isMe) Padding(padding: const EdgeInsets.only(bottom: 4, left: 4), child: Text(msg['senderName'] ?? '', style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold))),
                          Row(
                            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (isMe) Text(time, style: const TextStyle(fontSize: 10, color: Colors.grey)), if (isMe) const SizedBox(width: 4),
                              Container(
                                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(color: isMe ? const Color(0xFF5A55F5) : Colors.grey[300], borderRadius: BorderRadius.circular(15)),
                                child: Text(msg['text'] ?? '', style: TextStyle(color: isMe ? Colors.white : Colors.black87)),
                              ),
                              if (!isMe) const SizedBox(width: 4), if (!isMe) Text(time, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8), color: Theme.of(context).cardColor,
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(child: TextField(controller: _msgCtrl, decoration: InputDecoration(hintText: '메시지 입력...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none), filled: true, fillColor: Colors.grey[200]), onSubmitted: (_) => _sendMessage())),
                  const SizedBox(width: 8),
                  FloatingActionButton(mini: true, backgroundColor: const Color(0xFF5A55F5), onPressed: _sendMessage, child: const Icon(Icons.send, color: Colors.white, size: 18))
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}