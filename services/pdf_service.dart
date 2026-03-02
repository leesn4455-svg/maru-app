// lib/services/pdf_service.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; 
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:get/get.dart';

import '../models/app_models.dart';

class PdfService {
  static bool _isSameDate(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

  static Future<pw.Font> _getSafeKoreanFont(bool isBold) async {
    try {
      final url = isBold 
          ? 'https://raw.githubusercontent.com/google/fonts/main/ofl/nanumgothic/NanumGothic-Bold.ttf'
          : 'https://raw.githubusercontent.com/google/fonts/main/ofl/nanumgothic/NanumGothic-Regular.ttf';
      
      final request = await HttpClient().getUrl(Uri.parse(url));
      final response = await request.close();
      final bytes = await consolidateHttpClientResponseBytes(response);
      return pw.Font.ttf(bytes.buffer.asByteData());
    } catch (e) {
      throw Exception('폰트 다운로드 실패 (인터넷 연결을 확인하세요)');
    }
  }

  // 🌟 [수정] 캘린더 위젯 위에 'O년 O월 캘린더' 제목을 붙여서 여러 달이 나와도 구분이 가도록 복구!
  static pw.Widget _buildPdfCalendar(DateTime monthMonth, List<WorkRecord> records, pw.Font font, pw.Font boldFont) {
    final firstDay = DateTime(monthMonth.year, monthMonth.month, 1);
    final lastDay = DateTime(monthMonth.year, monthMonth.month + 1, 0);
    int startWeekday = firstDay.weekday; if (startWeekday == 7) startWeekday = 0; 
    
    List<pw.TableRow> rows = [];
    rows.add(pw.TableRow(children: ['일','월','화','수','목','금','토'].map((e) => pw.Container(alignment: pw.Alignment.center, padding: const pw.EdgeInsets.all(4), color: const PdfColor.fromInt(0xFF5A55F5), child: pw.Text(e, style: pw.TextStyle(font: boldFont, color: PdfColors.white, fontSize: 10)))).toList()));

    List<pw.Widget> currentRow = [];
    for (int i = 0; i < startWeekday; i++) {
      currentRow.add(pw.Container(decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300, width: 0.5))));
    }

    for (int i = 1; i <= lastDay.day; i++) {
      final currentDay = DateTime(monthMonth.year, monthMonth.month, i);
      final dailyRecords = records.where((r) => _isSameDate(r.date, currentDay)).toList();
      double dayHours = dailyRecords.fold(0.0, (sum, r) => sum + r.workHours);

      currentRow.add(
        pw.Container(
          height: 40,
          decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300, width: 0.5)),
          padding: const pw.EdgeInsets.all(2),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('$i', style: pw.TextStyle(font: font, fontSize: 8, color: currentDay.weekday == 7 ? PdfColors.red : PdfColors.black)),
              if (dayHours > 0)
                pw.Container(
                  margin: const pw.EdgeInsets.only(top: 2),
                  padding: const pw.EdgeInsets.symmetric(vertical: 1, horizontal: 2),
                  decoration: pw.BoxDecoration(color: const PdfColor.fromInt(0xFF5A55F5), borderRadius: pw.BorderRadius.circular(2)),
                  child: pw.Text('${dayHours}공수', style: pw.TextStyle(font: boldFont, fontSize: 7, color: PdfColors.white))
                )
            ]
          )
        )
      );

      if (currentRow.length == 7) {
        rows.add(pw.TableRow(children: currentRow)); currentRow = [];
      }
    }
    if (currentRow.isNotEmpty) {
      while (currentRow.length < 7) { currentRow.add(pw.Container(decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300, width: 0.5)))); }
      rows.add(pw.TableRow(children: currentRow));
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('${monthMonth.year}년 ${monthMonth.month}월 캘린더', style: pw.TextStyle(font: boldFont, fontSize: 14)),
        pw.SizedBox(height: 8),
        pw.Table(columnWidths: {for (var i in List.generate(7, (index) => index)) i: const pw.FlexColumnWidth()}, children: rows),
        pw.SizedBox(height: 20),
      ]
    );
  }

  static Future<void> generateAndSharePdf({required String periodText, required double totalHours, required int totalSalary, required int finalSalary, required List<WorkRecord> records, required AppSettings settings}) async {
    Get.dialog(const Center(child: CircularProgressIndicator(color: Colors.white)), barrierDismissible: false);

    try {
      pw.Font font; pw.Font boldFont;
      try {
        font = await _getSafeKoreanFont(false);
        boldFont = await _getSafeKoreanFont(true);
      } catch (e) {
        if (Get.isDialogOpen ?? false) Get.back(); 
        Get.snackbar('네트워크 오류', '정산서 폰트를 가져오기 위해 인터넷 연결이 필요합니다.', backgroundColor: Colors.redAccent, colorText: Colors.white);
        return;
      }

      // 🌟 [핵심] 일한 날짜를 바탕으로 캘린더를 그릴 월(Month) 추출 (1월, 2월 모두 나오게!)
      List<DateTime> months = [];
      for (var r in records) {
        DateTime m = DateTime(r.date.year, r.date.month, 1);
        if (!months.any((x) => x.year == m.year && x.month == m.month)) months.add(m);
      }
      months.sort();

      // 🌟 [핵심] 파일명 생성 (예: 2026년02월_정산내역.pdf)
      String filePrefix = '이번달';
      if (records.isNotEmpty) {
        DateTime latest = records.first.date; // 내림차순 정렬이므로 첫 번째가 가장 최근
        filePrefix = '${latest.year}년${latest.month.toString().padLeft(2, '0')}월';
      }

      final pdf = pw.Document();
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4, margin: const pw.EdgeInsets.all(30),
          build: (pw.Context context) {
            return [
              pw.Header(level: 0, child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('정산 내역서', style: pw.TextStyle(font: boldFont, fontSize: 24)), pw.Text(periodText, style: pw.TextStyle(font: font, fontSize: 12, color: PdfColors.grey700))])),
              pw.SizedBox(height: 10),
              pw.Container(
                padding: const pw.EdgeInsets.all(15), decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.circular(10)),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('근로자 성명:', style: pw.TextStyle(font: font)), pw.Text(settings.userName ?? '미입력', style: pw.TextStyle(font: boldFont))]), pw.SizedBox(height: 5),
                    pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('총 공수:', style: pw.TextStyle(font: font)), pw.Text('$totalHours 공수', style: pw.TextStyle(font: boldFont))]), pw.SizedBox(height: 5),
                    pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('세전 금액:', style: pw.TextStyle(font: font)), pw.Text('${NumberFormat('#,###').format(totalSalary)}원', style: pw.TextStyle(font: boldFont))]), pw.SizedBox(height: 5),
                    pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('세후 수령액:', style: pw.TextStyle(font: boldFont, fontSize: 14)), pw.Text('${NumberFormat('#,###').format(finalSalary)}원', style: pw.TextStyle(font: boldFont, fontSize: 16, color: const PdfColor.fromInt(0xFFFE3939)))]),
                  ]
                )
              ),
              pw.SizedBox(height: 20),

              // 🌟 [수정] 여러 달의 캘린더를 반복해서 그려줍니다!
              if (months.isNotEmpty) ...[
                pw.Text('월별 달력 요약', style: pw.TextStyle(font: boldFont, fontSize: 14)), 
                pw.SizedBox(height: 10),
                ...months.map((m) => _buildPdfCalendar(m, records, font, boldFont)).toList(),
              ],

              pw.Text('상세 근무 내역', style: pw.TextStyle(font: boldFont, fontSize: 14)), pw.SizedBox(height: 10),
              if (records.isEmpty) pw.Center(child: pw.Text('기록이 없습니다.', style: pw.TextStyle(font: font, color: PdfColors.grey)))
              else pw.TableHelper.fromTextArray(
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
      // 🌟 [수정] 요청하신 파일명 형식으로 변경 완료!
      await Printing.sharePdf(bytes: bytes, filename: '${filePrefix}_정산내역.pdf');
    } catch (e) {
      if (Get.isDialogOpen ?? false) Get.back(); 
      Get.snackbar('PDF 생성 오류', '문서 생성 중 문제가 발생했습니다: $e', backgroundColor: Colors.redAccent, colorText: Colors.white);
    }
  }
}