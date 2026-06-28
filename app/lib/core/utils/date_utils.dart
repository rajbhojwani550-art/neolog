import 'package:intl/intl.dart';

class AppDateUtils {
  AppDateUtils._();

  static final _dateFormat = DateFormat('dd MMM yyyy');
  static final _dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');
  static final _shortDateFormat = DateFormat('dd/MM/yyyy');
  static final _apiFormat = DateFormat('yyyy-MM-dd');

  static String formatDate(DateTime date) => _dateFormat.format(date);
  static String formatDateTime(DateTime date) => _dateTimeFormat.format(date);
  static String formatShortDate(DateTime date) => _shortDateFormat.format(date);
  static String formatForApi(DateTime date) => _apiFormat.format(date);

  static DateTime? parseApiDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;
    try {
      return DateTime.parse(dateStr);
    } catch (_) {
      return null;
    }
  }

  static int daysBetween(DateTime from, DateTime to) {
    final fromNorm = DateTime(from.year, from.month, from.day);
    final toNorm = DateTime(to.year, to.month, to.day);
    return toNorm.difference(fromNorm).inDays;
  }

  static int dayOfLife(DateTime dob) {
    return daysBetween(dob, DateTime.now()) + 1;
  }

  static String dayOfLifeString(DateTime dob) {
    final dol = dayOfLife(dob);
    return 'DOL $dol';
  }

  static String timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return formatDate(date);
  }
}
