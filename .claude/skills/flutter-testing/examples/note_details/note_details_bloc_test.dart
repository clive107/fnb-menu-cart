import 'package:example_app/blocs/note/note_details/note_details_bloc.dart';
import 'package:example_app/models/app/error_handling/failure.dart';
import 'package:example_app/models/common/label_value.dart';
import 'package:example_app/models/data_types/optional.dart';
import 'package:example_app/services/note/note_service.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' show ClientException;
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';

class MockLogger extends Mock implements Logger {}

class MockNoteService extends Mock implements NoteService {}

// A concrete event that doesn't override `props`, so the base
// NoteDetailsEvent's default `props => []` gets exercised.
class _NoOpNoteDetailsEvent extends NoteDetailsEvent {}

void main() {
  late Logger mockLogger;
  late NoteService mockNoteService;
  late NoteDetailsBloc noteDetailsBloc;

  final DeleteNoteRequest fakeRequest = DeleteNoteRequest(
    noteId: 'note-001',
    reason: const LabelValue(
      label: 'Duplicate',
      value: 'duplicate',
    ),
    remarks: 'Already saved elsewhere',
  );

  setUpAll(() {
    registerFallbackValue(
      DeleteNoteRequest(
        noteId: 'note-001',
        reason: const LabelValue(label: 'Other', value: 'other'),
      ),
    );
  });

  setUp(() {
    mockLogger = MockLogger();
    mockNoteService = MockNoteService();
    noteDetailsBloc = NoteDetailsBloc(
      logger: mockLogger,
      noteService: mockNoteService,
    );
  });

  tearDown(() {
    noteDetailsBloc.close();
  });

  test('Initial state is NoteDetailsState()', () {
    expect(noteDetailsBloc.state, const NoteDetailsState());
  });

  group('[NoteDetailsEvent] tests -', () {
    // Only needed because DeleteNote overrides `props` itself, so
    // nothing else calls the base class's default. Remove this test if a
    // field-less event is added and covers it instead.
    test('base NoteDetailsEvent has empty props by default.', () {
      expect(_NoOpNoteDetailsEvent().props, isEmpty);
    });

    test('DeleteNote props include the request.', () {
      expect(
        DeleteNote(deleteNoteRequest: fakeRequest).props,
        [fakeRequest],
      );
    });
  });

  group('[DeleteNoteStatusX] tests -', () {
    test('isInitial is true only for initial status.', () {
      expect(DeleteNoteStatus.initial.isInitial, isTrue);
      expect(DeleteNoteStatus.loading.isInitial, isFalse);
      expect(DeleteNoteStatus.success.isInitial, isFalse);
      expect(DeleteNoteStatus.failure.isInitial, isFalse);
      expect(DeleteNoteStatus.tokenExpired.isInitial, isFalse);
    });

    test('isLoading is true only for loading status.', () {
      expect(DeleteNoteStatus.loading.isLoading, isTrue);
      expect(DeleteNoteStatus.initial.isLoading, isFalse);
      expect(DeleteNoteStatus.success.isLoading, isFalse);
      expect(DeleteNoteStatus.failure.isLoading, isFalse);
      expect(DeleteNoteStatus.tokenExpired.isLoading, isFalse);
    });

    test('isSuccess is true only for success status.', () {
      expect(DeleteNoteStatus.success.isSuccess, isTrue);
      expect(DeleteNoteStatus.initial.isSuccess, isFalse);
      expect(DeleteNoteStatus.loading.isSuccess, isFalse);
      expect(DeleteNoteStatus.failure.isSuccess, isFalse);
      expect(DeleteNoteStatus.tokenExpired.isSuccess, isFalse);
    });

    test('isFailure is true only for failure status.', () {
      expect(DeleteNoteStatus.failure.isFailure, isTrue);
      expect(DeleteNoteStatus.initial.isFailure, isFalse);
      expect(DeleteNoteStatus.loading.isFailure, isFalse);
      expect(DeleteNoteStatus.success.isFailure, isFalse);
      expect(DeleteNoteStatus.tokenExpired.isFailure, isFalse);
    });

    test('isTokenExpired is true only for tokenExpired status.', () {
      expect(DeleteNoteStatus.tokenExpired.isTokenExpired, isTrue);
      expect(DeleteNoteStatus.initial.isTokenExpired, isFalse);
      expect(DeleteNoteStatus.loading.isTokenExpired, isFalse);
      expect(DeleteNoteStatus.success.isTokenExpired, isFalse);
      expect(DeleteNoteStatus.failure.isTokenExpired, isFalse);
    });
  });

  group('[NoteDetailsState.copyWith] tests -', () {
    const Failure fakeFailure = Failure(statusCode: 500, message: 'error');

    test('preserves all fields when called with no arguments.', () {
      const NoteDetailsState state = NoteDetailsState(
        deleteStatus: DeleteNoteStatus.failure,
        deleteFailure: fakeFailure,
      );
      expect(state.copyWith(), state);
    });

    test('updates deleteStatus when provided.', () {
      const NoteDetailsState state = NoteDetailsState();
      expect(
        state.copyWith(deleteStatus: DeleteNoteStatus.loading).deleteStatus,
        DeleteNoteStatus.loading,
      );
    });

    test('updates deleteFailure to a value when Optional.set(value) is provided.', () {
      const NoteDetailsState state = NoteDetailsState();
      expect(
        state.copyWith(deleteFailure: const Optional.set(fakeFailure)).deleteFailure,
        fakeFailure,
      );
    });

    test('clears deleteFailure to null when Optional.set(null) is provided.', () {
      const NoteDetailsState state = NoteDetailsState(
        deleteFailure: fakeFailure,
      );
      expect(
        state.copyWith(deleteFailure: const Optional.set(null)).deleteFailure,
        isNull,
      );
    });

    test('preserves existing deleteFailure when Optional() is not provided.', () {
      const NoteDetailsState state = NoteDetailsState(
        deleteFailure: fakeFailure,
      );
      expect(state.copyWith().deleteFailure, fakeFailure);
    });
  });

  group('[DeleteNote] tests -', () {
    // Scenario - Success
    blocTest<NoteDetailsBloc, NoteDetailsState>(
      'Emits [loading, success] when delete succeeds.',
      build: () {
        when(
          () => mockNoteService.deleteNote(
            deleteNoteRequest: any(named: 'deleteNoteRequest'),
          ),
        ).thenAnswer((_) async => {});
        return noteDetailsBloc;
      },
      act: (bloc) =>
          bloc.add(DeleteNote(deleteNoteRequest: fakeRequest)),
      expect: () => [
        const NoteDetailsState(
          deleteStatus: DeleteNoteStatus.loading,
          deleteFailure: null,
        ),
        const NoteDetailsState(
          deleteStatus: DeleteNoteStatus.success,
          deleteFailure: null,
        ),
      ],
    );

    // Scenario - InvalidTokenFailure
    blocTest<NoteDetailsBloc, NoteDetailsState>(
      'Emits [loading, tokenExpired] when service throws InvalidTokenFailure.',
      build: () {
        when(
          () => mockNoteService.deleteNote(
            deleteNoteRequest: any(named: 'deleteNoteRequest'),
          ),
        ).thenThrow(const InvalidTokenFailure());
        return noteDetailsBloc;
      },
      act: (bloc) =>
          bloc.add(DeleteNote(deleteNoteRequest: fakeRequest)),
      expect: () => [
        const NoteDetailsState(
          deleteStatus: DeleteNoteStatus.loading,
          deleteFailure: null,
        ),
        const NoteDetailsState(
          deleteStatus: DeleteNoteStatus.tokenExpired,
          deleteFailure: null,
        ),
      ],
    );

    // Scenario - Known Failure
    blocTest<NoteDetailsBloc, NoteDetailsState>(
      'Emits [loading, failure] with Failure object when service throws a Failure.',
      build: () {
        when(
          () => mockNoteService.deleteNote(
            deleteNoteRequest: any(named: 'deleteNoteRequest'),
          ),
        ).thenThrow(const Failure(statusCode: 500, message: 'Server error'));
        return noteDetailsBloc;
      },
      act: (bloc) =>
          bloc.add(DeleteNote(deleteNoteRequest: fakeRequest)),
      expect: () => [
        const NoteDetailsState(
          deleteStatus: DeleteNoteStatus.loading,
          deleteFailure: null,
        ),
        const NoteDetailsState(
          deleteStatus: DeleteNoteStatus.failure,
          deleteFailure: Failure(statusCode: 500, message: 'Server error'),
        ),
      ],
    );

    // Scenario - ClientException
    blocTest<NoteDetailsBloc, NoteDetailsState>(
      'Emits [loading, failure] with ClientExceptionFailure when service throws a ClientException.',
      build: () {
        when(
          () => mockNoteService.deleteNote(
            deleteNoteRequest: any(named: 'deleteNoteRequest'),
          ),
        ).thenThrow(ClientException('Network error'));
        return noteDetailsBloc;
      },
      act: (bloc) =>
          bloc.add(DeleteNote(deleteNoteRequest: fakeRequest)),
      expect: () => [
        const NoteDetailsState(
          deleteStatus: DeleteNoteStatus.loading,
          deleteFailure: null,
        ),
        const NoteDetailsState(
          deleteStatus: DeleteNoteStatus.failure,
          deleteFailure: ClientExceptionFailure(),
        ),
      ],
    );

    // Scenario - Unexpected exception
    blocTest<NoteDetailsBloc, NoteDetailsState>(
      'Emits [loading, failure] with null failure when service throws an unexpected exception.',
      build: () {
        when(
          () => mockNoteService.deleteNote(
            deleteNoteRequest: any(named: 'deleteNoteRequest'),
          ),
        ).thenThrow(Exception('Unexpected error'));
        return noteDetailsBloc;
      },
      act: (bloc) =>
          bloc.add(DeleteNote(deleteNoteRequest: fakeRequest)),
      expect: () => [
        const NoteDetailsState(
          deleteStatus: DeleteNoteStatus.loading,
          deleteFailure: null,
        ),
        const NoteDetailsState(
          deleteStatus: DeleteNoteStatus.failure,
          deleteFailure: null,
        ),
      ],
    );
  });
}
