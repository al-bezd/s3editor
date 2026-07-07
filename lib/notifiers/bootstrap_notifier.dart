import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:s3editor/const.dart';
import 'package:s3editor/notifiers/s3_notifier.dart';
import 'package:s3editor/notifiers/settings_notifier.dart';
import 'package:s3editor/states/bootstrap_state.dart';
import 'package:s3editor/screens/settings_screen.dart';

final bootstrapProvider = NotifierProvider<BootstrapNotidier, BootstrapState>(
  BootstrapNotidier.new,
);

class BootstrapNotidier extends Notifier<BootstrapState> {
  Future<void> bootstrap() async {
    state = state.copyWith(isLoading: true);
    final settingsisDone = await ref
        .read(settingsProvider.notifier)
        .bootstrap();
    if (!settingsisDone) {
      Navigator.of(
        globalNavigatorKey.currentContext!,
      ).push(MaterialPageRoute(builder: (context) => const SettingScreen()));
    }
    await ref.read(s3Provider.notifier).bootstrap();
    state = state.copyWith(isLoading: false);
  }

  @override
  BootstrapState build() {
    final initState = BootstrapState();
    Future.delayed(Duration(milliseconds: 200), bootstrap);
    return initState;
  }
}
