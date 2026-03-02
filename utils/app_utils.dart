// lib/utils/app_utils.dart
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/app_models.dart';

// 앱 전체에서 복사한 기록을 기억하는 임시 기억장치
WorkRecord? globalClipboardRecord;

// 금액에 콤마(,)를 찍어주는 포매터
class ThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue;
    int? value = int.tryParse(newValue.text.replaceAll(',', ''));
    if (value == null) return oldValue;
    final newText = NumberFormat('#,###').format(value);
    return TextEditingValue(text: newText, selection: TextSelection.collapsed(offset: newText.length));
  }
}