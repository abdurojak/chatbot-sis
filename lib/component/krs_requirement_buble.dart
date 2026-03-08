import 'package:chatbot/guardianship.dart';
import 'package:flutter/material.dart';
import 'package:chatbot/component/chat_helper.dart';

class KrsRequirementBubble extends StatelessWidget {
  final List<KrsRequirement> items;

  const KrsRequirementBubble({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final total = items.length;
    final passed = items.where((e) => e.status == 1).length;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFEAF1FF),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.assignment_turned_in,
                  size: 18,
                  color: Color(0xFF1E73BE),
                ),
                const SizedBox(width: 6),
                Text(
                  'Status Persyaratan KRS ($passed/${items.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E73BE),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            ...items.map((e) {
              final done = e.status == 1;
              final isPerwalian =
                  e.description.trim().toLowerCase() == 'belum perwalian';

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      done ? Icons.check_circle_rounded : Icons.cancel_rounded,
                      color: done ? Colors.green : Colors.red,
                      size: 20,
                    ),
                    const SizedBox(width: 10),

                    // DESKRIPSI
                    Expanded(
                      child: Text(
                        e.description,
                        style: TextStyle(
                          color: done ? Colors.black87 : Colors.red.shade700,
                          fontWeight: done ? FontWeight.w500 : FontWeight.w600,
                        ),
                      ),
                    ),

                    // TOMBOL ISI (KHUSUS BELUM PERWALIAN & BELUM DONE)
                    if (!done && isPerwalian)
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF1E73BE),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const PerwalianPage(), // ⬅️ ganti kalau beda
                            ),
                          );
                        },
                        child: const Text(
                          'Isi',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
