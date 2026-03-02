// lib/screens/site_manager_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

import '../models/app_models.dart';
import '../providers/site_provider.dart';

class SiteManagerScreen extends ConsumerStatefulWidget {
  const SiteManagerScreen({super.key});
  @override
  ConsumerState<SiteManagerScreen> createState() => _SiteManagerScreenState();
}

class _SiteManagerScreenState extends ConsumerState<SiteManagerScreen> {
  String _searchKeyword = "";

  @override
  Widget build(BuildContext context) {
    final sites = ref.watch(siteProvider);
    final filteredSites = sites.where((s) => s.siteName.toLowerCase().contains(_searchKeyword.toLowerCase()) || (s.memo?.toLowerCase().contains(_searchKeyword.toLowerCase()) ?? false)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('현장 정보 관리'), 
        actions: [
          IconButton(icon: const Icon(Icons.share), onPressed: () {
            if (filteredSites.isEmpty) return;
            String allText = filteredSites.map((s) => "현장명: ${s.siteName}\n주소: ${s.address}\n연락처: ${s.managerContact}\n---").join('\n');
            Share.share(allText);
          })
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: '현장 이름 검색...', prefixIcon: const Icon(Icons.search), filled: true, fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              ),
              onChanged: (val) => setState(() => _searchKeyword = val),
            ),
          ),
        ),
      ),
      body: filteredSites.isEmpty ? const Center(child: Text('검색 결과나 등록된 현장이 없습니다.')) : ListView.builder(
        padding: const EdgeInsets.all(16), itemCount: filteredSites.length,
        itemBuilder: (context, index) {
          final site = filteredSites[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ExpansionTile(
              title: Text(site.siteName, style: const TextStyle(fontWeight: FontWeight.bold)),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _row(Icons.map, '주소', site.address, isCopy: true),
                      _row(Icons.warehouse, '창고위치', site.warehouseLocation),
                      _row(Icons.meeting_room, '매니저실', site.managerOffice),
                      _row(Icons.door_front_door, '공동현관', site.commonEntrance ?? '없음'),
                      _row(Icons.phone, '담당자 연락처', site.managerContact, isPhone: true),
                      _row(Icons.note, '메모', site.memo ?? '없음'),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(onPressed: () {
                            String txt = "[Maru 현장 정보]\n현장명: ${site.siteName}\n주소: ${site.address}\n창고: ${site.warehouseLocation}\n매니저실: ${site.managerOffice}\n공동현관: ${site.commonEntrance ?? '없음'}\n연락처: ${site.managerContact}\n메모: ${site.memo ?? '없음'}";
                            Share.share(txt);
                          }, icon: const Icon(Icons.share, size: 16, color: Colors.blue), label: const Text('공유', style: TextStyle(color: Colors.blue))),
                          TextButton.icon(
                            onPressed: () { FocusScope.of(context).unfocus(); Future.delayed(const Duration(milliseconds: 150), () => _showAddSiteDialog(context, ref, site: site)); }, 
                            icon: const Icon(Icons.edit, size: 16), label: const Text('수정')
                          ),
                          TextButton.icon(onPressed: () => ref.read(siteProvider.notifier).deleteSite(site), icon: const Icon(Icons.delete, size: 16, color: Colors.red), label: const Text('삭제', style: TextStyle(color: Colors.red))),
                        ],
                      )
                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(backgroundColor: const Color(0xFF5A55F5), onPressed: () { FocusScope.of(context).unfocus(); Future.delayed(const Duration(milliseconds: 150), () => _showAddSiteDialog(context, ref)); }, child: const Icon(Icons.add, color: Colors.white)),
    );
  }

  Widget _row(IconData icon, String label, String value, {bool isPhone = false, bool isCopy = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF5A55F5)), const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)), Text(value, style: const TextStyle(fontSize: 14))])),
          if (isPhone) IconButton(icon: const Icon(Icons.call, color: Colors.green), onPressed: () => launchUrl(Uri.parse('tel:$value'))),
          if (isCopy) IconButton(icon: const Icon(Icons.copy, color: Colors.grey), onPressed: () { Clipboard.setData(ClipboardData(text: value)); Get.snackbar('복사', '내비게이션에 붙여넣으세요!'); }),
        ],
      ),
    );
  }

  void _showAddSiteDialog(BuildContext context, WidgetRef ref, {SiteInfo? site}) {
    final nameC = TextEditingController(text: site?.siteName);
    final addrC = TextEditingController(text: site?.address);
    final wareC = TextEditingController(text: site?.warehouseLocation);
    final offiC = TextEditingController(text: site?.managerOffice);
    final entC = TextEditingController(text: site?.commonEntrance);
    final phoneC = TextEditingController(text: site?.managerContact);
    final memoC = TextEditingController(text: site?.memo);

    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 20, left: 20, right: 20, top: 20),
        decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(site == null ? '현장 등록' : '현장 수정', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), const SizedBox(height: 15),
              TextField(controller: nameC, decoration: const InputDecoration(labelText: '현장명')), const SizedBox(height: 8),
              TextField(controller: addrC, decoration: const InputDecoration(labelText: '주소')), const SizedBox(height: 8),
              TextField(controller: wareC, decoration: const InputDecoration(labelText: '창고위치')), const SizedBox(height: 8),
              TextField(controller: offiC, decoration: const InputDecoration(labelText: '매니저실')), const SizedBox(height: 8),
              TextField(controller: entC, decoration: const InputDecoration(labelText: '공동현관 비밀번호')), const SizedBox(height: 8),
              TextField(controller: phoneC, decoration: const InputDecoration(labelText: '담당자 연락처')), const SizedBox(height: 8),
              TextField(controller: memoC, decoration: const InputDecoration(labelText: '메모')), const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF5A55F5), minimumSize: const Size(double.infinity, 55)), 
                onPressed: () {
                  if (nameC.text.isEmpty) return;
                  final newSite = SiteInfo(siteName: nameC.text, address: addrC.text, warehouseLocation: wareC.text, managerOffice: offiC.text, managerContact: phoneC.text, commonEntrance: entC.text, memo: memoC.text);
                  
                  // 🌟 [수정] Provider의 클라우드 동기화 시스템을 경유하도록 변경
                  if (site == null) {
                    ref.read(siteProvider.notifier).addSite(newSite);
                  } else { 
                    ref.read(siteProvider.notifier).updateSite(site.siteName, newSite); 
                  }
                  Get.back();
                },
                child: const Text('저장', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }
}