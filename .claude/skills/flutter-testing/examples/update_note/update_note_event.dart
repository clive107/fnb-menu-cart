part of 'update_note_bloc.dart';

abstract class UpdateNoteEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class GetNote extends UpdateNoteEvent {}

class UpdateNote extends UpdateNoteEvent {
  final UpdateNoteRequest updateNoteRequest;

  UpdateNote({required this.updateNoteRequest});

  @override
  List<Object?> get props => [updateNoteRequest];
}
