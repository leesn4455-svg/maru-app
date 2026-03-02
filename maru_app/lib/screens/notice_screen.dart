// lib/screens/notice_screen.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';

class NoticeScreen extends StatefulWidget {
  const NoticeScreen({super.key});

  @override
  State<NoticeScreen> createState() => _NoticeScreenState();
}

class _NoticeScreenState extends State<NoticeScreen> {
  final _box = Hive.box('preferences');
  List<Map<String, dynamic>> _notices = [];
  String _userRole = '팀원'; // 기본 권한

  @override
  void initState() {
    super.initState();
    _loadNotices();
    // 🌟 내 정보에서 설정한 직급(Role)을 불러옵니다.
    _userRole = _box.get('user_role', defaultValue: '팀원');
  }

  void _loadNotices() {
    // 서버 연동 전, 내부 DB에서 공지사항을 불러옵니다.
    final stored = _box.get('company_notices', defaultValue: []);
    _notices = List<Map<String, dynamic>>.from(stored.map((e) => Map<String, dynamic>.from(e)));
    // 최신순 정렬
    _notices.sort((a, b) => DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])));
    setState(() {});
  }

  void _saveNotices() {
    _box.put('company_notices', _notices);
    _loadNotices();
  }

  // 🌟 공지사항 작성 팝업 (팀장/대표만 접근 가능)
  void _showNoticeDialog([int? index]) {
    final titleCtrl = TextEditingController(text: index != null ? _notices[index]['title'] : '');
    final contentCtrl = TextEditingController(text: index != null ? _notices[index]['content'] : '');

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, left: 20, right: 20, top: 20),
        decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(index == null ? '공지사항 작성' : '공지사항 수정', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: '공지 제목', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: contentCtrl,
                maxLines: 5,
                decoration: const InputDecoration(labelText: '공지 내용', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, padding: const EdgeInsets.symmetric(vertical: 16)),
                onPressed: () {
                  if (titleCtrl.text.trim().isEmpty || contentCtrl.text.trim().isEmpty) {
                    Get.snackbar('알림', '제목과 내용을 모두 입력해주세요.');
                    return;
                  }
                  
                  String authorName = _box.get('user_name', defaultValue: '관리자');

                  if (index == null) {
                    // 새 공지 추가
                    _notices.add({
                      'id': DateTime.now().millisecondsSinceEpoch.toString(),
                      'title': titleCtrl.text.trim(),
                      'content': contentCtrl.text.trim(),
                      'author': authorName,
                      'date': DateTime.now().toIso8601String(),
                      'views': 0, // 나중에 읽음 확인 기능에 쓸 변수
                    });
                  } else {
                    // 공지 수정
                    _notices[index]['title'] = titleCtrl.text.trim();
                    _notices[index]['content'] = contentCtrl.text.trim();
                  }
                  
                  _saveNotices();
                  Get.back();
                },
                child: const Text('공지 등록하기', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              )
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  void _deleteNotice(int index) {
    Get.defaultDialog(
      title: '삭제', middleText: '이 공지사항을 삭제하시겠습니까?', textConfirm: '삭제', textCancel: '취소',
      confirmTextColor: Colors.white, buttonColor: Colors.redAccent, cancelTextColor: Colors.black,
      onConfirm: () { _notices.removeAt(index); _saveNotices(); Get.back(); Get.back(); }
    );
  }

  // 공지사항 상세 보기 창
  void _showNoticeDetail(int index) {
    final notice = _notices[index];
    // 팀장이나 대표인 경우 삭제 버튼을 상단에 띄워줍니다.
    bool isAdmin = _userRole == '대표' || _userRole == '팀장';

    Get.to(() => Scaffold(
      appBar: AppBar(
        title: const Text('공지사항 상세', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (isAdmin) 
            IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: () => _deleteNotice(index)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notice['title'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(notice['author'] ?? '관리자', style: const TextStyle(color: Colors.grey)),
                const SizedBox(width: 15),
                const Icon(Icons.access_time, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(DateFormat('yyyy.MM.dd HH:mm').format(DateTime.parse(notice['date'])), style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const Divider(height: 40, thickness: 1),
            Text(notice['content'], style: const TextStyle(fontSize: 16, height: 1.6)),
          ],
        ),
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    // 🌟 관리자(대표, 팀장) 여부 체크
    bool isAdmin = _userRole == '대표' || _userRole == '팀장';

    return Scaffold(
      appBar: AppBar(title: const Text('사내 공지사항', style: TextStyle(fontWeight: FontWeight.bold)), centerTitle: true),
      body: _notices.isEmpty
          ? Center(
              child: Text(
                isAdmin ? '등록된 공지사항이 없습니다.\n우측 하단 버튼을 눌러 공지를 작성하세요.' : '새로운 공지사항이 없습니다.', 
                textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)
              )
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _notices.length,
              itemBuilder: (context, index) {
                final notice = _notices[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 2,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    leading: const CircleAvatar(backgroundColor: Color(0xFFFFEBEE), child: Icon(Icons.campaign, color: Colors.redAccent)),
                    title: Text(notice['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text('${notice['author']} | ${DateFormat('MM/dd').format(DateTime.parse(notice['date']))}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ),
                    onTap: () => _showNoticeDetail(index),
                  ),
                );
              },
            ),
      // 🌟 [핵심] 관리자(대표/팀장)에게만 글쓰기(FAB) 버튼이 보입니다!
      floatingActionButton: isAdmin 
        ? FloatingActionButton.extended(
            backgroundColor: Colors.redAccent,
            onPressed: () => _showNoticeDialog(),
            icon: const Icon(Icons.edit, color: Colors.white),
            label: const Text('공지 작성', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ) 
        : null, 
    );
  }
}