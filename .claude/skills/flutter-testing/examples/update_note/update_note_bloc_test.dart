import 'package:example_app/blocs/note/update_note/update_note_bloc.dart';
import 'package:example_app/models/note/note.dart';
import 'package:example_app/models/app/error_handling/failure.dart';
import 'package:example_app/models/data_types/optional.dart';
import 'package:example_app/services/note/note_service.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';

class MockLogger extends Mock implements Logger {}

class MockNoteService extends Mock implements NoteService {}

class _UpdateNoteRequestFake extends Fake implements UpdateNoteRequest {}

void main() {
  late Logger mockLogger;
  late NoteService mockNoteService;
  late UpdateNoteBloc updateNoteBloc;
  late UpdateNoteRequest fakeRequest;

  // A note JSON payload as returned by the API under the `data` key.
  const Map<String, dynamic> fakeNoteJson = {
    'id': 'note-1',
    'title': 'Shopping list',
    'content': 'Milk, eggs, bread',
    'updated_at': '2026-01-01T09:00:00Z',
  };
  final Note fakeNote = Note.fromJson(fakeNoteJson);

  setUpAll(() {
    registerFallbackValue(_UpdateNoteRequestFake());
  });

  setUp(() {
    mockLogger = MockLogger();
    mockNoteService = MockNoteService();
    updateNoteBloc = UpdateNoteBloc(
      logger: mockLogger,
      noteService: mockNoteService,
    );
    fakeRequest = _UpdateNoteRequestFake();
  });

  tearDown(() {
    updateNoteBloc.close();
  });

  test('Initial state is UpdateNoteState()', () {
    expect(updateNoteBloc.state, const UpdateNoteState());
  });

  group('[UpdateNoteEvent] tests -', () {
    test('GetNote has empty props.', () {
      expect(GetNote().props, isEmpty);
    });

    test('UpdateNote exposes its request in props.', () {
      final UpdateNoteRequest request = UpdateNoteRequest(
        title: 'Shopping list',
        content: 'Milk, eggs, bread',
      );
      expect(UpdateNote(updateNoteRequest: request).props, [request]);
    });
  });

  group('[GetNoteStatusX] tests -', () {
    test('isInitial is true only for initial status.', () {
      expect(GetNoteStatus.initial.isInitial, isTrue);
      expect(GetNoteStatus.loading.isInitial, isFalse);
      expect(GetNoteStatus.success.isInitial, isFalse);
      expect(GetNoteStatus.failure.isInitial, isFalse);
      expect(GetNoteStatus.tokenExpired.isInitial, isFalse);
    });

    test('isLoading is true only for loading status.', () {
      expect(GetNoteStatus.loading.isLoading, isTrue);
      expect(GetNoteStatus.initial.isLoading, isFalse);
      expect(GetNoteStatus.success.isLoading, isFalse);
      expect(GetNoteStatus.failure.isLoading, isFalse);
      expect(GetNoteStatus.tokenExpired.isLoading, isFalse);
    });

    test('isSuccess is true only for success status.', () {
      expect(GetNoteStatus.success.isSuccess, isTrue);
      expect(GetNoteStatus.initial.isSuccess, isFalse);
      expect(GetNoteStatus.loading.isSuccess, isFalse);
      expect(GetNoteStatus.failure.isSuccess, isFalse);
      expect(GetNoteStatus.tokenExpired.isSuccess, isFalse);
    });

    test('isFailure is true only for failure status.', () {
      expect(GetNoteStatus.failure.isFailure, isTrue);
      expect(GetNoteStatus.initial.isFailure, isFalse);
      expect(GetNoteStatus.loading.isFailure, isFalse);
      expect(GetNoteStatus.success.isFailure, isFalse);
      expect(GetNoteStatus.tokenExpired.isFailure, isFalse);
    });

    test('isTokenExpired is true only for tokenExpired status.', () {
      expect(GetNoteStatus.tokenExpired.isTokenExpired, isTrue);
      expect(GetNoteStatus.initial.isTokenExpired, isFalse);
      expect(GetNoteStatus.loading.isTokenExpired, isFalse);
      expect(GetNoteStatus.success.isTokenExpired, isFalse);
      expect(GetNoteStatus.failure.isTokenExpired, isFalse);
    });
  });

  group('[UpdateNoteStatusX] tests -', () {
    test('isInitial is true only for initial status.', () {
      expect(UpdateNoteStatus.initial.isInitial, isTrue);
      expect(UpdateNoteStatus.loading.isInitial, isFalse);
      expect(UpdateNoteStatus.success.isInitial, isFalse);
      expect(UpdateNoteStatus.failure.isInitial, isFalse);
      expect(UpdateNoteStatus.tokenExpired.isInitial, isFalse);
    });

    test('isLoading is true only for loading status.', () {
      expect(UpdateNoteStatus.loading.isLoading, isTrue);
      expect(UpdateNoteStatus.initial.isLoading, isFalse);
      expect(UpdateNoteStatus.success.isLoading, isFalse);
      expect(UpdateNoteStatus.failure.isLoading, isFalse);
      expect(UpdateNoteStatus.tokenExpired.isLoading, isFalse);
    });

    test('isSuccess is true only for success status.', () {
      expect(UpdateNoteStatus.success.isSuccess, isTrue);
      expect(UpdateNoteStatus.initial.isSuccess, isFalse);
      expect(UpdateNoteStatus.loading.isSuccess, isFalse);
      expect(UpdateNoteStatus.failure.isSuccess, isFalse);
      expect(UpdateNoteStatus.tokenExpired.isSuccess, isFalse);
    });

    test('isFailure is true only for failure status.', () {
      expect(UpdateNoteStatus.failure.isFailure, isTrue);
      expect(UpdateNoteStatus.initial.isFailure, isFalse);
      expect(UpdateNoteStatus.loading.isFailure, isFalse);
      expect(UpdateNoteStatus.success.isFailure, isFalse);
      expect(UpdateNoteStatus.tokenExpired.isFailure, isFalse);
    });

    test('isTokenExpired is true only for tokenExpired status.', () {
      expect(UpdateNoteStatus.tokenExpired.isTokenExpired, isTrue);
      expect(UpdateNoteStatus.initial.isTokenExpired, isFalse);
      expect(UpdateNoteStatus.loading.isTokenExpired, isFalse);
      expect(UpdateNoteStatus.success.isTokenExpired, isFalse);
      expect(UpdateNoteStatus.failure.isTokenExpired, isFalse);
    });
  });

  group('[UpdateNoteState.copyWith] tests -', () {
    const Failure fakeFailure = Failure(statusCode: 500, message: 'error');

    test('preserves all fields when called with no arguments.', () {
      final UpdateNoteState state = UpdateNoteState(
        getNoteStatus: GetNoteStatus.success,
        getNoteFailure: fakeFailure,
        note: fakeNote,
        status: UpdateNoteStatus.failure,
        failure: fakeFailure,
      );
      expect(state.copyWith(), state);
    });

    test('updates getNoteStatus when provided.', () {
      const UpdateNoteState state = UpdateNoteState();
      expect(
        state
            .copyWith(getNoteStatus: GetNoteStatus.loading)
            .getNoteStatus,
        GetNoteStatus.loading,
      );
    });

    test('updates status when provided.', () {
      const UpdateNoteState state = UpdateNoteState();
      expect(
        state.copyWith(status: UpdateNoteStatus.loading).status,
        UpdateNoteStatus.loading,
      );
    });

    test(
      'updates getNoteFailure to a value when Optional.set(value) is provided.',
      () {
        const UpdateNoteState state = UpdateNoteState();
        expect(
          state
              .copyWith(getNoteFailure: Optional.set(fakeFailure))
              .getNoteFailure,
          fakeFailure,
        );
      },
    );

    test(
      'clears getNoteFailure to null when Optional.set(null) is provided.',
      () {
        const UpdateNoteState state = UpdateNoteState(
          getNoteFailure: fakeFailure,
        );
        expect(
          state
              .copyWith(getNoteFailure: const Optional.set(null))
              .getNoteFailure,
          isNull,
        );
      },
    );

    test(
      'preserves existing getNoteFailure when Optional() is not provided.',
      () {
        const UpdateNoteState state = UpdateNoteState(
          getNoteFailure: fakeFailure,
        );
        expect(state.copyWith().getNoteFailure, fakeFailure);
      },
    );

    test('updates note when Optional.set(value) is provided.', () {
      const UpdateNoteState state = UpdateNoteState();
      expect(
        state.copyWith(note: Optional.set(fakeNote)).note,
        fakeNote,
      );
    });

    test('clears note to null when Optional.set(null) is provided.', () {
      final UpdateNoteState state = UpdateNoteState(note: fakeNote);
      expect(state.copyWith(note: const Optional.set(null)).note, isNull);
    });

    test('preserves existing note when Optional() is not provided.', () {
      final UpdateNoteState state = UpdateNoteState(note: fakeNote);
      expect(state.copyWith().note, fakeNote);
    });

    test(
      'updates failure to a value when Optional.set(value) is provided.',
      () {
        const UpdateNoteState state = UpdateNoteState();
        expect(
          state.copyWith(failure: Optional.set(fakeFailure)).failure,
          fakeFailure,
        );
      },
    );

    test('clears failure to null when Optional.set(null) is provided.', () {
      const UpdateNoteState state = UpdateNoteState(failure: fakeFailure);
      expect(state.copyWith(failure: const Optional.set(null)).failure, isNull);
    });

    test('preserves existing failure when Optional() is not provided.', () {
      const UpdateNoteState state = UpdateNoteState(failure: fakeFailure);
      expect(state.copyWith().failure, fakeFailure);
    });
  });

  group('[GetNote] tests -', () {
    // Scenario - Get note is successful
    blocTest<UpdateNoteBloc, UpdateNoteState>(
      'Emits [loading, success] get note statuses with the note when [GetNote] is added and the request succeeds.',
      build: () {
        when(
          () => mockNoteService.getNote(),
        ).thenAnswer((_) async => {'data': fakeNoteJson});
        return updateNoteBloc;
      },
      act: (bloc) => bloc.add(GetNote()),
      expect: () => [
        const UpdateNoteState(
          getNoteStatus: GetNoteStatus.loading,
          getNoteFailure: null,
          note: null,
          status: UpdateNoteStatus.initial,
          failure: null,
        ),
        UpdateNoteState(
          getNoteStatus: GetNoteStatus.success,
          getNoteFailure: null,
          note: fakeNote,
          status: UpdateNoteStatus.initial,
          failure: null,
        ),
      ],
    );

    // Scenario - Get note fails with an InvalidTokenFailure
    blocTest<UpdateNoteBloc, UpdateNoteState>(
      'Emits [loading, tokenExpired] get note statuses when [GetNote] is added and throws InvalidTokenFailure.',
      build: () {
        when(
          () => mockNoteService.getNote(),
        ).thenThrow(const InvalidTokenFailure());
        return updateNoteBloc;
      },
      act: (bloc) => bloc.add(GetNote()),
      expect: () => [
        const UpdateNoteState(
          getNoteStatus: GetNoteStatus.loading,
          getNoteFailure: null,
          note: null,
          status: UpdateNoteStatus.initial,
          failure: null,
        ),
        const UpdateNoteState(
          getNoteStatus: GetNoteStatus.tokenExpired,
          getNoteFailure: null,
          note: null,
          status: UpdateNoteStatus.initial,
          failure: null,
        ),
      ],
    );

    // Scenario - Get note fails with a Failure
    blocTest<UpdateNoteBloc, UpdateNoteState>(
      'Emits [loading, failure] get note statuses with the failure when [GetNote] is added and throws a Failure.',
      build: () {
        when(
          () => mockNoteService.getNote(),
        ).thenThrow(const ClientExceptionFailure());
        return updateNoteBloc;
      },
      act: (bloc) => bloc.add(GetNote()),
      expect: () => [
        const UpdateNoteState(
          getNoteStatus: GetNoteStatus.loading,
          getNoteFailure: null,
          note: null,
          status: UpdateNoteStatus.initial,
          failure: null,
        ),
        const UpdateNoteState(
          getNoteStatus: GetNoteStatus.failure,
          getNoteFailure: ClientExceptionFailure(),
          note: null,
          status: UpdateNoteStatus.initial,
          failure: null,
        ),
      ],
    );

    // Scenario - Get note fails with an unexpected exception
    blocTest<UpdateNoteBloc, UpdateNoteState>(
      'Emits [loading, failure] get note statuses with null failure when [GetNote] is added and throws an unexpected exception.',
      build: () {
        when(
          () => mockNoteService.getNote(),
        ).thenThrow(Exception('Unexpected error'));
        return updateNoteBloc;
      },
      act: (bloc) => bloc.add(GetNote()),
      expect: () => [
        const UpdateNoteState(
          getNoteStatus: GetNoteStatus.loading,
          getNoteFailure: null,
          note: null,
          status: UpdateNoteStatus.initial,
          failure: null,
        ),
        const UpdateNoteState(
          getNoteStatus: GetNoteStatus.failure,
          getNoteFailure: null,
          note: null,
          status: UpdateNoteStatus.initial,
          failure: null,
        ),
      ],
    );
  });

  group('[UpdateNote] tests -', () {
    // Scenario - Update note is successful
    blocTest<UpdateNoteBloc, UpdateNoteState>(
      'Emits [loading, success] statuses and carries the updated note when [UpdateNote] is added and the request succeeds.',
      build: () {
        when(
          () => mockNoteService.updateNote(
            updateNoteRequest: any(named: 'updateNoteRequest'),
          ),
        ).thenAnswer((_) async => {'data': fakeNoteJson});
        return updateNoteBloc;
      },
      act: (bloc) => bloc.add(UpdateNote(updateNoteRequest: fakeRequest)),
      expect: () => [
        const UpdateNoteState(
          getNoteStatus: GetNoteStatus.initial,
          getNoteFailure: null,
          note: null,
          status: UpdateNoteStatus.loading,
          failure: null,
        ),
        UpdateNoteState(
          getNoteStatus: GetNoteStatus.initial,
          getNoteFailure: null,
          note: fakeNote,
          status: UpdateNoteStatus.success,
          failure: null,
        ),
      ],
    );

    // Scenario - Update note fails with an InvalidTokenFailure
    blocTest<UpdateNoteBloc, UpdateNoteState>(
      'Emits [loading, tokenExpired] statuses when [UpdateNote] is added and throws InvalidTokenFailure.',
      build: () {
        when(
          () => mockNoteService.updateNote(
            updateNoteRequest: any(named: 'updateNoteRequest'),
          ),
        ).thenThrow(const InvalidTokenFailure());
        return updateNoteBloc;
      },
      act: (bloc) => bloc.add(UpdateNote(updateNoteRequest: fakeRequest)),
      expect: () => [
        const UpdateNoteState(
          getNoteStatus: GetNoteStatus.initial,
          getNoteFailure: null,
          note: null,
          status: UpdateNoteStatus.loading,
          failure: null,
        ),
        const UpdateNoteState(
          getNoteStatus: GetNoteStatus.initial,
          getNoteFailure: null,
          note: null,
          status: UpdateNoteStatus.tokenExpired,
          failure: null,
        ),
      ],
    );

    // Scenario - Update note fails with a Failure
    blocTest<UpdateNoteBloc, UpdateNoteState>(
      'Emits [loading, failure] statuses with the failure when [UpdateNote] is added and throws a Failure.',
      build: () {
        when(
          () => mockNoteService.updateNote(
            updateNoteRequest: any(named: 'updateNoteRequest'),
          ),
        ).thenThrow(const ClientExceptionFailure());
        return updateNoteBloc;
      },
      act: (bloc) => bloc.add(UpdateNote(updateNoteRequest: fakeRequest)),
      expect: () => [
        const UpdateNoteState(
          getNoteStatus: GetNoteStatus.initial,
          getNoteFailure: null,
          note: null,
          status: UpdateNoteStatus.loading,
          failure: null,
        ),
        const UpdateNoteState(
          getNoteStatus: GetNoteStatus.initial,
          getNoteFailure: null,
          note: null,
          status: UpdateNoteStatus.failure,
          failure: ClientExceptionFailure(),
        ),
      ],
    );

    // Scenario - Update note fails with an unexpected exception
    blocTest<UpdateNoteBloc, UpdateNoteState>(
      'Emits [loading, failure] statuses with null failure when [UpdateNote] is added and throws an unexpected exception.',
      build: () {
        when(
          () => mockNoteService.updateNote(
            updateNoteRequest: any(named: 'updateNoteRequest'),
          ),
        ).thenThrow(Exception('Unexpected error'));
        return updateNoteBloc;
      },
      act: (bloc) => bloc.add(UpdateNote(updateNoteRequest: fakeRequest)),
      expect: () => [
        const UpdateNoteState(
          getNoteStatus: GetNoteStatus.initial,
          getNoteFailure: null,
          note: null,
          status: UpdateNoteStatus.loading,
          failure: null,
        ),
        const UpdateNoteState(
          getNoteStatus: GetNoteStatus.initial,
          getNoteFailure: null,
          note: null,
          status: UpdateNoteStatus.failure,
          failure: null,
        ),
      ],
    );
  });
}
