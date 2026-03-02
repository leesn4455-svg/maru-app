// lib/models/chat_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;          // 메시지 고유 ID
  final String senderId;    // 보낸 사람 UID
  final String senderName;  // 보낸 사람 이름
  final String text;        // 메시지 내용
  final DateTime timestamp; // 보낸 시간

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
  });

  // Firestore(Map)에서 데이터를 가져올 때 쓰는 공장
  factory ChatMessage.fromMap(Map<String, dynamic> map, String id) {
    return ChatMessage(
      id: id,
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '알 수 없음',
      text: map['text'] ?? '',
      // Firestore의 Timestamp를 DateTime으로 변환
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Firestore(Map)로 데이터를 보낼 때 쓰는 변환기
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(), // 서버 기준 시간 입력
    };
  }
}