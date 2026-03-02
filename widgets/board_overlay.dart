// lib/widgets/board_overlay.dart
import 'package:flutter/material.dart';

class BoardOverlay extends StatelessWidget {
  final List<Map<String, dynamic>> fields;

  const BoardOverlay({super.key, required this.fields});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Table(
        defaultColumnWidth: const IntrinsicColumnWidth(),
        // 🌟 [피드백 4 반영] 사진에 박히는 보드판은 원래대로 얇고 일정한 선(1.0)으로 복구
        border: TableBorder.all(color: Colors.black, width: 1.0),
        children: List.generate(fields.length, (index) {
          return TableRow(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                alignment: Alignment.center,
                child: Text(
                  fields[index]['label'], 
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black)
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                alignment: Alignment.centerLeft,
                child: Text(
                  fields[index]['value'], 
                  style: const TextStyle(fontSize: 13, color: Colors.black, fontWeight: FontWeight.bold)
                ),
              )
            ],
          );
        }),
      ),
    );
  }
}