import 'dart:io';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:s3editor/const.dart';
import 'package:s3editor/extensions/build_context_ext.dart';
import 'package:s3editor/extensions/string_ext.dart';
import 'package:s3editor/notifiers/s3_notifier.dart';
import 'package:s3editor/notifiers/settings_notifier.dart';
import 'package:s3editor/widgets/input_shape_widget.dart';

class SettingScreen extends HookConsumerWidget {
  const SettingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storage = useState(FlutterSecureStorage());
    final items = useState<Map<String, String>>({});

    final isLoading = useState(false);
    final s3Notifier = ref.read(s3Provider.notifier);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final settingsState = ref.watch(settingsProvider);
    useEffect(() {
      Future(() async {
        isLoading.value = true;
        items.value = await storage.value.readAll();
        if (settingsState.saveDir.isEmpty) {
          settingsNotifier.saveDir = (await getDownloadsDir()).path;
          if (context.mounted) {
            context.showSnackBar(
              'the save directory is set by default'.toCapitalize(),
            );
          }
        }
        isLoading.value = false;
      });
      return () => settingsNotifier.fill();
    }, []);
    return Scaffold(
      appBar: AppBar(title: Text('settings'.toCapitalize()), centerTitle: true),
      body: Align(
        alignment: Alignment.center,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              child: Column(
                spacing: 16,
                children: [
                  InputShapeWidget(
                    title: 'end point'.toCapitalize(),
                    currentValue: settingsState.endPoint,
                    onTap: () {
                      context.showInputField((value) {
                        //storage.value.write(key: 'endPoint', value: value);
                        settingsNotifier.endPoint = value;
                        context.showSnackBar(
                          'field "end point" was successfuly save',
                        );
                      }, initValue: settingsState.endPoint);
                    },
                    onLongPress: () {
                      //storage.value.delete(key: 'endPoint');
                      settingsNotifier.endPoint = '';
                      context.showSnackBar(
                        'field "end point" was successfuly removed',
                      );
                    },
                  ),
                  InputShapeWidget(
                    title: 'access key'.toCapitalize(),
                    currentValue: settingsState.accessKey,
                    secretText: true,
                    onTap: () {
                      context.showInputField((value) {
                        //storage.value.write(key: 'accessKey', value: value);
                        settingsNotifier.accessKey = value;
                        context.showSnackBar(
                          'field "access key" was successfuly save',
                        );
                      }, initValue: settingsState.accessKey);
                    },
                    onLongPress: () {
                      //storage.value.delete(key: 'accessKey');
                      settingsNotifier.accessKey = '';
                      context.showSnackBar(
                        'field "access key" was successfuly removed',
                      );
                    },
                  ),
                  InputShapeWidget(
                    title: 'secret key'.toCapitalize(),
                    currentValue: settingsState.secretKey,
                    secretText: true,
                    onTap: () {
                      context.showInputField((value) {
                        //storage.value.write(key: 'secretKey', value: value);
                        settingsNotifier.secretKey = value;
                        context.showSnackBar(
                          'field "secret key" was successfuly save',
                        );
                      }, initValue: settingsState.secretKey);
                    },
                    onLongPress: () {
                      //storage.value.delete(key: 'secretKey');
                      settingsNotifier.secretKey = '';
                      context.showSnackBar(
                        'field "secret key" was successfuly removed',
                      );
                    },
                  ),
                  InputShapeWidget(
                    title: 'bucket'.toCapitalize(),
                    currentValue: settingsState.bucket,
                    onTap: () async {
                      final buckets = await ref
                          .read(s3Provider.notifier)
                          .getBuckets();
                      if (context.mounted) {
                        final bucket = await showConfirmationDialog(
                          context: context,
                          title: 'select bucket'.toCapitalize(),

                          actions: buckets
                              .map(
                                (x) => AlertDialogAction(key: x, label: x.name),
                              )
                              .toList(),
                        );
                        if (bucket != null) {
                          // storage.value.write(
                          //   key: 'bucket',
                          //   value: bucket.name,
                          // );
                          settingsNotifier.bucket = bucket.name;
                          await s3Notifier.reconect();
                          if (context.mounted) {
                            context.showSnackBar(
                              'field "bucket" was successfuly save',
                            );
                          }
                        }
                      }

                      // context.showInputField((value) {
                      //   storage.value.write(key: 'bucket', value: value);
                      //   settingsNotifier.bucket = value;
                      //   context.showSnackBar('field "bucket" was successfuly save');
                      // }, initValue: settingsState.bucket);
                    },
                    onLongPress: () {
                      //storage.value.delete(key: 'bucket');
                      settingsNotifier.bucket = '';
                      context.showSnackBar(
                        'field "bucket" was successfuly removed',
                      );
                    },
                  ),
                  InputShapeWidget(
                    title: 'save dir'.toCapitalize(),
                    currentValue: settingsState.saveDir,
                    suffix: IconButton(
                      onPressed: () async {
                        String? selectedDirectory =
                            await FilePicker.getDirectoryPath();
                        if (selectedDirectory != null) {
                          settingsNotifier.saveDir = selectedDirectory;
                          if (context.mounted) {
                            context.showSnackBar(
                              'field "save dir" was successfuly save',
                            );
                          }
                        }
                      },
                      icon: Icon(Icons.folder),
                      onLongPress: () async {
                        settingsNotifier.saveDir =
                            (await getDownloadsDir()).path;
                        if (context.mounted) {
                          context.showSnackBar(
                            'field "save dir" set default path folder',
                          );
                        }
                      },
                    ),
                    onTap: () {
                      context.showInputField((value) {
                        if (!Directory(value).existsSync()) {
                          context.showErrorSnackBar(
                            'directory $value is not found',
                          );
                          return;
                        }
                        //storage.value.write(key: 'saveDir', value: value);
                        settingsNotifier.saveDir = value;
                        context.showSnackBar(
                          'field "save dir" was successfuly save',
                        );
                      }, initValue: settingsState.saveDir);
                    },
                    onLongPress: () {
                      //storage.value.delete(key: 'saveDir');
                      settingsNotifier.saveDir = '';
                      context.showSnackBar(
                        'field "save dir" was successfuly removed',
                      );
                    },
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'open the folder with the file after downloading'
                              .toCapitalize(),
                        ),
                      ),
                      Switch(
                        value: settingsState.isOpenFolderAfterDownload,
                        onChanged: (value) {
                          settingsNotifier.isOpenFolderAfterDownload = value;
                        },
                      ),
                    ],
                  ),
                  
                     Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'autoplay audio files'
                              .toCapitalize(),
                        ),
                      ),
                      Switch(
                        value: settingsState.isAutoplayAudio,
                        onChanged: (value) {
                          settingsNotifier.isAutoplayAudio = value;
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),
                  CheckConnection(
                    endPoint: settingsState.endPoint,
                    accessKey: settingsState.accessKey,
                    secretKey: settingsState.secretKey,
                    //bucket: settingsState.bucket,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CheckConnection extends HookConsumerWidget {
  final String endPoint;
  final String accessKey;
  final String secretKey;
  //final String bucket;

  const CheckConnection({
    super.key,
    required this.endPoint,
    required this.accessKey,
    required this.secretKey,
    //required this.bucket,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s3Notifier = ref.read(s3Provider.notifier);
    final statusMessage = useState('');
    final isSuccess = useState(false);
    final isLoading = useState(false);
    return Column(
      children: [
        if (statusMessage.value.isNotEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: isSuccess.value
                  ? Colors.green.shade50
                  : Colors.red.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSuccess.value ? Colors.green : Colors.red,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isSuccess.value ? Icons.check_circle : Icons.error_outline,
                  color: isSuccess.value ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    statusMessage.value,
                    style: TextStyle(
                      color: isSuccess.value
                          ? Colors.green.shade800
                          : Colors.red.shade800,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // 🔹 Кнопка тестирования
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: isLoading.value
                ? null
                : () async {
                    try {
                      await s3Notifier.testConnection(
                        endPoint: endPoint,
                        accessKey: accessKey,
                        secretKey: secretKey,
                        //bucket: bucket.isEmpty ? null : bucket,
                      );

                      isLoading.value = false;
                      isSuccess.value = true;
                      statusMessage.value =
                          '✅ ${'connection is success'.toCapitalize()}!';
                    } catch (e) {
                      String errorMsg = e.toString();

                      // 🔹 Дружелюбная обработка типовых ошибок
                      if (errorMsg.contains('Connection refused') ||
                          errorMsg.contains('SocketException')) {
                        errorMsg =
                            '❌ Хост недоступен. Проверьте Endpoint и порт.';
                      } else if (errorMsg.contains('InvalidAccessKeyId') ||
                          errorMsg.contains('SignatureDoesNotMatch')) {
                        errorMsg = '❌ Неверный Access Key или Secret Key.';
                      } else if (errorMsg.contains('timeout') ||
                          errorMsg.contains('Timeout')) {
                        errorMsg =
                            '❌ Превышено время ожидания. Проверьте сеть или SSL.';
                      } else if (errorMsg.contains('certificate') ||
                          errorMsg.contains('CERTIFICATE')) {
                        errorMsg =
                            '❌ Ошибка SSL-сертификата. Попробуйте отключить SSL.';
                      }

                      isLoading.value = false;
                      isSuccess.value = false;
                      statusMessage.value = errorMsg;
                    }
                  },
            icon: isLoading.value
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.wifi),
            label: Text(
              isLoading.value
                  ? '${'testing'.toCapitalize()}...'
                  : '🔍 ${'test connection'.toCapitalize()}',
            ),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: statusMessage.value.isEmpty
                  ? Theme.of(context).primaryColor
                  : (isSuccess.value ? Colors.green : Colors.red),
            ),
          ),
        ),
      ],
    );
  }
}
