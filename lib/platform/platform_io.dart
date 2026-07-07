/// Платформозависимый файловый ввод-вывод.
///
/// На нативных платформах (Windows/macOS/Linux/mobile) используется `dart:io`,
/// на web — браузерные API (см. соответствующие реализации). Весь код приложения
/// работает только с этим фасадом и ничего не знает о платформе.
///
/// Контракт (реализуется в platform_io_native.dart / platform_io_web.dart):
/// - `bool get supportsLocalFs`
/// - `Future<Uint8List> readBytesFromPath(String path)`
/// - `Future<String?> defaultSaveDir()`
/// - `bool directoryExists(String path)`
/// - `Future<void> saveBytes({required String fileName, required Uint8List bytes, String? saveDir, bool openFolder})`
library;

export 'platform_io_native.dart'
    if (dart.library.html) 'platform_io_web.dart';
