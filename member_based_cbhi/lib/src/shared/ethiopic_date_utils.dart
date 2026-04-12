/// Ethiopic (Ge'ez) calendar utilities for CBHI date display.
/// Ethiopian calendar is ~7-8 years behind Gregorian.
/// Months: Meskerem, Tikimt, Hidar, Tahsas, Tir, Yekatit, Megabit,
///         Miazia, Ginbot, Sene, Hamle, Nehase, Pagume
library;

class EthiopicDate {
  const EthiopicDate(this.year, this.month, this.day);

  final int year;
  final int month;
  final int day;

  static const _monthNames = [
    'Meskerem', 'Tikimt', 'Hidar', 'Tahsas', 'Tir', 'Yekatit',
    'Megabit', 'Miazia', 'Ginbot', 'Sene', 'Hamle', 'Nehase', 'Pagume',
  ];

  static const _monthNamesAm = [
    'መስከረም', 'ጥቅምት', 'ህዳር', 'ታህሳስ', 'ጥር', 'የካቲት',
    'መጋቢት', 'ሚያዚያ', 'ግንቦት', 'ሰኔ', 'ሐምሌ', 'ነሐሴ', 'ጳጉሜ',
  ];

  String get monthName => month >= 1 && month <= 13 ? _monthNames[month - 1] : '';
  String get monthNameAm => month >= 1 && month <= 13 ? _monthNamesAm[month - 1] : '';

  /// Convert Gregorian DateTime to Ethiopian date
  static EthiopicDate fromGregorian(DateTime gregorian) {
    // Ethiopian calendar conversion algorithm
    final jdn = _gregorianToJdn(gregorian.year, gregorian.month, gregorian.day);
    return _jdnToEthiopic(jdn);
  }

  /// Convert Ethiopian date to Gregorian DateTime
  DateTime toGregorian() {
    final jdn = _ethiopicToJdn(year, month, day);
    return _jdnToGregorian(jdn);
  }

  /// Format as "DD Month YYYY" in English
  String format({bool amharic = false}) {
    final name = amharic ? monthNameAm : monthName;
    return '$day $name $year';
  }

  /// Format as "DD/MM/YYYY"
  String formatNumeric() =>
      '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$year';

  static int _gregorianToJdn(int year, int month, int day) {
    final a = (14 - month) ~/ 12;
    final y = year + 4800 - a;
    final m = month + 12 * a - 3;
    return day + (153 * m + 2) ~/ 5 + 365 * y + y ~/ 4 - y ~/ 100 + y ~/ 400 - 32045;
  }

  static EthiopicDate _jdnToEthiopic(int jdn) {
    final r = (jdn - 1723856) % 1461;
    final n = r % 365 + 365 * (r ~/ 1460);
    final year = 4 * ((jdn - 1723856) ~/ 1461) + r ~/ 365 - r ~/ 1460;
    final month = n ~/ 30 + 1;
    final day = n % 30 + 1;
    return EthiopicDate(year, month, day);
  }

  static int _ethiopicToJdn(int year, int month, int day) {
    return 1723856 + 365 * (year - 1) + year ~/ 4 + 30 * (month - 1) + day - 1;
  }

  static DateTime _jdnToGregorian(int jdn) {
    final a = jdn + 32044;
    final b = (4 * a + 3) ~/ 146097;
    final c = a - (146097 * b) ~/ 4;
    final d = (4 * c + 3) ~/ 1461;
    final e = c - (1461 * d) ~/ 4;
    final m = (5 * e + 2) ~/ 153;
    final day = e - (153 * m + 2) ~/ 5 + 1;
    final month = m + 3 - 12 * (m ~/ 10);
    final year = 100 * b + d - 4800 + m ~/ 10;
    return DateTime(year, month, day);
  }

  @override
  String toString() => format();
}

/// Format a Gregorian date showing both calendars
String formatDualCalendar(DateTime gregorian, {bool amharic = false}) {
  final eth = EthiopicDate.fromGregorian(gregorian);
  final gregStr = '${gregorian.day.toString().padLeft(2, '0')}/'
      '${gregorian.month.toString().padLeft(2, '0')}/${gregorian.year}';
  final ethStr = eth.format(amharic: amharic);
  return '$gregStr ($ethStr EC)';
}
