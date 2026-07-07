// // lib/services/clipboard_file_service.dart

// import 'package:flutter/foundation.dart';
// import 'package:super_clipboard/super_clipboard.dart';

// class ClipboardFileService {
//   /// Получить пути к файлам из буфера обмена (если там есть файлы)
//   static Future<List<Uint8List>> getFilePathsFromClipboard() async {
//     try {
//       // 🔹 Читаем буфер обмена
//       final clip = await SystemClipboard.instance?.read();
//       if (clip == null) return [];

//       // 🔹 Проверяем, есть ли там файлы
//       if (!clip.items.isNotEmpty) return [];

//       // 🔹 Получаем файлы
//       final items = clip.items.toList();
//       if (items.isEmpty) return [];

//       // 🔹 Извлекаем пути (на разных платформах по-разному)
//       final paths = <Uint8List>[];
//       for (final item in items) {
//         // 📁 item.name - имя файла
//         // 📁 item.contentType - MIME тип

//         // 🔹 Попытка получить локальный путь
//         item.getFile(null, (value) async {
//           final bytes = await value.readAll();
//           paths.add(bytes);
//         });

//         // 🔹 Если файл не локальный (например, из браузера) - можно скачать
//       }

//       return paths;
//     } catch (e) {
//       debugPrint('❌ Ошибка чтения буфера: $e');
//       return [];
//     }
//   }

//   /// Проверить, есть ли файлы в буфере обмена
//   // static Future<bool> hasFilesInClipboard() async {
//   //   final clip = await SystemClipboard.instance?.read();
//   //   return clip?.hasFiles ?? false;
//   // }
// }
