import 'package:flutter/material.dart';
import 'ethiopic_date_utils.dart';

/// Shows a date picker and displays the selected date in both
/// Gregorian and Ethiopic (Ge'ez) calendar formats.
Future<DateTime?> showEthiopicDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
  String? helpText,
}) async {
  final picked = await showDatePicker(
    context: context,
    initialDate: initialDate,
    firstDate: firstDate,
    lastDate: lastDate,
    helpText: helpText,
    builder: (context, child) {
      return Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(
            context,
          ).colorScheme.copyWith(primary: const Color(0xFF0D7A5F)),
        ),
        child: child!,
      );
    },
  );

  if (picked != null && context.mounted) {
    final ethDate = EthiopicDate.fromGregorian(picked);
    // Show Ethiopic date as a snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.calendar_today, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(
              'Ethiopic: ${ethDate.format()} EC',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
        backgroundColor: const Color(0xFF0D7A5F),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  return picked;
}

/// Widget that displays a date in both Gregorian and Ethiopic formats
class DualCalendarDate extends StatelessWidget {
  const DualCalendarDate({
    super.key,
    required this.date,
    this.style,
    this.ethiopicStyle,
  });

  final DateTime date;
  final TextStyle? style;
  final TextStyle? ethiopicStyle;

  @override
  Widget build(BuildContext context) {
    final ethDate = EthiopicDate.fromGregorian(date);
    final gregStr =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    final ethStr = ethDate.format();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(gregStr, style: style ?? Theme.of(context).textTheme.bodyMedium),
        Text(
          '$ethStr EC',
          style:
              ethiopicStyle ??
              Theme.of(context).textTheme.bodySmall?.copyWith(
                color: const Color(0xFF0D7A5F),
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}
