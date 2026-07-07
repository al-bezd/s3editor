import 'package:equatable/equatable.dart';
import 'package:s3editor/models/s3_item.dart';

class S3State extends Equatable {
  final String currentPreffix;
  final String currentKey;
  final String error;
  final bool isLoading;
  final List<S3Item> items;

  const S3State({
    required this.currentPreffix,
    required this.currentKey,
    required this.error,
    required this.items,
    this.isLoading = false,
  });

  @override
  List<Object?> get props => [
    currentPreffix,
    currentKey,
    error,
    isLoading,
    items,
  ];

  S3State copyWith({
    bool? isLoading,
    String? error,
    String? currentPreffix,
    String? currentKey,
    List<S3Item>? items,
  }) {
    return S3State(
      currentPreffix: currentPreffix ?? this.currentPreffix,
      currentKey: currentKey ?? this.currentKey,
      error: error ?? this.error,
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
    );
  }

  S3Item get currentS3Item {
    return items.firstWhere((x) => x.key == currentKey);
  }
}
