// lib/widgets/keyboard_file_paste_listener.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pasteboard/pasteboard.dart';


class KeyboardFilePasteListener extends StatefulWidget {
  final Widget child;
  final Function(List<String> files) onFilesPasted;
  final VoidCallback? onPasteEmpty;

  const KeyboardFilePasteListener({
    required this.child,
    required this.onFilesPasted,
    this.onPasteEmpty,
    super.key,
  });

  @override
  State<KeyboardFilePasteListener> createState() =>
      _KeyboardFilePasteListenerState();
}

class _KeyboardFilePasteListenerState extends State<KeyboardFilePasteListener> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // 🔹 Авто-фокус, чтобы ловить клавиши
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        FocusScope.of(context).requestFocus(_focusNode);
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  /// Обработка нажатий клавиш
  Future<void> _onKey(KeyEvent event) async {
    // 🔹 Проверяем: Ctrl+V (или Cmd+V на macOS)
    final isCtrlV =
        event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.keyV &&
        (HardwareKeyboard.instance.isControlPressed ||
            HardwareKeyboard.instance.isMetaPressed); // Meta = Cmd на Mac

    if (!isCtrlV) return;

    // 🔹 Предотвращаем стандартное поведение
    //event.handled = true;

    // 🔹 Читаем файлы из буфера
    final files = await Pasteboard.files();

    if (files.isNotEmpty) {
      // ✅ Файлы найдены - передаём в колбэк
      widget.onFilesPasted(files);
    } else {
      // ❌ Файлов нет - возможно, обычный текст
      widget.onPasteEmpty?.call();

      // 🔹 Можно прочитать обычный текст, если нужно:
      // final text = await Clipboard.getData('text/plain');
      // if (text?.value != null) { ... }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: true,

      onKeyEvent: (node, event) {
        _onKey(event);
        return KeyEventResult.handled;
      },
      child: widget.child,
    );
  }
}
