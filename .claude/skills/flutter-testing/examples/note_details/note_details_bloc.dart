import 'package:example_app/models/app/error_handling/failure.dart';
import 'package:example_app/models/data_types/optional.dart';
import 'package:example_app/services/note/note_service.dart';
import 'package:example_app/utils/data_types/optional.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' show ClientException;
import 'package:logger/logger.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

part 'note_details_event.dart';
part 'note_details_state.dart';

class NoteDetailsBloc
    extends Bloc<NoteDetailsEvent, NoteDetailsState> {
  static const String _kTag = '[NoteDetailsBloc]';

  final Logger _logger;
  final NoteService _noteService;

  NoteDetailsBloc({
    required Logger logger,
    required NoteService noteService,
  }) : _logger = logger,
       _noteService = noteService,
       super(const NoteDetailsState()) {
    on<DeleteNote>(_mapDeleteNoteEventToState);
  }

  void _mapDeleteNoteEventToState(
    DeleteNote event,
    Emitter<NoteDetailsState> emit,
  ) async {
    const String kTag = '$_kTag[DeleteNote]';
    // Emit state with loading status
    emit(
      state.copyWith(
        deleteStatus: DeleteNoteStatus.loading,
        deleteFailure: const Optional.set(null),
      ),
    );
    try {
      final String noteId = event.deleteNoteRequest.noteId;
      _logger.i('$kTag Deleting note $noteId...');
      await _noteService.deleteNote(
        deleteNoteRequest: event.deleteNoteRequest,
      );
      _logger.i('$kTag Note $noteId deleted successfully');
      // Emit state with success status
      emit(
        state.copyWith(
          deleteStatus: DeleteNoteStatus.success,
          deleteFailure: const Optional.set(null),
        ),
      );
    } catch (e, stackTrace) {
      _logger.e('$kTag Delete note failed: $e');
      if (e is InvalidTokenFailure) {
        // Emit state with token expired status
        emit(
          state.copyWith(
            deleteStatus: DeleteNoteStatus.tokenExpired,
            deleteFailure: const Optional.set(null),
          ),
        );
        return;
      }
      if (e is Failure || e is ClientException) {
        Failure failure = e is Failure ? e : const ClientExceptionFailure();
        // Emit state with failure status and failure
        emit(
          state.copyWith(
            deleteStatus: DeleteNoteStatus.failure,
            deleteFailure: Optional.set(failure),
          ),
        );
        return;
      }
      Sentry.captureException(e, stackTrace: stackTrace);
      // Emit state with failure status
      emit(
        state.copyWith(
          deleteStatus: DeleteNoteStatus.failure,
          deleteFailure: const Optional.set(null),
        ),
      );
    }
  }
}
