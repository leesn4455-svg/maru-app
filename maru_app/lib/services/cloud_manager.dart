// lib/services/cloud_manager.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class CloudManager {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. 서버에 데이터 업로드 (저장)
  static Future<void> saveDocument({required String collection, required String docId, required Map<String, dynamic> data}) async {
    await _db.collection(collection).doc(docId).set(data);
  }

  // 2. 서버에서 데이터 다운로드 (불러오기)
  static Future<Map<String, dynamic>?> getDocument({required String collection, required String docId}) async {
    final doc = await _db.collection(collection).doc(docId).get();
    if (doc.exists) {
      return doc.data();
    }
    return null;
  }

  // TODO: 나중에 팀원 스케줄 실시간 불러오기(스트리밍) 기능이 여기에 추가됩니다!
}