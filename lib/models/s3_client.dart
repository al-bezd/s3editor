import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:minio/io.dart';
import 'package:minio/minio.dart';
import 'package:minio/models.dart';
import 'package:s3editor/const.dart';

class S3Storage {
  late final Minio _minio;
  final String _bucket;

  Minio get minio => _minio;
  String get bucket => _bucket;

  S3Storage({
    required String endPoint,
    required String accessKey,
    required String secretKey,
    String region = 'us-east-1',
    required String bucket,
    bool useSSL = true,
  }) : _bucket = bucket {
    createConnection(
      endPoint: endPoint,
      accessKey: accessKey,
      secretKey: secretKey,
    );
  }

  void createConnection({
    required String endPoint,
    required String accessKey,
    required String secretKey,
    String? region,
    bool useSSL = true,
  }) {
    _minio = Minio(
      endPoint: endPoint,
      accessKey: accessKey,
      secretKey: secretKey,
      region: region,
      useSSL: useSSL,
    );
  }

  Future<List<Bucket>> getBuckets() async {
    return await minio.listBuckets();
  }

  /// Загрузка файла из локальной директории
  Future<void> uploadFile(String objectKey, File file) async {
    await _minio.fPutObject(_bucket, objectKey, file.path);
  }

  /// Скачивание файла в локальную директорию
  Future<File> downloadFile(
    String objectKey,
    String fileName, {
    String? saveDir,
  }) async {
    //final dir = await getApplicationDocumentsDirectory();
    late Directory dir;
    if (saveDir == null || saveDir.isEmpty) {
      dir = await getDownloadsDir();
    } else {
      dir = Directory(saveDir);
    }

    //final dir = await getDownloadsDir();
    final filePath = '${dir.path}/$fileName';
    await _minio.fGetObject(_bucket, objectKey, filePath);
    return File(filePath);
  }

  /// Получить список объектов (опционально с префиксом)
  Future<List<String>> listObjects({String prefix = ''}) async {
    final stream = _minio.listObjects(_bucket, prefix: prefix);
    final items = await stream.toList();
    return items.map((e) => e.toString()).toList();
  }

  /// Удаление объекта
  Future<void> deleteObject(String objectKey) async {
    await _minio.removeObject(_bucket, objectKey);
  }

  /// Удаление папки и всех её вложений (рекурсивно)
  Future<void> deleteFolderRecursive(String folderKey) async {
    // 🔹 Нормализуем ключ: гарантируем слэш в конце
    final prefix = folderKey.endsWith('/') ? folderKey : '$folderKey/';

    // 🔹 Получаем ВСЕ объекты с этим префиксом (рекурсивно)
    final stream = _minio.listObjects(_bucket, prefix: prefix, recursive: true);
    final objects = await stream.toList();

    // 🔹 Удаляем каждый объект
    for (final objAndPreffixes in objects) {
      for (final obj in objAndPreffixes.objects) {
        if (obj.key != null) {
          await _minio.removeObject(_bucket, obj.key!);
        }
      }
    }

    //print('✅ Удалено объектов: ${objects.length}');
  }

  Future<void> createFolder(String folderKey) async {
    // ✅ Гарантируем, что ключ заканчивается на слэш
    final key = folderKey.endsWith('/') ? folderKey : '$folderKey/';

    // ✅ Создаём пустой объект (0 байт)
    final result = await _minio.putObject(
      _bucket,
      key,
      Stream.value(Uint8List(0)), // пустой поток байтов
      size: 0, // размер: 0 байт
      metadata: {
        "contentType": 'application/x-directory',
      }, // ✅ MIME-тип для папок (опционально)
    );
    debugPrint('createFolder: $result');
  }

  /// Генерация presigned URL для загрузки (клиент делает PUT напрямую)
  Future<String> getPresignedUploadUrl(String objectKey, Duration expiry) {
    return _minio.presignedPutObject(
      _bucket,
      objectKey,
      expires: expiry.inSeconds,
    );
  }

  /// Генерация presigned URL для скачивания
  Future<String> getPresignedDownloadUrl(
    String objectKey,
    Duration expiry, {
    Map<String, String>? respHeaders,
  }) {
    return _minio.presignedGetObject(
      _bucket,
      objectKey,
      expires: expiry.inSeconds,
      respHeaders: respHeaders,
    );
  }
}
