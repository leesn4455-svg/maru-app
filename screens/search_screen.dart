// lib/screens/search_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/work_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});
  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) { 
    final allRecords = ref.watch(workProvider);
    final filtered = allRecords.where((r) => 
      r.siteName.toLowerCase().contains(_searchQuery.toLowerCase()) || 
      // [에러 해결] 메모가 Null일 경우 빈 글자로 치환하여 에러 방어!
      (r.memo ?? '').toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          decoration: const InputDecoration(hintText: '현장명 또는 메모 검색...', border: InputBorder.none),
          onChanged: (val) => setState(() => _searchQuery = val),
        ),
      ),
      body: _searchQuery.isEmpty 
        ? const Center(child: Text('검색어를 입력하세요.', style: TextStyle(color: Colors.grey)))
        : ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final r = filtered[index];
              return ListTile(
                leading: CircleAvatar(backgroundColor: const Color(0xFF5A55F5).withValues(alpha: 0.1), child: const Icon(Icons.search, color: Color(0xFF5A55F5))),
                title: Text('${DateFormat('yyyy년 MM월 dd일').format(r.date)} | ${r.siteName}'),
                // [에러 해결] isEmpty 검사 시 Null 방어!
                subtitle: Text('단가: ${NumberFormat('#,###').format(r.dailyWage)}원 | 메모: ${(r.memo?.isEmpty ?? true) ? '없음' : r.memo}'),
                trailing: Text('${r.workHours}공수', style: const TextStyle(fontWeight: FontWeight.bold)),
              );
            },
          ),
    );
  }
}