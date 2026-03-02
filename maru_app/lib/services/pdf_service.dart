// lib/services/pdf_service.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:get/get.dart';

import '../models/app_models.dart';

class PdfService {
  static bool _isSameDate(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  // 캘린더 그리기 함수 (높이를 살짝 조절해서 한 페이지에 잘 들어가게 다듬었습니다)
  static pw.Widget _buildPdfCalendar(DateTime monthMonth, List<WorkRecord> records, pw.Font font, pw.Font boldFont) {
    final firstDay = DateTime(monthMonth.year, monthMonth.month, 1);
    final lastDay = DateTime(monthMonth.year, monthMonth.month + 1, 0);
    int startWeekday = firstDay.weekday; if (startWeekday == 7) startWeekday = 0; 
    
    List<pw.TableRow> rows = [];
    rows.add(pw.TableRow(children: ['일','월','화','수','목','금','토'].map((e) => pw.Container(alignment: pw.Alignment.center, padding: const pw.EdgeInsets.all(4), color: PdfColors.grey300, child: pw.Text(e, style: pw.TextStyle(font: boldFont, fontSize: 10)))).toList()));
    
    List<pw.Widget> currentRow = [];
    for (int i = 0; i < startWeekday; i++) {
      currentRow.add(pw.Container(decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400, width: 0.5))));
    }
    
    for (int i = 1; i <= lastDay.day; i++) {
      DateTime currentDate = DateTime(monthMonth.year, monthMonth.month, i);
      var dayRecords = records.where((r) => _isSameDate(r.date, currentDate)).toList();
      pw.Widget cell = pw.Container(
        height: 40, decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400, width: 0.5)), padding: const pw.EdgeInsets.all(2),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text('$i', style: pw.TextStyle(font: font, fontSize: 8, color: (currentRow.length == 0) ? PdfColors.red : (currentRow.length == 6 ? PdfColors.blue : PdfColors.black))),
            ...dayRecords.map((r) => pw.Container(margin: const pw.EdgeInsets.only(top: 1), padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 1), decoration: pw.BoxDecoration(color: PdfColor.fromInt(0xFF5A55F5), borderRadius: pw.BorderRadius.circular(2)), child: pw.Text('${r.siteName}\n(${r.workHours})', style: pw.TextStyle(font: boldFont, fontSize: 6, color: PdfColors.white)))).take(2), 
          ]
        )
      );
      currentRow.add(cell);
      if (currentRow.length == 7) { rows.add(pw.TableRow(children: currentRow)); currentRow = []; }
    }
    
    if (currentRow.isNotEmpty) {
      while (currentRow.length < 7) { currentRow.add(pw.Container(decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400, width: 0.5)))); }
      rows.add(pw.TableRow(children: currentRow));
    }
    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text('${monthMonth.year}년 ${monthMonth.month}월 캘린더', style: pw.TextStyle(font: boldFont, fontSize: 12)), 
      pw.SizedBox(height: 5), 
      pw.Table(children: rows), 
      pw.SizedBox(height: 15)
    ]);
  }

  static Future<void> generateAndSharePdf({required String periodText, required double totalHours, required int totalSalary, required int finalSalary, required List<WorkRecord> records, required AppSettings settings}) async {
    try {
      Get.dialog(const Center(child: CircularProgressIndicator()), barrierDismissible: false);
      
      ByteData fontData;
      ByteData boldData;
      try {
        fontData = await rootBundle.load("assets/fonts/NanumGothic-Regular.ttf");
        boldData = await rootBundle.load("assets/fonts/NanumGothic-Bold.ttf");
      } catch (e) {
        throw Exception("assets/fonts/ 폴더에 폰트 파일이 없거나 파일명이 다릅니다.");
      }
      
      final font = pw.Font.ttf(fontData);
      final boldFont = pw.Font.ttf(boldData);
      
      // 일한 날짜를 바탕으로 캘린더를 그릴 월(Month) 추출 (예: 1월, 2월)
      List<DateTime> months = [];
      for (var r in records) {
        DateTime m = DateTime(r.date.year, r.date.month, 1);
        if (!months.any((x) => x.year == m.year && x.month == m.month)) months.add(m);
      }
      months.sort();

      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return [
              // 1. 헤더 영역
              pw.Center(child: pw.Text('청 구 서', style: pw.TextStyle(font: boldFont, fontSize: 28))),
              pw.SizedBox(height: 20),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [pw.Text('청 구 자 : ${settings.userName ?? "작업자"}', style: pw.TextStyle(font: font, fontSize: 12)), pw.Text('연 락 처 : ${settings.phoneNumber ?? "미등록"}', style: pw.TextStyle(font: font, fontSize: 12))]), pw.Text('청구기간: $periodText', style: pw.TextStyle(font: font, fontSize: 12, color: PdfColors.grey700))]),
              pw.SizedBox(height: 15), pw.Divider(), pw.SizedBox(height: 10),
              
              // 2. 급여 요약 영역
              pw.Container(
                padding: const pw.EdgeInsets.all(12), decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.circular(8)),
                child: pw.Column(children: [
                  pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('총 인정 공수:', style: pw.TextStyle(font: font, fontSize: 14)), pw.Text('$totalHours 공수', style: pw.TextStyle(font: boldFont, fontSize: 14))]), pw.SizedBox(height: 5),
                  pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('세전 총액:', style: pw.TextStyle(font: font, fontSize: 14)), pw.Text('${NumberFormat('#,###').format(totalSalary)}원', style: pw.TextStyle(font: font, fontSize: 14))]), pw.SizedBox(height: 10), pw.Divider(color: PdfColors.grey400), pw.SizedBox(height: 10),
                  pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('최종 청구 금액 (세후):', style: pw.TextStyle(font: boldFont, fontSize: 16)), pw.Text('${NumberFormat('#,###').format(finalSalary)}원', style: pw.TextStyle(font: boldFont, fontSize: 16, color: PdfColors.red700))])
                ])
              ),
              pw.SizedBox(height: 20),
              
              // 🌟 3. 월별 캘린더 영역 (급여 요약과 상세 내역 사이에 삽입!)
              if (months.isNotEmpty) ...[
                pw.Text('월별 상세 캘린더', style: pw.TextStyle(font: boldFont, fontSize: 14)),
                pw.SizedBox(height: 10),
                // 추출된 월 개수만큼 캘린더를 연속해서 그려줍니다.
                ...months.map((m) => _buildPdfCalendar(m, records, font, boldFont)).toList(),
                pw.SizedBox(height: 10),
              ],
              
              // 4. 상세 근무 내역 영역
              pw.Text('상세 근무 내역', style: pw.TextStyle(font: boldFont, fontSize: 14)),
              pw.SizedBox(height: 8),
              if (records.isEmpty) pw.Text('해당 기간에 완료된 근무 내역이 없습니다.', style: pw.TextStyle(font: font, fontSize: 12, color: PdfColors.grey))
              else
                pw.TableHelper.fromTextArray(
                  context: context, cellStyle: pw.TextStyle(font: font, fontSize: 10), headerStyle: pw.TextStyle(font: boldFont, fontSize: 10, color: PdfColors.white), headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF5A55F5)), cellAlignment: pw.Alignment.center,
                  data: <List<String>>[
                    ['일자', '현장명', '공수', '단가', '일당 금액'],
                    ...records.map((r) => [DateFormat('MM/dd').format(r.date), r.siteName, r.workHours.toString(), '${NumberFormat('#,###').format(r.dailyWage)}원', '${NumberFormat('#,###').format((r.workHours * r.dailyWage).toInt())}원']),
                  ],
                ),
              pw.SizedBox(height: 20), pw.Center(child: pw.Text('위 금액을 정히 청구합니다.', style: pw.TextStyle(font: font, fontSize: 14))), pw.SizedBox(height: 20),
              pw.Align(alignment: pw.Alignment.centerRight, child: pw.Text('(인 / 서명)  ____________________', style: pw.TextStyle(font: font, fontSize: 14))),
            ];
          },
        ),
      );

      final bytes = await pdf.save();
      if (Get.isDialogOpen ?? false) Get.back(); 
      await Printing.sharePdf(bytes: bytes, filename: 'Maru_청구서_$periodText.pdf');
      
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar('PDF 생성 실패', '오류: $e', backgroundColor: Colors.redAccent, colorText: Colors.white, duration: const Duration(seconds: 5));
    }
  }
}