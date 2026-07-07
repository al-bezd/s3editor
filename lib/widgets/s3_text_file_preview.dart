import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:s3editor/enums/file_type.dart';
import 'package:s3editor/models/s3_item.dart';
import 'package:s3editor/notifiers/s3_notifier.dart';

class S3TextFilePreview extends HookConsumerWidget {
  final S3Item s3Item;
  final InputDecoration? decoration;
  const S3TextFilePreview({super.key, required this.s3Item, this.decoration});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s3Notifier = ref.read(s3Provider.notifier);
    final isLoading = useState(false);
    final controller = useTextEditingController();
    void fill() {
      Future(() async {
        isLoading.value = false;
        controller.text =
            (await s3Notifier.loadFile(item: s3Item, fileType: FileType.text))
                as String;
        isLoading.value = true;
      });
    }

    useEffect(() {
      fill();
      return null;
    }, [s3Item.key]);

    if (!isLoading.value) return Center(child: CircularProgressIndicator());
    return TextField(
      //controller: _textController,
      controller: controller,
      maxLines: null,
      //expands: true,
      readOnly: true,
      decoration: decoration,
      //style: TextStyle(fontFamily: editing ? 'monospace' : null),
    );
  }
}
