class S3Item {
  static Map<String, String> urls = {};
  final String key;
  final String name;
  final bool isFolder;
  final int size;
  final DateTime? lastModified;

  S3Item({
    required this.key,
    required this.name,
    required this.isFolder,
    required this.size,
    this.lastModified,
  });

  String get url => urls.containsKey(key) ? urls[key]! : '';

  bool? _isTextFile;
  bool? _isImageFile;
  bool? _isAudioFile;
  bool get isTextFile {
    _isTextFile ??= [
      'txt',
      'md',
      'json',
      'xml',
      'csv',
      'log',
      'js',
      'dart',
      'py',
    ].contains(name.split('.').last.toLowerCase());
    return _isTextFile!;
  }

  bool get isImageFile {
    _isImageFile ??= [
      'png',
      'jpg',
      'jpeg',
      'bmp',
    ].contains(name.split('.').last.toLowerCase());
    return _isImageFile!;
  }

  bool get isAudioFile {
    _isAudioFile ??= [
      'mp3',
      'wav',
      'ogg',
    ].contains(name.split('.').last.toLowerCase());
    return _isAudioFile!;
  }
}
