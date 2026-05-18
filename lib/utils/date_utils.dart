String formatIST(String utcTime) {
  if (utcTime.isEmpty) return "";

  final dt = DateTime.parse(utcTime).toLocal();

  return "${dt.day.toString().padLeft(2, '0')}-"
         "${dt.month.toString().padLeft(2, '0')}-"
         "${dt.year}  "
         "${dt.hour.toString().padLeft(2, '0')}:"
         "${dt.minute.toString().padLeft(2, '0')}";
}
