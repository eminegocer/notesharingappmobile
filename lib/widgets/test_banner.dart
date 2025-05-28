import 'package:flutter/material.dart';

class TestBanner extends StatelessWidget {
  final VoidCallback onStartTest;

  const TestBanner({Key? key, required this.onStartTest}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FDCB),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.yellow.withOpacity(0.13),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Metinler
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "Sana Özel İhtiyacın Olan Notları Bulmak İster Misin?",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF222B45),
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  "Kısa bir test çözerek sana en uygun notları keşfet!",
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF6B7FD7),
                  ),
                ),
              ],
            ),
          ),
          // Buton
          ElevatedButton(
            onPressed: onStartTest,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD600),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              elevation: 2,
            ),
            child: const Text(
              "Teste Başla",
              style: TextStyle(
                color: Color(0xFF222B45),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 