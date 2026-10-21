part of 'update_note_bloc.dart';

enum GetNoteStatus { initial, loading, success, failure, tokenExpired }

extension GetNoteStatusX on GetNoteStatus {
  bool get isInitial => this == GetNoteStatus.initial;
  bool get isLoading => this == GetNoteStatus.loading;
  bool get isSuccess => this == GetNoteStatus.success;
  bool get isFailure => this == GetNoteStatus.failure;
  bool get isTokenExpired => this == GetNoteStatus.tokenExpired;
}

enum UpdateNoteStatus { initial, loading, success, failure, tokenExpired }

extension UpdateNoteStatusX on UpdateNoteStatus {
  bool get isInitial => this == UpdateNoteStatus.initial;
  bool get isLoading => this == UpdateNoteStatus.loading;
  bool get isSuccess => this == UpdateNoteStatus.success;
  bool get isFailure => this == UpdateNoteStatus.failure;
  bool get isTokenExpired => this == UpdateNoteStatus.tokenExpired;
}

class UpdateNoteState extends Equatable {
  final GetNoteStatus getNoteStatus;
  final Failure? getNoteFailure;
  final Note? note;
  final UpdateNoteStatus status;
  final Failure? failure;

  const UpdateNoteState({
    this.getNoteStatus = GetNoteStatus.initial,
    this.getNoteFailure,
    this.note,
    this.status = UpdateNoteStatus.initial,
    this.failure,
  });

  @override
  List<Object?> get props => [
    getNoteStatus,
    getNoteFailure,
    note,
    status,
    failure,
  ];

  UpdateNoteState copyWith({
    GetNoteStatus? getNoteStatus,
    Optional<Failure> getNoteFailure = const Optional(),
    Optional<Note> note = const Optional(),
    UpdateNoteStatus? status,
    Optional<Failure> failure = const Optional(),
  }) {
    return UpdateNoteState(
      getNoteStatus: getNoteStatus ?? this.getNoteStatus,
      getNoteFailure: resolveOptional(
        getNoteFailure,
        this.getNoteFailure,
      ),
      note: resolveOptional(note, this.note),
      status: status ?? this.status,
      failure: resolveOptional(failure, this.failure),
    );
  }
}
