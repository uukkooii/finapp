import 'package:flutter/material.dart';
import '../core/constants.dart';

/// Reusable month selector: < [Year Month] >
class MonthSelector extends StatelessWidget {
  final DateTime month;
  final ValueChanged<DateTime> onChanged;
  final Color? textColor;

  const MonthSelector({
    super.key,
    required this.month,
    required this.onChanged,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left, color: goldColor),
          onPressed: () => onChanged(DateTime(month.year, month.month - 1)),
        ),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: month,
              firstDate: DateTime(2020),
              lastDate: DateTime(2030),
              builder: (ctx, child) => Theme(
                data: Theme.of(ctx).copyWith(
                  colorScheme: const ColorScheme.dark(primary: goldColor),
                ),
                child: child!,
              ),
            );
            if (picked != null) onChanged(picked);
          },
          child: Text(
            '${month.year}年${month.month}月',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor ?? Colors.white,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right, color: goldColor),
          onPressed: () => onChanged(DateTime(month.year, month.month + 1)),
        ),
      ],
    );
  }
}
