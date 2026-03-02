// lib/screens/statistics_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart'; 
import 'package:get/get.dart';

import '../providers/work_provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import '../services/pdf_service.dart';
import '../utils/date_calculator.dart'; // 🌟 유틸리티 추가

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});
  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> {
  DateTime _currentMonth = DateTime.now();
  final List<Color> pieColors = [AppTheme.primaryColor, Colors.orangeAccent, Colors.greenAccent, Colors.redAccent, Colors.lightBlueAccent, Colors.purpleAccent, Colors.amber];

  void _showMonthYearPicker() {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 300, color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          children: [
            SizedBox(height: 220, child: CupertinoDatePicker(mode: CupertinoDatePickerMode.monthYear, initialDateTime: _currentMonth, onDateTimeChanged: (DateTime newDate) => setState(() => _currentMonth = newDate))),
            CupertinoButton(child: const Text('확인', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), onPressed: () => Get.back())
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final workRecords = ref.watch(workProvider);
    final appSettings = ref.watch(appSettingsProvider);

    // 🌟 [핵심 수정] 계산기 유틸리티를 활용하여 기간을 정확하게 산출
    final period = DateCalculator.getSettlementPeriod(_currentMonth, appSettings.settlementStartDay);
    final startDate = period.start;
    final endDate = period.end;

    final periodText = '${startDate.month}월 ${startDate.day}일 ~ ${endDate.month}월 ${endDate.day}일';
    
    // 🌟 [핵심 수정] 시간값이 섞여 25일이 딸려오던 버그를 isDateInRange 로 차단
    final periodRecords = workRecords.where((r) => !r.isSchedule && DateCalculator.isDateInRange(r.date, startDate, endDate)).toList();
    periodRecords.sort((a, b) => b.date.compareTo(a.date));

    double totalHours = 0; int totalSalary = 0;
    Map<String, double> siteHoursMap = {}; Map<String, int> siteSalaryMap = {};
    for (var r in periodRecords) { 
      totalHours += r.workHours; int daySalary = (r.dailyWage * r.workHours).toInt(); totalSalary += daySalary; 
      siteHoursMap[r.siteName] = (siteHoursMap[r.siteName] ?? 0) + r.workHours; siteSalaryMap[r.siteName] = (siteSalaryMap[r.siteName] ?? 0) + daySalary;
    }

    var sortedEntries = siteHoursMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    var sortedSalaryEntries = siteSalaryMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    double taxRate = double.tryParse(appSettings.taxType) ?? 0.0;
    int finalSalary = (totalSalary * (1 - (taxRate / 100))).toInt();

    return Scaffold(
      appBar: AppBar(
        title: const Text('통계 및 정산 내역'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.redAccent, size: 28),
            tooltip: '청구서 PDF 생성',
            onPressed: () => PdfService.generateAndSharePdf(periodText: periodText, totalHours: totalHours, totalSalary: totalSalary, finalSalary: finalSalary, records: periodRecords, settings: appSettings),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! > 0) { setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1)); } else if (details.primaryVelocity! < 0) { setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1)); }
        },
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1))),
                GestureDetector(onTap: _showMonthYearPicker, child: Text(DateFormat('yyyy년 MM월').format(_currentMonth), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, decoration: TextDecoration.underline, decorationColor: Colors.grey))),
                IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1))),
              ],
            ),
            
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    if (sortedEntries.isNotEmpty)
                      Container(
                        height: 180, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround, maxY: sortedEntries.first.value + 2, 
                            barTouchData: BarTouchData(
                              enabled: true, 
                              touchTooltipData: BarTouchTooltipData(getTooltipColor: (group) => AppTheme.primaryColor, getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem('${rod.toY}공수', const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                            ),
                            titlesData: FlTitlesData(
                              leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)), topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (double value, TitleMeta meta) { return Padding(padding: const EdgeInsets.only(top: 8.0), child: Text(sortedEntries[value.toInt()].key, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))); })),
                            ),
                            gridData: const FlGridData(show: false), borderData: FlBorderData(show: false),
                            barGroups: sortedEntries.asMap().entries.map((entry) {
                              return BarChartGroupData(x: entry.key, barRods: [BarChartRodData(toY: entry.value.value, color: AppTheme.primaryColor, width: 20, borderRadius: BorderRadius.circular(4))], showingTooltipIndicators: []);
                            }).toList(),
                          ),
                        ),
                      )
                    else
                      const Padding(padding: EdgeInsets.all(20), child: Text('이번 달 완료된 기록이 없습니다.', style: TextStyle(color: Colors.grey))),

                    if (sortedSalaryEntries.isNotEmpty && totalSalary > 0)
                      Container(
                        height: 150, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                        child: Row(
                          children: [
                            Expanded(flex: 2, child: PieChart(PieChartData(sectionsSpace: 2, centerSpaceRadius: 35, sections: sortedSalaryEntries.asMap().entries.map((entry) { final color = pieColors[entry.key % pieColors.length]; final double percentage = (entry.value.value / totalSalary) * 100; return PieChartSectionData(color: color, value: entry.value.value.toDouble(), title: '${percentage.toStringAsFixed(1)}%', radius: 40, titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)); }).toList()))),
                            Expanded(flex: 1, child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: sortedSalaryEntries.take(4).toList().asMap().entries.map((entry) { final color = pieColors[entry.key % pieColors.length]; return Padding(padding: const EdgeInsets.symmetric(vertical: 2.0), child: Row(children: [Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), const SizedBox(width: 6), Expanded(child: Text(entry.value.key, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis))])); }).toList()))
                          ],
                        ),
                      ),

                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(15), border: Border.all(color: AppTheme.primaryColor.withOpacity(0.5))),
                      child: Column(
                        children: [
                          Text('$periodText 총 $totalHours 공수', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor, fontSize: 16)),
                          const Divider(),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('세전 총액', style: TextStyle(color: Colors.grey)), Text('${NumberFormat('#,###').format(totalSalary)}원', style: const TextStyle(fontSize: 18))]),
                          const SizedBox(height: 8),
                          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('세후 수령액 (공제 $taxRate%)', style: const TextStyle(fontWeight: FontWeight.bold)), Text('${NumberFormat('#,###').format(finalSalary)}원', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.redAccent))]),
                        ],
                      ),
                    ),
                    
                    ListView.builder(
                      shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                      itemCount: periodRecords.length,
                      itemBuilder: (context, index) {
                        final r = periodRecords[index];
                        return ListTile(
                          title: Text('${DateFormat('MM/dd').format(r.date)} | ${r.siteName}'),
                          subtitle: Text('${r.workHours}공수 x ${NumberFormat('#,###').format(r.dailyWage)}원'),
                          trailing: Text('${NumberFormat('#,###').format((r.workHours * r.dailyWage).toInt())}원', style: const TextStyle(fontWeight: FontWeight.bold)),
                        );
                      },
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}