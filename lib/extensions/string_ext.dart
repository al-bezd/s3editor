extension StringExt on String {
  String toCapitalize() {
    try {
      return this[0].toUpperCase() + substring(1);
    } catch (e) {
      return this;
    }
  }

  /// Обрезать строку и добавить ... в конец если она более 20 символов но если менее но оставить как есть
  String truncateWithEllipsis({int cutoff = 32}) {
    if (length <= cutoff) {
      return this;
    } else {
      return '${substring(0, cutoff)}...';
    }
  }

  bool isDigit() {
    if (isEmpty) return false; // Пустая строка — не число

    // Пробуем распарсить строку в double
    final parsedValue = double.tryParse(this);

    // Если распарсилось успешно — это число
    return parsedValue != null;
  }

  double toDouble() {
    if (this=='.' || this == ',') return 0.0;
    if (isEmpty) return 0.0;
    return double.parse(this);
  }

  int toInt() {
    if (isEmpty) return 0;
    return int.parse(this);
  }
}
