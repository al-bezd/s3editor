import 'dart:async';
import 'package:flutter/material.dart';
import 'package:keyboard_height/keyboard_height.dart';

extension BuildContextExt on BuildContext {
  ///
  void showSnackBar(String text, {Color? backgroundColor}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(content: Text(text), backgroundColor: backgroundColor),
    );
  }

  ///
  void showErrorSnackBar(String text) {
    final color = Colors.white;
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        backgroundColor: Colors.red,
        content: Row(
          spacing: 8,
          children: [
            Icon(Icons.error, color: color),
            Text(text, style: TextStyle(color: color)),
          ],
        ),
      ),
    );
  }

  void showSuccessSnackBar(String text) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green,
        content: Row(
          spacing: 8,
          children: [
            Icon(
              Icons.check_circle_outline,
              color: Theme.of(this).snackBarTheme.actionTextColor,
            ),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: Theme.of(this).snackBarTheme.actionTextColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showInputField(
    Function(String value) whenComplete, {
    String? initValue,
    String? hintText,
    String? helperText,
    TextInputType? keyboardType,
  }) {
    final textController = TextEditingController(text: initValue);

    final StreamController sc = StreamController<double>.broadcast();
    KeyboardHeight.instance.addListener(() {
      if (!sc.isClosed) {
        sc.add(KeyboardHeight.instance.height);
      }
    });

    showModalBottomSheet(
      isScrollControlled: true,
      context: this,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                keyboardType: keyboardType,
                onEditingComplete: () => Navigator.of(context).pop(),
                autofocus: true,
                controller: textController,
                decoration: InputDecoration(
                  hintText: hintText,
                  helperText: helperText,
                ),
              ),
            ),

            StreamBuilder(
              stream: sc.stream,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  return SizedBox(height: snapshot.data + 48);
                } else {
                  return const SizedBox(height: 0);
                }
              },
            ),
          ],
        );
      },
    ).whenComplete(() {
      if (textController.text != '') {
        whenComplete(textController.text);
      }
      sc.close();
    });
  }
}
