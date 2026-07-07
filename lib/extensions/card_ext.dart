import 'package:flutter/material.dart';

extension CardExt on Card {
  static Card casual({
    Widget? child,
    Color? color,
    EdgeInsetsGeometry? padding = const EdgeInsets.all(16.0),
  }) {
    return Card(
      margin: EdgeInsets.zero,
      color: color ?? Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      elevation: 0,
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16.0),
        child: child,
      ),
    );
  }
}
