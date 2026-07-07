import 'package:minio/models.dart';

extension ListObjectsResultExt on ListObjectsResult {
  String get key => toString();
}
