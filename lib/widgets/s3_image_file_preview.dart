import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:s3editor/models/s3_item.dart';
import 'package:s3editor/notifiers/s3_notifier.dart';

class S3ImageFilePreview extends HookConsumerWidget {
  const S3ImageFilePreview({super.key, required this.s3Item});
  final S3Item s3Item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s3Notifier = ref.read(s3Provider.notifier);
    final isLoading = useState(false);
    final error = useState('');
    void fill() {
      Future(() async {
        isLoading.value = false;
        try {
          if (s3Item.url.isEmpty) {
            S3Item.urls[s3Item.key] = await s3Notifier.getUrl(s3Item.key);
          }
        } catch (err) {
          error.value = '$err';
        }

        isLoading.value = true;
      });
    }

    useEffect(() {
      fill();
      return null;
    }, [s3Item.key]);

    if (!isLoading.value) return Center(child: CircularProgressIndicator());
    if (error.value.isNotEmpty) {
      return Center(child: Text(error.value));
    }
    return CachedNetworkImage(imageUrl: s3Item.url);
  }
}
