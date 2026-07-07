import 'package:equatable/equatable.dart';

class BootstrapState extends Equatable {
  final bool isLoading;

  const BootstrapState({this.isLoading = true});

  @override
  List<Object?> get props => [isLoading];

  BootstrapState copyWith({bool? isLoading}) {
    return BootstrapState(isLoading: isLoading ?? this.isLoading);
  }
}
