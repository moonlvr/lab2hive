const List<String> _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Formats a date like "Oct 5, 2026".
String formatDate(DateTime d) => '${_months[d.month - 1]} ${d.day}, ${d.year}';