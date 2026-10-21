import 'package:example_app/models/note/note.dart';
import 'package:example_app/models/app/error_handling/failure.dart';
import 'package:example_app/models/data_types/optional.dart';
import 'package:example_app/services/note/note_service.dart';
import 'package:example_app/utils/data_types/optional.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' show ClientException;
import 'package:logger/logger.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

part 'update_note_event.dart';
part 'update_note_state.dart';

class UpdateNoteBloc extends Bloc<UpdateNoteEvent, UpdateNoteState> {
  static const String _kTag = '[UpdateNoteBloc]';

  final Logger _logger;
  final NoteService _noteService;

  UpdateNoteBloc({
    required Logger logger,
    required NoteService noteService,
  }) : _logger = logger,
       _noteService = noteService,
       super(const UpdateNoteState()) {
    on<GetNote>(_mapGetNoteEventToState);
    on<UpdateNote>(_mapUpdateNoteEventToState);
  }

  void _mapGetNoteEventToState(
    GetNote event,
    Emitter<UpdateNoteState> emit,
  ) async {
    const String kTag = '$_kTag[GetNote]';
    // Emit state with loading status
    emit(
      state.copyWith(
        getNoteStatus: GetNoteStatus.loading,
        getNoteFailure: const Optional.set(null),
        note: const Optional.set(null),
      ),
    );
    try {
      _logger.i('$kTag Getting note...');
      final Map<String, dynamic> response = await _noteService.getNote();
      final Note note = Note.fromJson(response['data']);
      _logger.i('$kTag Get note successfully.');
      // Emit state with success status and data
      emit(
        state.copyWith(
          getNoteStatus: GetNoteStatus.success,
          getNoteFailure: const Optional.set(null),
          note: Optional.set(note),
        ),
      );
    } catch (e, stackTrace) {
      _logger.e('$kTag Get note failed: $e');
      if (e is InvalidTokenFailure) {
        // Emit state with token expired status
        emit(
          state.copyWith(
            getNoteStatus: GetNoteStatus.tokenExpired,
            getNoteFailure: const Optional.set(null),
            note: const Optional.set(null),
          ),
        );
        return;
      }
      if (e is Failure || e is ClientException) {
        Failure failure = e is Failure ? e : const ClientExceptionFailure();
        // Emit state with failure status and failure
        emit(
          state.copyWith(
            getNoteStatus: GetNoteStatus.failure,
            getNoteFailure: Optional.set(failure),
            note: const Optional.set(null),
          ),
        );
        return;
      }
      Sentry.captureException(e, stackTrace: stackTrace);
      // Emit state with failure status
      emit(
        state.copyWith(
          getNoteStatus: GetNoteStatus.failure,
          getNoteFailure: const Optional.set(null),
          note: const Optional.set(null),
        ),
      );
    }
  }

  void _mapUpdateNoteEventToState(
    UpdateNote event,
    Emitter<UpdateNoteState> emit,
  ) async {
    const String kTag = '$_kTag[UpdateNote]';
    // Emit state with loading status
    emit(
      state.copyWith(
        status: UpdateNoteStatus.loading,
        failure: const Optional.set(null),
      ),
    );
    try {
      _logger.i('$kTag Updating note...');
      final Map<String, dynamic> response = await _noteService.updateNote(
        updateNoteRequest: event.updateNoteRequest,
      );
      final Note note = Note.fromJson(response['data']);
      _logger.i('$kTag Note updated successfully');
      // Emit state with success status and the updated note
      emit(
        state.copyWith(
          status: UpdateNoteStatus.success,
          failure: const Optional.set(null),
          note: Optional.set(note),
        ),
      );
    } catch (e, stackTrace) {
      _logger.e('$kTag Update note failed: $e');
      if (e is InvalidTokenFailure) {
        // Emit state with token expired status
        emit(
          state.copyWith(
            status: UpdateNoteStatus.tokenExpired,
            failure: const Optional.set(null),
          ),
        );
        return;
      }
      if (e is Failure || e is ClientException) {
        Failure failure = e is Failure ? e : const ClientExceptionFailure();
        // Emit state with failure status and failure
        emit(
          state.copyWith(
            status: UpdateNoteStatus.failure,
            failure: Optional.set(failure),
          ),
        );
        return;
      }
      Sentry.captureException(e, stackTrace: stackTrace);
      // Emit state with failure status
      emit(
        state.copyWith(
          status: UpdateNoteStatus.failure,
          failure: const Optional.set(null),
        ),
      );
    }
  }
}
