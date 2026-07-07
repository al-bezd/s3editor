import 'dart:io';
import 'dart:typed_data';

/// Локальная файловая система доступна.
bool get supportsLocalFs => true;

/// Прочитать байты файла по пути (drag&drop / вставка из буфера на десктопе).
Future<Uint8List> readBytesFromPath(String path) => File(path).readAsBytes();

/// Папка загрузок по умолчанию (или null, если не удалось определить).
Future<String?> defaultSaveDir() async {
  final home =
      Platform.environment['USERPROFILE'] ?? Platform.environment['HOME'];
  if (home == null || home.isEmpty) return null;
  return '$home${Platform.pathSeparator}Downloads';
}

/// Существует ли директория.
bool directoryExists(String path) => Directory(path).existsSync();

/// Сохранить байты в файл на диск и (опционально) открыть папку в проводнике.
Future<void> saveBytes({
  required String fileName,
  required Uint8List bytes,
  String? saveDir,
  bool openFolder = false,
}) async {
  Directory dir;
  if (saveDir == null || saveDir.isEmpty) {
    final def = await defaultSaveDir();
    dir = Directory(def ?? Directory.current.path);
  } else {
    dir = Directory(saveDir);
  }
  if (!dir.existsSync()) {
    dir.createSync(recursive: true);
  }

  final filePath = '${dir.path}${Platform.pathSeparator}$fileName';
  await File(filePath).writeAsBytes(bytes);

  if (openFolder) {
    if (Platform.isWindows) {
      await Process.run('explorer', [dir.path]);
    } else if (Platform.isMacOS) {
      await Process.run('open', [dir.path]);
    } else if (Platform.isLinux) {
      await Process.run('xdg-open', [dir.path]);
    }
  }
}
