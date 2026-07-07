import 'dart:async';
import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:s3editor/extensions/build_context_ext.dart';
import 'package:s3editor/extensions/string_ext.dart';
import 'package:s3editor/models/s3_item.dart';
import 'package:s3editor/models/upload_file.dart';
import 'package:s3editor/notifiers/s3_notifier.dart';
import 'package:s3editor/notifiers/settings_notifier.dart';
import 'package:s3editor/widgets/keyboard_file_paste_listener.dart';
import 'package:s3editor/widgets/s3_audio_file_preview.dart';
import 'package:s3editor/widgets/s3_image_file_preview.dart';
import 'package:s3editor/screens/s3_edit_screen.dart';
import 'package:s3editor/widgets/s3_text_file_preview.dart';
import 'package:s3editor/screens/settings_screen.dart';
// Импорт вашего S3Storage из прошлого ответа

// Модель элемента

class S3BrowserScreen extends HookConsumerWidget {
  const S3BrowserScreen({super.key});

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  IconData _getFileIcon(String name) {
    final ext = name.split('.').last.toLowerCase();
    return switch (ext) {
      'jpg' || 'jpeg' || 'png' || 'gif' || 'webp' || 'svg' => Icons.image,
      'pdf' => Icons.picture_as_pdf,
      'txt' || 'md' || 'json' || 'xml' || 'csv' => Icons.article,
      'mp3' || 'wav' || 'ogg' => Icons.audio_file,
      'mp4' || 'mov' || 'avi' => Icons.video_file,
      'zip' || 'rar' || '7z' => Icons.folder_zip,
      _ => Icons.insert_drive_file,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s3State = ref.watch(s3Provider);
    final s3Notifier = ref.read(s3Provider.notifier);
    final pathStack = s3Notifier.pathStack;

    final bucket = ref.watch(settingsProvider.select((x) => x.bucket));
    useEffect(() {
      Future(() async {
        await s3Notifier.loadItems();
      });
      return null;
    }, []);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "📦 $bucket${s3State.currentPreffix.isEmpty ? ' ~ Root' : ' ~ ${pathStack.last}'}",
        ),
        leading: pathStack.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: s3Notifier.goBack,
              ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => s3Notifier.loadItems(),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const SettingScreen()),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: const Padding(
        padding: EdgeInsets.only(bottom: 16.0),
        child: Row(
          mainAxisSize: .min,
          spacing: 8,
          children: [AddFileBtn(), AddFolderBtn()],
        ),
      ),

      body: Builder(
        builder: (context) {
          if (s3State.isLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (s3State.error != '') {
            return Center(
              child: Text(
                s3State.error,
                style: const TextStyle(color: Colors.red),
              ),
            );
          } else if (s3State.items.isEmpty) {
            return KeyboardFilePasteListener(
              onFilesPasted: (List<String> filePaths) {
                s3Notifier.uploadPaths(filePaths);
              },
              child: DropTarget(
                onDragDone: (details) => s3Notifier.onDragDone(details),
                onDragEntered: (details) => s3Notifier.onDragEntered(details),
                onDragExited: (details) => s3Notifier.onDragExited(details),
                onDragUpdated: (details) => s3Notifier.onDragUpdated(details),
                child: const Center(child: Text('Папка пуста')),
              ),
            );
          }
          return KeyboardFilePasteListener(
            onFilesPasted: (List<String> filePaths) {
              s3Notifier.uploadPaths(filePaths);
            },
            child: DropTarget(
              onDragDone: (details) => s3Notifier.onDragDone(details),
              onDragEntered: (details) => s3Notifier.onDragEntered(details),
              onDragExited: (details) => s3Notifier.onDragExited(details),
              onDragUpdated: (details) => s3Notifier.onDragUpdated(details),
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 64),
                      child: ListView.builder(
                        itemCount: s3State.items.length,
                        itemBuilder: (context, index) {
                          final item = s3State.items[index];
                          return GestureDetector(
                            child: ListTile(
                              selected: s3State.currentKey == item.key,

                              selectedTileColor: Colors.grey[200],
                              leading: item.isImageFile
                                  ? SizedBox(
                                      height:
                                          48, // ✅ Стандартный размер для ListTile.leading
                                      width: 48,
                                      child: ClipRRect(
                                        // ✅ Обрезаем, если изображение не квадратное
                                        borderRadius: BorderRadius.circular(4),
                                        child: S3ImageFilePreview(s3Item: item),
                                      ),
                                    )
                                  : Icon(
                                      item.isFolder
                                          ? Icons.folder
                                          : _getFileIcon(item.name),
                                      color: item.isFolder
                                          ? Colors.orange
                                          : Colors.blue,
                                    ),
                              title: SelectableText(item.name),
                              subtitle: item.isFolder
                                  ? null
                                  : Column(
                                      spacing: 4,
                                      children: [
                                        Row(
                                          spacing: 4,
                                          children: [
                                            Text('size:'),
                                            Text(_formatSize(item.size)),
                                          ],
                                        ),
                                        Row(
                                          spacing: 4,
                                          children: [
                                            Text('last modified:'),
                                            Text(
                                              item.lastModified
                                                      ?.toString()
                                                      .substring(0, 10) ??
                                                  '',
                                              style: const TextStyle(
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                              trailing: item.name == '..'
                                  ? null
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      spacing: 8,
                                      children: [
                                        if (!item.isFolder)
                                          DownloadBtn(item: item),
                                        if (!item.isFolder)
                                          GetLinkBtn(item: item),
                                        RemoveBtn(item: item),
                                      ],
                                    ),

                              onTap: () {
                                s3Notifier.setCurrentKey(item.key);
                              },
                              onLongPress: () {
                                s3Notifier.setCurrentKey('');
                              },
                            ),
                            onDoubleTap: () {
                              if (item.isFolder) {
                                s3Notifier.openFolder(item.key);
                                return;
                              }
                              s3Notifier.setCurrentKey(item.key);
                              if (item.isAudioFile) {
                                showOkAlertDialog(
                                  context: context,
                                  message: "audio file haven't visual view",
                                );
                                return;
                              }
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => S3EditScreen(item: item),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ),

                  !s3State.currentKey.endsWith('/') &&
                          s3State.currentKey.isNotEmpty &&
                          s3State.items
                              .map((x) => x.key)
                              .contains(s3State.currentKey)
                      ? Container(
                          padding: const EdgeInsets.all(8),
                          width: 400,

                          child: Column(
                            spacing: 16,
                            children: [
                              Text(s3State.currentKey),
                              Expanded(
                                child: SingleChildScrollView(
                                  child: HookBuilder(
                                    builder: (context) {
                                      final item = s3State.currentS3Item;
                                      useEffect(() {
                                        SoLoud.instance.disposeAllSources();
                                        return null;
                                      }, [item.key]);
                                      if (item.isTextFile) {
                                        return S3TextFilePreview(s3Item: item);
                                      } else if (item.isImageFile) {
                                        return S3ImageFilePreview(s3Item: item);
                                      } else if (item.isAudioFile) {
                                        return S3AudioFilePreview(s3Item: item);
                                      }
                                      return const SizedBox();
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      : const SizedBox(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class RemoveBtn extends ConsumerWidget {
  final S3Item item;

  const RemoveBtn({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s3Notifier = ref.read(s3Provider.notifier);
    return IconButton(
      style: IconButton.styleFrom(
        //backgroundColor: Colors.red, // 🔹 Фон
        foregroundColor: Colors.red, // 🔹 Цвет иконки
        disabledBackgroundColor: Colors.grey, // 🔹 Фон когда отключён
      ),
      onPressed: () async {
        String message =
            'do you realy want to remove ${item.name} file from s3 storage?'
                .toCapitalize();

        if (item.isFolder) {
          message =
              'do you realy want to remove ${item.name} folder with all includes files, from s3 storage?'
                  .toCapitalize();
        }

        final res = await showOkCancelAlertDialog(
          context: context,
          title: 'are you sure?'.toCapitalize(),
          message: message,
        );
        if (res == OkCancelResult.ok) {
          if (item.isFolder) {
            await s3Notifier.deleteFolderRecursive(item.key);
            return;
          }
          await s3Notifier.deleteObject(item.key);
        }
      },
      icon: Icon(Icons.delete_forever),
    );
  }
}

class GetLinkBtn extends HookConsumerWidget {
  final S3Item item;
  const GetLinkBtn({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = useState(false);
    return IconButton(
      onPressed: () async {
        isLoading.value = true;
        final String link = await ref
            .read(s3Provider.notifier)
            .getUrl(item.key);
        final uri = Uri.parse(link);
        if (context.mounted) {
          showOkAlertDialog(context: context, message: uri.origin + uri.path);
        }
        isLoading.value = false;
      },
      icon: isLoading.value
          ? SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(strokeWidth: 4),
            )
          : Icon(Icons.link),
    );
  }
}

class DownloadBtn extends HookConsumerWidget {
  final S3Item item;
  const DownloadBtn({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = useState(false);
    return IconButton(
      onPressed: () async {
        isLoading.value = true;
        final settingsState = ref.read(settingsProvider);
        await ref
            .read(s3Provider.notifier)
            .download(
              item,
              saveDir: settingsState.saveDir,
              openFolder: settingsState.isOpenFolderAfterDownload,
            );
        if (context.mounted) context.showSnackBar('file was downloaded');
        //if (context.mounted) showOkAlertDialog(context: context, message: link);
        isLoading.value = false;
      },
      icon: isLoading.value
          ? SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(strokeWidth: 4),
            )
          : Icon(Icons.download),
    );
  }
}

class AddFolderBtn extends HookConsumerWidget {
  const AddFolderBtn({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newFolderName = useState('');
    final s3State = ref.watch(s3Provider);
    final s3Notifier = ref.read(s3Provider.notifier);
    return FloatingActionButton(
      heroTag: 'AddFolderBtn',
      tooltip: 'add folder',
      child: Icon(Icons.create_new_folder_outlined),
      onPressed: () {
        context.showInputField((value) async {
          if (value.isEmpty) return;
          newFolderName.value = value;

          if (s3State.items.where((x) => x.name == value).isNotEmpty) {
            showOkAlertDialog(
              context: context,
              title: 'warning'.toCapitalize(),
              message: 'folder with same name already exists',
            );
            return;
          }
          final confirm = await showOkCancelAlertDialog(
            context: context,

            title: 'confirm'.toCapitalize(),
            message:
                'are you realy want to create this folder with name "${newFolderName.value}"',
          );
          if (confirm == OkCancelResult.ok) {
            String name = s3State.currentPreffix + newFolderName.value;
            if (!name.endsWith('/')) name = '$name/';
            await s3Notifier.createNewFolder(name);
            newFolderName.value = '';
          }
        }, initValue: newFolderName.value.isEmpty ? null : newFolderName.value);
      },
    );
  }
}

class AddFileBtn extends HookConsumerWidget {
  const AddFileBtn({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s3Notifier = ref.read(s3Provider.notifier);
    return FloatingActionButton(
      heroTag: 'AddFileBtn',
      tooltip: 'add files',
      child: Icon(Icons.note_add_outlined),
      onPressed: () async {
        final filePickerResult = await FilePicker.pickFiles(
          allowMultiple: true,
          withData: true, // грузим байты в память — обязательно для web
        );
        if (filePickerResult == null) return;

        final files = filePickerResult.files
            .where((f) => f.bytes != null)
            .map((f) => UploadFile(name: f.name, bytes: f.bytes!))
            .toList();
        await s3Notifier.uploadFiles(files);
      },
    );
  }
}
