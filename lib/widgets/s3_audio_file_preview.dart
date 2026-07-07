import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:s3editor/models/s3_item.dart';
import 'package:s3editor/notifiers/s3_notifier.dart';
import 'package:s3editor/notifiers/settings_notifier.dart';

class S3AudioFilePreview extends HookConsumerWidget {
  final S3Item s3Item;
  const S3AudioFilePreview({super.key, required this.s3Item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s3Notifier = ref.read(s3Provider.notifier);
    final settingsState = ref.watch((settingsProvider));
    final isLoading = useState(false);
    final error = useState('');
    final currentSound = useState<AudioSource?>(null);
    final soundHandle = useState<SoundHandle?>(null);
    final isValid = soundHandle.value == null
        ? false
        : SoLoud.instance.getIsValidVoiceHandle(soundHandle.value!);

    bool getIsPlaying() {
      if (soundHandle.value == null) return false;
      if (!isValid) return false;

      final paused = SoLoud.instance.getPause(soundHandle.value!);

      return !paused;
    }

    final isPlaying = useState(false);
    final isStoped = useState(true);
    Future<void> stop() async {
      await SoLoud.instance.stop(soundHandle.value!);
      isPlaying.value = false;
      isStoped.value = true;
    }

    void pauseSwitch() {
      if (!isValid) {
        return;
      }
      SoLoud.instance.pauseSwitch(soundHandle.value!);
      isPlaying.value = getIsPlaying();
    }

    Future<void> play() async {
      if (isValid) {
        return;
      }
      soundHandle.value = await SoLoud.instance.play(currentSound.value!);
      isPlaying.value = true;
      isStoped.value = false;
    }

    void fill() {
      Future(() async {
        isLoading.value = false;
        try {
          if (s3Item.url.isEmpty) {
            S3Item.urls[s3Item.key] = await s3Notifier.getUrl(s3Item.key);
          }
          currentSound.value = await SoLoud.instance.loadUrl(s3Item.url);
          if (settingsState.isAutoplayAudio) {
            await play();
          } else {
            isStoped.value = true;
          }
        } catch (err) {
          error.value = '$err';
        }

        isLoading.value = true;
      });
    }

    useEffect(() {
      fill();
      return () async {
        if (soundHandle.value != null) {
          await stop();
        }

        if (currentSound.value != null) {
          SoLoud.instance.disposeSource(currentSound.value!);
        }
      };
    }, [s3Item.key]);

    if (!isLoading.value) return Center(child: CircularProgressIndicator());
    if (error.value.isNotEmpty) {
      return Center(child: Text(error.value));
    }
    final btnColors = IconButton.styleFrom(
      backgroundColor: Colors.blue[100],
      //foregroundColor: Colors.white,
    );

    return Row(
      mainAxisAlignment: .center,
      spacing: 8,
      children: [
        IconButton(
          style: btnColors,
          onPressed: () async {
            await stop();
          },
          icon: Icon(Icons.stop),
        ),
        IconButton(
          style: btnColors,
          iconSize: 36,
          onPressed: () async {
            if (isStoped.value) {
              await play();
              return;
            }
            pauseSwitch();
          },
          icon: isPlaying.value ? Icon(Icons.pause) : Icon(Icons.play_arrow),
        ),
      ],
    );
  }
}
