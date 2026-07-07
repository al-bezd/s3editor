import 'package:equatable/equatable.dart';

class SettingsState extends Equatable {
  final String endPoint;
  final String accessKey;
  final String secretKey;
  final String bucket;
  final String saveDir;
  final bool isOpenFolderAfterDownload;
  final bool isAutoplayAudio;

  const SettingsState({
    required this.endPoint,
    required this.accessKey,
    required this.secretKey,
    required this.bucket,
    required this.saveDir,
    this.isOpenFolderAfterDownload = true,
    this.isAutoplayAudio = true,
  });
  @override
  List<Object?> get props => [
    endPoint,
    secretKey,
    accessKey,
    bucket,
    saveDir,
    isOpenFolderAfterDownload,
    isAutoplayAudio,
  ];

  SettingsState copyWith({
    String? endPoint,
    String? accessKey,
    String? secretKey,
    String? bucket,
    String? saveDir,
    bool? isOpenFolderAfterDownload,
    bool? isAutoplayAudio,
  }) {
    return SettingsState(
      endPoint: endPoint ?? this.endPoint,
      accessKey: accessKey ?? this.accessKey,
      secretKey: secretKey ?? this.secretKey,
      bucket: bucket ?? this.bucket,
      saveDir: saveDir ?? this.saveDir,
      isOpenFolderAfterDownload:
          isOpenFolderAfterDownload ?? this.isOpenFolderAfterDownload,
      isAutoplayAudio: isAutoplayAudio ?? this.isAutoplayAudio,
    );
  }
}
