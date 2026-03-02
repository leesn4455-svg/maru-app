// lib/screens/site_list_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class SiteListScreen extends StatefulWidget {
  const SiteListScreen({super.key});
  @override
  State<SiteListScreen> createState() => _SiteListScreenState();
}

class _SiteListScreenState extends State<SiteListScreen> {
  List<dynamic> sites = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchSites();
  }

  Future<void> _fetchSites() async {
    setState(() => isLoading = true);
    final data = await ApiService.getSites(); // 서버에서 실시간 현장 목록 가져오기
    setState(() {
      sites = data;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text('통합 현장 정보', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black), onPressed: () => Get.back()),
        actions: [IconButton(icon: const Icon(Icons.refresh, color: Colors.black), onPressed: _fetchSites)],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sites.length,
              itemBuilder: (context, index) {
                final site = sites[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade300)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.business, color: AppTheme.primaryColor, size: 20),
                            const SizedBox(width: 8),
                            Text(site['site_name'] ?? '현장명 없음', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const Divider(height: 20, thickness: 1),
                        if (site['address'] != null && site['address'].toString().isNotEmpty)
                          Padding(padding: const EdgeInsets.only(bottom: 4), child: Text('📍 주소: ${site['address']}')),
                        if (site['contact'] != null && site['contact'].toString().isNotEmpty)
                          Padding(padding: const EdgeInsets.only(bottom: 4), child: Text('📞 연락처: ${site['contact']}')),
                        if (site['entrance_pw'] != null && site['entrance_pw'].toString().isNotEmpty)
                          Padding(padding: const EdgeInsets.only(bottom: 4), child: Text('🔐 공동현관: ${site['entrance_pw']}', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))),
                        if (site['memo'] != null && site['memo'].toString().isNotEmpty)
                          Padding(padding: const EdgeInsets.only(top: 8), child: Container(padding: const EdgeInsets.all(8), width: double.infinity, decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)), child: Text('📝 메모: ${site['memo']}', style: const TextStyle(color: Colors.black87)))),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}