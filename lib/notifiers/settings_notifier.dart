import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:s3editor/const.dart';
import 'package:s3editor/states/settings_state.dart';
import 'package:s3editor/screens/settings_screen.dart';

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(
  SettingsNotifier.new,
);

class SettingsNotifier extends Notifier<SettingsState> {
  late final FlutterSecureStorage storage;

  set isOpenFolderAfterDownload(bool value) {
    state = state.copyWith(isOpenFolderAfterDownload: value);

    storage.write(key: 'isOpenFolderAfterDownload', value: value.toString());
  }

  set isAutoplayAudio(bool value) {
    state = state.copyWith(isAutoplayAudio: value);
    storage.write(key: 'isAutoplayAudio', value: value.toString());
  }

  set saveDir(String value) {
    state = state.copyWith(saveDir: value);
    if (value.isEmpty) {
      storage.delete(key: 'saveDir');
      return;
    }
    storage.write(key: 'saveDir', value: value);
  }

  set endPoint(String value) {
    state = state.copyWith(endPoint: value);
    if (value.isEmpty) {
      storage.delete(key: 'endPoint');
      return;
    }
    storage.write(key: 'endPoint', value: value);
  }

  set accessKey(String value) {
    state = state.copyWith(accessKey: value);
    if (value.isEmpty) {
      storage.delete(key: 'accessKey');
      return;
    }
    storage.write(key: 'accessKey', value: value);
  }

  set secretKey(String value) {
    state = state.copyWith(secretKey: value);
    if (value.isEmpty) {
      storage.delete(key: 'secretKey');
      return;
    }
    storage.write(key: 'secretKey', value: value);
  }

  set bucket(String value) {
    state = state.copyWith(bucket: value);
    if (value.isEmpty) {
      storage.delete(key: 'bucket');
      return;
    }
    storage.write(key: 'bucket', value: value);
  }

  Future<void> init() async {
    final items = await storage.readAll();
    final endPoint = items['endPoint'];
    final accessKey = items['accessKey'];
    final secretKey = items['secretKey'];
    final bucket = items['bucket'];
    final saveDir = items['saveDir'];
    final isOpenFolderAfterDownload = items['isOpenFolderAfterDownload'];
    final isAutoplayAudio = items['isAutoplayAudio'];
    final args = [endPoint, accessKey, secretKey, bucket];
    if (args.contains(null) || args.contains('')) {
      Navigator.of(
        globalNavigatorKey.currentContext!,
      ).push(MaterialPageRoute(builder: (context) => const SettingScreen()));
    }
    state = state.copyWith(
      endPoint: endPoint,
      accessKey: accessKey,
      secretKey: secretKey,
      bucket: bucket,
      saveDir: saveDir,
      isOpenFolderAfterDownload: isOpenFolderAfterDownload == null
          ? true
          : bool.parse(isOpenFolderAfterDownload),
      isAutoplayAudio: isAutoplayAudio == null
          ? true
          : bool.parse(isAutoplayAudio),
    );
  }

  Future<bool> bootstrap() async {
    storage = FlutterSecureStorage();
    return await fill();
  }

  Future<bool> fill() async {
    final storage = FlutterSecureStorage();
    final items = await storage.readAll();
    final endPoint = items['endPoint'];
    final accessKey = items['accessKey'];
    final secretKey = items['secretKey'];
    final bucket = items['bucket'];
    final saveDir = items['saveDir'];
    final isOpenFolderAfterDownload = items['isOpenFolderAfterDownload'];
    final isAutoplayAudio = items['isAutoplayAudio'];
    final args = [endPoint, accessKey, secretKey, bucket];
    if (args.contains(null) || args.contains('')) {
      return false;
    }
    state = state.copyWith(
      endPoint: endPoint,
      accessKey: accessKey,
      secretKey: secretKey,
      bucket: bucket,
      saveDir: saveDir,
      isOpenFolderAfterDownload: isOpenFolderAfterDownload == null
          ? true
          : bool.parse(isOpenFolderAfterDownload),
      isAutoplayAudio: isAutoplayAudio == null
          ? true
          : bool.parse(isAutoplayAudio),
    );
    return true;
  }

  @override
  SettingsState build() {
    final state = SettingsState(
      accessKey: '',
      endPoint: '',
      secretKey: '',
      bucket: '',
      saveDir: '',
    );
    //init();
    return state;
  }
}
