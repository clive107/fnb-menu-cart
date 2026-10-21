part of 'note_details_bloc.dart';

enum DeleteNoteStatus { initial, loading, success, failure, tokenExpired }

extension DeleteNoteStatusX on DeleteNoteStatus {
  bool get isInitial => this == DeleteNoteStatus.initial;
  bool get isLoading => this == DeleteNoteStatus.loading;
  bool get isSuccess => this == DeleteNoteStatus.success;
  bool get isFailure => this == DeleteNoteStatus.failure;
  bool get isTokenExpired => this == DeleteNoteStatus.tokenExpired;
}

class NoteDetailsState extends Equatable {
  final DeleteNoteStatus deleteStatus;
  final Failure? deleteFailure;

  const NoteDetailsState({
    this.deleteStatus = DeleteNoteStatus.initial,
    this.deleteFailure,
  });

  @override
  List<Object?> get props => [deleteStatus, deleteFailure];

  NoteDetailsState copyWith({
    DeleteNoteStatus? deleteStatus,
    Optional<Failure> deleteFailure = const Optional(),
  }) {
    return NoteDetailsState(
      deleteStatus: deleteStatus ?? this.deleteStatus,
      deleteFailure: resolveOptional(deleteFailure, this.deleteFailure),
    );
  }
}
