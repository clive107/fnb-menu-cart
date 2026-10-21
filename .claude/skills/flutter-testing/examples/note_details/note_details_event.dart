part of 'note_details_bloc.dart';

abstract class NoteDetailsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class DeleteNote extends NoteDetailsEvent {
  final DeleteNoteRequest deleteNoteRequest;

  DeleteNote({required this.deleteNoteRequest});

  @override
  List<Object?> get props => [deleteNoteRequest];
}
