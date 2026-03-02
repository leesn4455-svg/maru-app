// lib/utils/date_calculator.dart
import 'package:flutter/material.dart';

class DateCalculator {
  /// 설정한 정산 시작일(startDay)을 기준으로 정산 기간을 계산합니다.
  static DateTimeRange getSettlementPeriod(DateTime targetMonth, int startDay) {
    DateTime startDate;
    DateTime endDate;

    if (startDay == 1) {
      // 🌟 [해결 1] 1일 시작인 경우: 이번 달 1일 ~ 말일 (30일, 31일 등 없는 일자 자동 계산됨)
      startDate = DateTime(targetMonth.year, targetMonth.month, 1);
      endDate = DateTime(targetMonth.year, targetMonth.month + 1, 0); 
    } else {
      // 26일 등 특정일 시작: 이전 달 26일 ~ 이번 달 25일
      startDate = DateTime(targetMonth.year, targetMonth.month - 1, startDay);
      endDate = DateTime(targetMonth.year, targetMonth.month, startDay - 1);
    }

    return DateTimeRange(start: startDate, end: endDate);
  }

  /// 🌟 [해결 2] 시간, 분, 초 단위로 인해 하루 전날(25일)이 딸려오는 현상을 막기 위한 안전한 비교 함수
  static bool isDateInRange(DateTime target, DateTime start, DateTime end) {
    final t = DateTime(target.year, target.month, target.day);
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day);
    return t.compareTo(s) >= 0 && t.compareTo(e) <= 0;
  }
}