// lib/screens/site_info_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

import '../models/app_models.dart';
import '../providers/site_provider.dart'; // 🌟 클라우드 안테나 연결

// 🌟 ConsumerStatefulWidget으로 변경!
class SiteInfoScreen extends ConsumerStatefulWidget {
  const SiteInfoScreen({super.key});
  @override
  ConsumerState<SiteInfoScreen> createState() => _SiteInfoScreenState();
}

class _SiteInfoScreenState extends ConsumerState<SiteInfoScreen> {
  String _searchQuery = '';

  void _showSiteModal([SiteInfo? existingSite]) {
    final nameC = TextEditingController(text: existingSite?.siteName);
    final addressC = TextEditingController(text: existingSite?.address);
    final warehouseC = TextEditingController(text: existingSite?.warehouseLocation);
    final managerC = TextEditingController(text: existingSite?.managerOffice);
    final contactC = TextEditingController(text: existingSite?.managerContact);
    final entranceC = TextEditingController(text: existingSite?.commonEntrance);
    final memoC = TextEditingController(text: existingSite?.memo);
    final parkingC = TextEditingController(text: existingSite?.parkingTip);
    final mapUrlC = TextEditingController(text: existingSite?.mapUrl);

    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.90),
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(existingSite == null ? '새 현장 정보 추가' : '현장 정보 수정', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                TextField(controller: nameC, decoration: const InputDecoration(labelText: '현장명 (필수)', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: addressC, decoration: const InputDecoration(labelText: '주소', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: mapUrlC, decoration: const InputDecoration(labelText: '지도 앱 공유 링크 붙여넣기 (선택)', hintText: '예: https://kko.to/..., https://naver.me/...', border: OutlineInputBorder())),
                const SizedBox(height: 5),
                const Align(alignment: Alignment.centerLeft, child: Text(' * 네이버/카카오 지도에서 복사한 링크를 넣으면 내비게이션이 정확히 연결됩니다.', style: TextStyle(fontSize: 11, color: Colors.grey))),
                const SizedBox(height: 10),
                TextField(controller: parkingC, decoration: const InputDecoration(labelText: '주차 꿀팁', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: warehouseC, decoration: const InputDecoration(labelText: '창고 위치', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: managerC, decoration: const InputDecoration(labelText: '매니저실 위치', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: contactC, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: '연락처', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: entranceC, decoration: const InputDecoration(labelText: '공동현관 비밀번호', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: memoC, maxLines: 5, decoration: const InputDecoration(labelText: '기타 메모', alignLabelWithHint: true, border: OutlineInputBorder())),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: const Color(0xFF5A55F5)),
                  onPressed: () {
                    if (nameC.text.isEmpty) return;
                    final newSite = SiteInfo(
                      siteName: nameC.text, address: addressC.text, warehouseLocation: warehouseC.text,
                      managerOffice: managerC.text, managerContact: contactC.text, commonEntrance: entranceC.text, memo: memoC.text,
                      parkingTip: parkingC.text, mapUrl: mapUrlC.text,
                    );
                    
                    // 🌟 [클라우드 연동] 로컬 직접 조작 대신 안테나를 통해 명령 전송!
                    if (existingSite == null) { 
                      ref.read(siteProvider.notifier).addSite(newSite); 
                    } else { 
                      ref.read(siteProvider.notifier).updateSite(existingSite.siteName, newSite); 
                    }
                    Get.back(); 
                  },
                  child: const Text('저장하기', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) { await launchUrl(launchUri); } else { Get.snackbar('오류', '전화를 걸 수 없습니다.'); }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    Get.snackbar('복사 완료', '$label 복사되었습니다.', snackPosition: SnackPosition.BOTTOM);
  }

  void _shareSiteInfo(SiteInfo site) {
    String text = '[${site.siteName} 현장 정보]\n';
    if (site.address.isNotEmpty) text += '📍 주소: ${site.address}\n';
    if (site.parkingTip?.isNotEmpty ?? false) text += '🚗 주차: ${site.parkingTip}\n';
    if (site.mapUrl?.isNotEmpty ?? false) text += '🗺️ 지도: ${site.mapUrl}\n';
    if (site.warehouseLocation.isNotEmpty) text += '🏢 창고: ${site.warehouseLocation}\n';
    if (site.managerOffice.isNotEmpty) text += '👨‍💼 매니저실: ${site.managerOffice}\n';
    if (site.managerContact.isNotEmpty) text += '📞 연락처: ${site.managerContact}\n';
    if (site.commonEntrance?.isNotEmpty ?? false) text += '🔑 공동현관: ${site.commonEntrance}\n';
    if (site.memo?.isNotEmpty ?? false) text += '📝 메모: ${site.memo}';
    Share.share(text);
  }

  Future<void> _openNavi(SiteInfo site) async {
    if (site.mapUrl != null && site.mapUrl!.startsWith('http')) {
      final url = Uri.parse(site.mapUrl!);
      try { await launchUrl(url, mode: LaunchMode.externalApplication); return; } 
      catch (e) { try { await launchUrl(url, mode: LaunchMode.inAppBrowserView); return; } catch (e2) { Get.snackbar('오류', '해당 링크를 열 수 있는 앱이 없습니다.'); return; } }
    }
    if (site.address.isNotEmpty) {
      final url = Uri.parse('https://map.kakao.com/link/search/${Uri.encodeComponent(site.address)}');
      try { await launchUrl(url, mode: LaunchMode.externalApplication); } catch (e) { Get.snackbar('오류', '내비게이션을 실행할 수 없습니다.'); }
    } else { Get.snackbar('알림', '길안내를 위해 주소나 지도 공유 링크를 입력해주세요.'); }
  }

  @override
  Widget build(BuildContext context) {
    // 🌟 [동기화 감지] 파이어베이스에서 변경되면 화면이 자동으로 리프레시 됩니다!
    final sites = ref.watch(siteProvider);
    final filteredSites = sites.where((e) => e.siteName.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('현장 정보 관리', style: TextStyle(fontWeight: FontWeight.bold)), centerTitle: true),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(decoration: InputDecoration(hintText: '현장명 검색...', prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)), filled: true, fillColor: Theme.of(context).cardColor), onChanged: (val) => setState(() => _searchQuery = val)),
          ),
          Expanded(
            child: filteredSites.isEmpty ? const Center(child: Text('등록된 현장 정보가 없습니다.')) : ListView.builder(
              itemCount: filteredSites.length,
              itemBuilder: (context, index) {
                final site = filteredSites[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ExpansionTile(
                    title: Text(site.siteName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF5A55F5))), subtitle: Text(site.address),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _infoRow('주소', site.address, onCopy: () => _copyToClipboard(site.address, '주소가')),
                            if (site.parkingTip?.isNotEmpty ?? false) _infoRow('주차 꿀팁', site.parkingTip!),
                            if (site.mapUrl?.isNotEmpty ?? false) _infoRow('지도 링크', '등록됨 (내비게이션 버튼을 누르세요)'),
                            _infoRow('창고 위치', site.warehouseLocation), _infoRow('매니저실 위치', site.managerOffice),
                            _infoRow('연락처', site.managerContact, onCall: () => _makePhoneCall(site.managerContact)),
                            if (site.commonEntrance?.isNotEmpty ?? false) _infoRow('공동현관', site.commonEntrance!),
                            if (site.memo?.isNotEmpty ?? false) _infoRow('메모', site.memo!),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                ElevatedButton.icon(onPressed: () => _openNavi(site), icon: const Icon(Icons.navigation, size: 16, color: Colors.white), label: const Text('내비게이션', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), style: ElevatedButton.styleFrom(backgroundColor: Colors.green)),
                                const Spacer(),
                                IconButton(icon: const Icon(Icons.share, color: Colors.blueAccent), onPressed: () => _shareSiteInfo(site)),
                                IconButton(icon: const Icon(Icons.edit, color: Colors.grey), onPressed: () => _showSiteModal(site)), // 🌟 수정 버튼
                                IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => ref.read(siteProvider.notifier).deleteSite(site)), // 🌟 삭제 버튼 연동
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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(backgroundColor: const Color(0xFF5A55F5), onPressed: () => _showSiteModal(), child: const Icon(Icons.add, color: Colors.white)),
    );
  }

  Widget _infoRow(String title, String content, {VoidCallback? onCopy, VoidCallback? onCall}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text(title, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold))),
          Expanded(child: Text(content)),
          if (onCall != null) GestureDetector(onTap: onCall, child: const Icon(Icons.phone, size: 20, color: Colors.green)),
          if (onCall != null) const SizedBox(width: 10),
          if (onCopy != null) GestureDetector(onTap: onCopy, child: const Icon(Icons.copy, size: 20, color: Colors.blueAccent)),
        ],
      ),
    );
  }
}