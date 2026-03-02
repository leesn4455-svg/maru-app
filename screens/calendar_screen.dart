// lib/screens/calendar_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';

import '../providers/work_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/calendar_header.dart';
import '../widgets/day_detail_modal.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});
  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();

  final Map<DateTime, String> _krHolidays = {
    DateTime(2025,1,1): "신정", DateTime(2025,1,28): "설연휴", DateTime(2025,1,29): "설날", DateTime(2025,1,30): "설연휴", DateTime(2025,3,1): "삼일절", DateTime(2025,3,3): "대체공휴일", DateTime(2025,5,5): "어린이날", DateTime(2025,5,6): "대체공휴일", DateTime(2025,5,27): "부처님오신날", DateTime(2025,6,6): "현충일", DateTime(2025,8,15): "광복절", DateTime(2025,10,3): "개천절", DateTime(2025,10,5): "추석연휴", DateTime(2025,10,6): "추석", DateTime(2025,10,7): "추석연휴", DateTime(2025,10,8): "대체공휴일", DateTime(2025,10,9): "한글날", DateTime(2025,12,25): "성탄절",
    DateTime(2026,1,1): "신정", DateTime(2026,2,16): "설연휴", DateTime(2026,2,17): "설날", DateTime(2026,2,18): "설연휴", DateTime(2026,3,1): "삼일절", DateTime(2026,3,2): "대체공휴일", DateTime(2026,5,5): "어린이날", DateTime(2026,5,24): "부처님오신날", DateTime(2026,5,25): "대체공휴일", DateTime(2026,6,6): "현충일", DateTime(2026,8,15): "광복절", DateTime(2026,8,17): "대체공휴일", DateTime(2026,9,24): "추석연휴", DateTime(2026,9,25): "추석", DateTime(2026,9,26): "추석연휴", DateTime(2026,9,28): "대체공휴일", DateTime(2026,10,3): "개천절", DateTime(2026,10,5): "대체공휴일", DateTime(2026,10,9): "한글날", DateTime(2026,12,25): "성탄절",
  };

  Widget _buildCalendarCell(DateTime day, {required Color textColor, bool isToday = false, bool isSelected = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final holidayName = _krHolidays.entries.firstWhere((e) => isSameDay(e.key, day), orElse: () => MapEntry(day, '')).value;
    
    return Container(
      decoration: BoxDecoration(border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[300]!, width: 0.5), color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : (isToday ? Colors.blue.withOpacity(0.05) : null)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 2),
          Center(child: Container(decoration: isToday ? const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle) : null, padding: isToday ? const EdgeInsets.all(4) : EdgeInsets.zero, child: Text('${day.day}', style: TextStyle(color: isToday ? Colors.white : textColor, fontSize: 13, fontWeight: isToday ? FontWeight.bold : FontWeight.normal)))),
          if (holidayName.isNotEmpty) Center(child: Text(holidayName, style: const TextStyle(color: Colors.redAccent, fontSize: 8, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  void _selectDateWithCupertino(bool isHeader) {
    showCupertinoModalPopup(
      context: context,
      builder: (_) => Container(
        height: 300, color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(children: [Container(decoration: BoxDecoration(color: Theme.of(context).cardColor, border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.3), width: 1))), child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [CupertinoButton(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), child: const Text('선택 완료', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF5A55F5))), onPressed: () => Get.back())])), Expanded(child: SafeArea(top: false, child: CupertinoDatePicker(initialDateTime: _focusedDay, mode: CupertinoDatePickerMode.date, onDateTimeChanged: (val) { setState(() { _focusedDay = val; if(!isHeader) _selectedDay = val; }); })))])
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final workRecords = ref.watch(workProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        CalendarHeader(focusedDay: _focusedDay),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0), child: Align(alignment: Alignment.centerLeft, child: Text(_selectedDay != null ? DateFormat('M월 d일 (E)', 'ko_KR').format(_selectedDay!) : '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: TableCalendar(
                locale: 'ko_KR', focusedDay: _focusedDay, firstDay: DateTime.utc(2020), lastDay: DateTime.utc(2030),
                sixWeekMonthsEnforced: true, 
                rowHeight: 45, 
                daysOfWeekHeight: 35,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onPageChanged: (focusedDay) => setState(() => _focusedDay = focusedDay),
                onHeaderTapped: (date) => _selectDateWithCupertino(true), 
                onDaySelected: (sDay, fDay) { setState(() { _selectedDay = sDay; _focusedDay = fDay; }); showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Theme.of(context).bottomSheetTheme.backgroundColor, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))), builder: (_) => DayDetailModal(selectedDate: sDay)); },
                headerStyle: HeaderStyle(formatButtonVisible: false, titleCentered: true, titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black), leftChevronIcon: Icon(Icons.chevron_left, color: isDark ? Colors.white : Colors.black), rightChevronIcon: Icon(Icons.chevron_right, color: isDark ? Colors.white : Colors.black)),
                calendarBuilders: CalendarBuilders(
                  dowBuilder: (context, day) { Color textColor = isDark ? Colors.white : Colors.black; if (day.weekday == DateTime.sunday) textColor = Colors.redAccent; if (day.weekday == DateTime.saturday) textColor = Colors.blue; return Container(decoration: BoxDecoration(border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[300]!, width: 0.5)), alignment: Alignment.center, child: Text(DateFormat.E('ko_KR').format(day), style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13))); },
                  defaultBuilder: (context, day, focusedDay) => _buildCalendarCell(day, textColor: (day.weekday == DateTime.sunday) ? Colors.redAccent : (day.weekday == DateTime.saturday ? Colors.blue : (isDark ? Colors.white : Colors.black))),
                  outsideBuilder: (context, day, focusedDay) => _buildCalendarCell(day, textColor: Colors.grey),
                  holidayBuilder: (context, day, focusedDay) => _buildCalendarCell(day, textColor: Colors.redAccent),
                  todayBuilder: (context, day, focusedDay) => _buildCalendarCell(day, textColor: isDark ? Colors.white : Colors.black, isToday: true),
                  selectedBuilder: (context, day, focusedDay) => _buildCalendarCell(day, textColor: isDark ? Colors.white : Colors.black, isSelected: true),
                  
                  markerBuilder: (context, day, events) {
                    final dayRecords = workRecords.where((r) => isSameDay(r.date, day) && !r.isSchedule).toList();
                    final daySchedules = workRecords.where((r) => isSameDay(r.date, day) && r.isSchedule).toList();
                    List<Widget> markers = [];
                    
                    for (var schedule in daySchedules) { markers.add(Container(width: double.infinity, margin: const EdgeInsets.only(bottom: 1), padding: const EdgeInsets.symmetric(vertical: 2), decoration: BoxDecoration(color: Colors.blueAccent.withOpacity(0.9), borderRadius: BorderRadius.circular(2)), child: Text(schedule.siteName, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis, textAlign: TextAlign.center))); }
                    for (var record in dayRecords) { markers.add(Container(width: double.infinity, margin: const EdgeInsets.only(bottom: 1), padding: const EdgeInsets.symmetric(vertical: 2), decoration: BoxDecoration(color: AppTheme.primaryColor.withOpacity(0.9), borderRadius: BorderRadius.circular(2)), child: Text('${record.siteName}(${record.workHours})', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis, textAlign: TextAlign.center))); }
                    
                    if (markers.isEmpty) return const SizedBox();
                    
                    // 🌟 [핵심 해결] 마커가 2개 이상일 때 달력 칸을 넘치지 않도록 +N건으로 요약합니다.
                    return Positioned(
                      bottom: 2, left: 2, right: 2,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          markers.first,
                          if (markers.length > 1)
                            Container(
                              margin: const EdgeInsets.only(top: 1),
                              padding: const EdgeInsets.symmetric(vertical: 1),
                              width: double.infinity,
                              decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(2)),
                              child: Text('+${markers.length - 1}건', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                            )
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}