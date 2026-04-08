import 'package:chatbot/component/app_theme.dart';
import 'package:chatbot/guardianship.dart';
import 'package:chatbot/models/krs_models.dart';
import 'package:flutter/material.dart';

class KrsRequirementBubble extends StatelessWidget {
  final List<KrsRequirement> items;

  const KrsRequirementBubble({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final passed = items.where((item) => item.status == 1).length;

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppThemePalette.soft(0.88),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.assignment_turned_in,
                  size: 18,
                  color: AppThemePalette.primary,
                ),
                const SizedBox(width: 6),
                Text(
                  'Status Persyaratan KRS ($passed/${items.length})',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppThemePalette.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...items.map((item) {
              final done = item.status == 1;
              final isPerwalian =
                  item.description.trim().toLowerCase() == 'belum perwalian';

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
                    Expanded(
                      child: Text(
                        item.description,
                        style: TextStyle(
                          color: done ? Colors.black87 : Colors.red.shade700,
                          fontWeight: done ? FontWeight.w500 : FontWeight.w600,
                        ),
                      ),
                    ),
                    if (!done && isPerwalian)
                      TextButton(
                        style: TextButton.styleFrom(
                          foregroundColor: AppThemePalette.primary,
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
                              builder: (_) => const PerwalianPage(),
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
            }),
          ],
        ),
      ),
    );
  }
}
