import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// В браузере нет доступа к локальной файловой системе.
bool get supportsLocalFs => false;

/// В браузере файлов по пути не существует — эта операция не поддерживается.
Future<Uint8List> readBytesFromPath(String path) =>
    throw UnsupportedError('Чтение файлов по пути недоступно в web');

/// Папки загрузок в понимании ОС в браузере нет.
Future<String?> defaultSaveDir() async => null;

/// В браузере проверить путь к директории нельзя.
bool directoryExists(String path) => false;

/// Скачать байты как файл через браузер (Blob + временная ссылка).
///
/// [saveDir] и [openFolder] в web игнорируются — браузер сам решает, куда
/// сохранять, и открывает свой диалог/папку загрузок.
Future<void> saveBytes({
  required String fileName,
  required Uint8List bytes,
  String? saveDir,
  bool openFolder = false,
}) async {
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: 'application/octet-stream'),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor =
      web.document.createElement('a') as web.HTMLAnchorElement
        ..href = url
        ..download = fileName
        ..style.display = 'none';
  web.document.body?.appendChild(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
}
