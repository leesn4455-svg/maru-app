// lib/providers/site_provider.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/app_models.dart';
import 'app_provider.dart';

class SiteInfoNotifier extends StateNotifier<List<SiteInfo>> {
  final Ref ref;
  StreamSubscription? _syncSubscription;
  final String _boxName = 'site_info';

  SiteInfoNotifier(this.ref) : super([]) {
    _loadSites();
    _initCloudSync(); // 🌟 앱 시작 시 클라우드 동기화 안테나 가동!
  }

  void _loadSites() {
    final box = Hive.box<SiteInfo>(_boxName);
    state = box.values.toList();
  }

  // 🌟 [핵심] Firestore 실시간 감시 시스템
  void _initCloudSync() {
    final companyCode = ref.read(appSettingsProvider).companyCode;
    
    // 회사 코드가 있는 사용자만 클라우드 동기화 활성화
    if (companyCode != null && companyCode.isNotEmpty) {
      _syncSubscription = FirebaseFirestore.instance
          .collection('companies')
          .doc(companyCode)
          .collection('sites')
          .snapshots()
          .listen((snapshot) async {
            
        final box = Hive.box<SiteInfo>(_boxName);
        await box.clear(); // 로컬 데이터를 비우고 클라우드 데이터로 완벽 동기화
        
        for (var doc in snapshot.docs) {
          final data = doc.data();
          await box.add(SiteInfo(
            siteName: data['siteName'] ?? '',
            address: data['address'] ?? '',
            warehouseLocation: data['warehouseLocation'] ?? '',
            managerOffice: data['managerOffice'] ?? '',
            managerContact: data['managerContact'] ?? '',
            commonEntrance: data['commonEntrance'],
            memo: data['memo'],
            parkingTip: data['parkingTip'],
            mapUrl: data['mapUrl'],
            companyCode: companyCode,
          ));
        }
        _loadSites(); // 화면 즉시 새로고침
      });
    }
  }

  Future<void> addSite(SiteInfo site) async {
    final companyCode = ref.read(appSettingsProvider).companyCode;
    if (companyCode != null && companyCode.isNotEmpty) {
      site.companyCode = companyCode;
      await FirebaseFirestore.instance.collection('companies').doc(companyCode).collection('sites').doc(site.siteName).set(_toMap(site));
    } else {
      // 회사 코드가 없는 개인 사용자는 기존처럼 로컬에만 저장
      await Hive.box<SiteInfo>(_boxName).add(site);
      _loadSites();
    }
  }

  Future<void> updateSite(String oldSiteName, SiteInfo site) async {
    final companyCode = ref.read(appSettingsProvider).companyCode;
    if (companyCode != null && companyCode.isNotEmpty) {
      site.companyCode = companyCode;
      // 현장명이 바뀌었을 수 있으므로 기존 이름의 문서는 삭제하고 새로 생성
      if (oldSiteName != site.siteName) {
        await FirebaseFirestore.instance.collection('companies').doc(companyCode).collection('sites').doc(oldSiteName).delete();
      }
      await FirebaseFirestore.instance.collection('companies').doc(companyCode).collection('sites').doc(site.siteName).set(_toMap(site));
    } else {
      final box = Hive.box<SiteInfo>(_boxName);
      final index = box.values.toList().indexWhere((s) => s.siteName == oldSiteName);
      if (index != -1) await box.putAt(index, site);
      _loadSites();
    }
  }

  Future<void> deleteSite(SiteInfo site) async {
    final companyCode = ref.read(appSettingsProvider).companyCode;
    if (companyCode != null && companyCode.isNotEmpty) {
      await FirebaseFirestore.instance.collection('companies').doc(companyCode).collection('sites').doc(site.siteName).delete();
    } else {
      final box = Hive.box<SiteInfo>(_boxName);
      final index = box.values.toList().indexWhere((s) => s.siteName == site.siteName);
      if (index != -1) await box.deleteAt(index);
      _loadSites();
    }
  }

  Map<String, dynamic> _toMap(SiteInfo s) => {
    'siteName': s.siteName, 'address': s.address, 'warehouseLocation': s.warehouseLocation,
    'managerOffice': s.managerOffice, 'managerContact': s.managerContact,
    'commonEntrance': s.commonEntrance, 'memo': s.memo, 'parkingTip': s.parkingTip, 'mapUrl': s.mapUrl,
  };

  @override
  void dispose() {
    _syncSubscription?.cancel();
    super.dispose();
  }
}

// 🌟 [수정] Provider가 ref에 접근할 수 있도록 연결
final siteProvider = StateNotifierProvider<SiteInfoNotifier, List<SiteInfo>>((ref) => SiteInfoNotifier(ref));