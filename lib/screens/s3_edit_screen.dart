// Экран просмотра/редактирования
import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:highlight/languages/json.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:json5/json5.dart';
import 'package:s3editor/exceptions/is_not_text_exception.dart';
import 'package:s3editor/models/s3_item.dart';
import 'package:s3editor/notifiers/s3_notifier.dart';

class FormatIntent extends Intent {
  const FormatIntent();
}

class SaveDocument extends Intent {
  const SaveDocument();
}

class S3EditScreen extends HookConsumerWidget {
  final S3Item item;

  const S3EditScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = useState(false);
    //final isEditing = useState(false);
    final error = useState('');
    //final textController = useTextEditingController();
    final s3Notifier = ref.read(s3Provider.notifier);
    final presignedUrl = useState('');

    final codeController = useState<CodeController?>(null);
    final scrollController = useScrollController();

    void formatCode() {
      try {
        if (codeController.value == null) {
          return;
        }
        final parsed = json5Decode(codeController.value!.text);

        const encoder = JsonEncoder.withIndent('  ');

        codeController.value!.text = encoder.convert(parsed);
      } catch (e) {
        debugPrint(e.toString());
      }
    }

    Future<void> load() async {
      try {
        isLoading.value = true;
        presignedUrl.value = await s3Notifier.getUrl(item.key);
        if (item.isTextFile) {
          final text = await s3Notifier.loadTextFileByUrl(presignedUrl.value);
          codeController.value = CodeController(
            text: text, // Initial code
            language: json,
          );
          //textController.text = text;
        }
      } on IsNotTextException catch (err) {
        error.value = '$err';
      } catch (err) {
        error.value = 'Ошибка: $err';
      } finally {
        isLoading.value = false;
      }
    }

    void showSnackBar(BuildContext context, String msg) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), duration: const Duration(seconds: 2)),
      );
    }

    Future<void> saveText(BuildContext context) async {
      if (!item.isTextFile ||
          presignedUrl.value.isEmpty ||
          codeController.value == null) {
        return;
      }

      //isLoading.value = true;
      try {
        final putUrl = await s3Notifier.s3.getPresignedUploadUrl(
          item.key,
          const Duration(minutes: 5),
        );
        final response = await http.put(
          Uri.parse(putUrl),
          headers: {'Content-Type': 'text/plain; charset=utf-8'},
          body: codeController.value!.text,
        );
        if (response.statusCode == 200 || response.statusCode == 204) {
          if (context.mounted) showSnackBar(context, '✅ Файл сохранён');
        } else {
          throw Exception('Сервер вернул ${response.statusCode}');
        }
      } catch (e) {
        if (context.mounted) showSnackBar(context, '❌ Ошибка сохранения: $e');
      } finally {
        // isLoading.value = false;
      }
    }

    useEffect(() {
      Future(() async {
        await load();
      });
      return () {
        //textController.dispose();
      };
    }, [item.key]);

    if (isLoading.value) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (error.value.isNotEmpty) {
      return Scaffold(body: Center(child: Text(error.value)));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(item.name),
        actions: item.isTextFile
            ? [
                IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: () => saveText(context),
                ),
              ]
            : null,
      ),
      body: item.isImageFile
          ? InteractiveViewer(
              minScale: 0.5,
              maxScale: 5.0,
              child: Center(
                child: CachedNetworkImage(
                  imageUrl: presignedUrl.value,
                  fit: BoxFit.contain,
                  placeholder: (_, _) => const CircularProgressIndicator(),
                  errorWidget: (_, _, _) =>
                      const Icon(Icons.error, color: Colors.red, size: 48),
                ),
              ),
            )
          : item.isTextFile
          ? Builder(
              builder: (context) {
                if (codeController.value != null) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Shortcuts(
                      shortcuts: {
                        const SingleActivator(
                          LogicalKeyboardKey.keyF,
                          alt: true,
                        ): const FormatIntent(),
                        const SingleActivator(
                          LogicalKeyboardKey.keyS,
                          control: true,
                        ): const SaveDocument(),
                      },
                      child: Actions(
                        actions: {
                          FormatIntent: CallbackAction<FormatIntent>(
                            onInvoke: (intent) {
                              formatCode();
                              return null;
                            },
                          ),
                          SaveDocument: CallbackAction<SaveDocument>(
                            onInvoke: (intent) {
                              saveText(context);
                              return null;
                            },
                          ),
                        },
                        child: RawScrollbar(
                          controller: scrollController,
                          thumbVisibility: true,
                          child: SingleChildScrollView(
                            controller: scrollController,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minWidth: MediaQuery.of(context).size.width,
                                minHeight: MediaQuery.of(context).size.height,
                              ),
                              child: CodeTheme(
                                data: CodeThemeData(
                                  styles: monokaiSublimeTheme,
                                ),
                                child: CodeField(
                                  controller: codeController.value!,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }
                return const SizedBox();
              },
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.insert_drive_file,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Тип файла не поддерживается для встроенного просмотра',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => showSnackBar(
                      context,
                      'Используйте open_file пакет для внешнего просмотра',
                    ),
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Открыть в стороннем приложении'),
                  ),
                ],
              ),
            ),
    );
  }
}
