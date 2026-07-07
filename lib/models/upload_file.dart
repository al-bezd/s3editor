import 'dart:typed_data';

/// Файл, подготовленный к загрузке в S3: имя + байты содержимого.
///
/// Работает одинаково на всех платформах — в отличие от пути к файлу,
/// которого в браузере не существует.
class UploadFile {
  final String name;
  final Uint8List bytes;

  const UploadFile({required this.name, required this.bytes});
}
