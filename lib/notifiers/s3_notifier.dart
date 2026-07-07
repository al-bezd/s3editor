import 'dart:io';
import 'dart:typed_data';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:minio/minio.dart';
import 'package:minio/models.dart';
import 'package:s3editor/enums/file_type.dart';
import 'package:s3editor/exceptions/is_not_image_exception.dart';
import 'package:s3editor/exceptions/is_not_text_exception.dart';
import 'package:s3editor/models/s3_client.dart';
import 'package:s3editor/models/s3_item.dart';
import 'package:s3editor/notifiers/settings_notifier.dart';
import 'package:s3editor/states/s3_state.dart';

final s3Provider = NotifierProvider<S3Notifier, S3State>(S3Notifier.new);

class S3Notifier extends Notifier<S3State> {
  S3Storage? _s3;

  S3Storage get s3 {
    _s3 ??= _createConnection();
    return _s3!;
  }

  final List<String> pathStack = [];

  S3Storage _createConnection() {
    //final settingsNotifier = ref.read(settingsProvider.notifier);
    final settingsState = ref.read(settingsProvider);
    return S3Storage(
      endPoint: settingsState.endPoint, // или ваш S3-совместимый эндпоинт
      accessKey: settingsState.accessKey,
      secretKey: settingsState.secretKey,
      bucket: settingsState.bucket,
    );
  }

  Future<void> reconect() async {
    _s3 = _createConnection();
    loadItems();
  }

  Future<String> getUrl(String key, {Map<String, String>? respHeaders}) async {
    final url = await s3.getPresignedDownloadUrl(
      key,
      const Duration(minutes: 15),
      respHeaders: respHeaders,
    );
    return url;
  }

  Future<dynamic> loadFile({
    required S3Item item,
    required FileType fileType,
  }) async {
    final url = await getUrl(item.key);
    switch (fileType) {
      case FileType.text:
        if (!item.isTextFile) throw IsNotTextException('is not text');
        return await loadTextFileByUrl(url);

      case FileType.image:
        if (!item.isImageFile) throw IsNotImageException('is not image');
        return await loadImageFileByUrl(url);
    }
  }

  Future<String> loadTextFileByUrl(String url) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return response.body;
    } else {
      throw Exception('Не удалось загрузить текст');
    }
  }

  Future<Uint8List> loadImageFileByUrl(String url) async {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return response.bodyBytes; // ✅ Байты изображения
    } else {
      throw Exception(
        'Не удалось загрузить изображение: ${response.statusCode}',
      );
    }
  }

  Future<void> loadItems() async {
    state = state.copyWith(isLoading: true, error: '');

    try {
      // Получаем объекты без рекурсии (только текущий уровень)
      final stream = s3.minio.listObjects(
        s3.bucket,
        prefix: state.currentPreffix,
        recursive: false,
      );
      final rawItems = await stream.toList();

      final parsed = <S3Item>[];
      //final seenFolders = <String>{};

      for (final obj in rawItems) {
        for (final folder in obj.prefixes) {
          //seenFolders.add(folder);
          parsed.add(
            S3Item(
              key: folder,
              name: folder.substring(0, folder.length - 1).split("/").last,
              isFolder: true,
              size: 0,
              lastModified: null,
            ),
          );
        }

        for (final file in obj.objects) {
          if (file.key == null) throw 'item.key is null';
          parsed.add(
            S3Item(
              key: file.key!,
              name: obj.objects.first == file
                  ? '..'
                  : file.key!.replaceAll(state.currentPreffix, ''),
              isFolder: file.key!.endsWith('/'),
              size: file.size ?? 0,
              lastModified: file.lastModified,
            ),
          );
        }
      }

      // Сортировка: папки сверху, файлы по алфавиту
      parsed.sort((a, b) {
        if (a.isFolder && !b.isFolder) return -1;
        if (!a.isFolder && b.isFolder) return 1;
        return a.name.compareTo(b.name);
      });

      state = state.copyWith(items: [...parsed], isLoading: false);
    } catch (e) {
      state = state.copyWith(error: 'Ошибка загрузки: $e', isLoading: false);
    }
  }

  void openFolder(String folderKey) {
    if (state.currentPreffix == folderKey) {
      goBack();
      return;
    }

    setCurrentFolder(folderKey);
    pathStack.add(folderKey);

    loadItems();
  }

  void goBack() {
    if (pathStack.isEmpty) return;
    pathStack.removeLast();

    setCurrentFolder(pathStack.isEmpty ? '' : pathStack.last);
    loadItems();
  }

  Future<void> deleteObject(String objectKey) async {
    await s3.deleteObject(objectKey);
    await loadItems();
  }

  Future<void> deleteFolderRecursive(String objectKey) async {
    await s3.deleteFolderRecursive(objectKey);
    await loadItems();
  }

  void setCurrentFolder(String key) {
    state = state.copyWith(currentPreffix: key);
  }

  void setCurrentKey(String key) {
    state = state.copyWith(currentKey: key);
  }

  Future<void> onDragDone(DropDoneDetails details) async {
    // for (final file in details.files) {
    //   await s3.uploadFile(
    //     '${state.currentPreffix}${file.name}',
    //     File(file.path),
    //   );
    // }
    // await loadItems();
    await addFiles(details.files.map((x) => x.path));
  }

  Future<void> addFiles(Iterable<String> filePaths) async {
    for (final filePath in filePaths) {
      final file = File(filePath);
      await s3.uploadFile(
        '${state.currentPreffix}${file.path.split('\\').last}',
        File(file.path),
      );
    }
    await loadItems();
  }

  void onDragEntered(DropEventDetails details) {}
  void onDragExited(DropEventDetails details) {}
  void onDragUpdated(DropEventDetails details) {}

  Future<void> createNewFolder(String newFolderKey) async {
    await s3.createFolder(newFolderKey);
    await loadItems();
  }

  Future<bool> bootstrap() async {
    return true;
  }

  Future<void> testConnection({
    required String endPoint,
    required String accessKey,
    required String secretKey,
    String? bucket,
  }) async {
    final minio = Minio(
      endPoint: endPoint,
      accessKey: accessKey,
      secretKey: secretKey,
    );

    // 🔹 2. Быстрая проверка: список бакетов + таймаут
    await minio.listBuckets().timeout(const Duration(seconds: 8));
    if (bucket != null) {
      final exists = await minio.bucketExists(bucket);
      if (!exists) throw Exception('Bakcet "$bucket" не найден');
    }
  }

  Future<File> download(S3Item item, {String? saveDir}) async {
    return await s3.downloadFile(item.key, item.name, saveDir: saveDir);
  }

  Future<List<Bucket>> getBuckets() async {
    return await s3.getBuckets();
  }

  @override
  build() {
    return S3State(currentPreffix: '', error: '', items: [], currentKey: '');
  }
}
