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
        // 글씨 길이에 맞춰 넓이가 완벽하게 타이트해집니다!
        defaultColumnWidth: const IntrinsicColumnWidth(),
        border: TableBorder.all(color: Colors.black, width: 1.0),
        children: List.generate(fields.length, (index) {
          return TableRow(
            children: [
              // 라벨 영역
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                alignment: Alignment.center,
                child: Text(
                  fields[index]['label'], 
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black)
                ),
              ),
              // 내용 영역
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