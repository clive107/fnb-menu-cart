import 'package:example_app/blocs/base/tabs/base_tabs_cubit.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';

class MockLogger extends Mock implements Logger {}

enum _TestTab { tabA, tabB, tabC }

class _TestTabsCubit extends BaseTabsCubit<_TestTab> {
  _TestTabsCubit({
    required super.logger,
    super.initialTab = _TestTab.tabA,
    super.onTabInitialized,
  });

  @override
  String get kTag => '[TestTabsCubit]';
}

void main() {
  late Logger mockLogger;

  setUp(() {
    mockLogger = MockLogger();
  });

  // ---------------------------------------------------------------------------
  group('Initial state -', () {
    test('state is the initial tab', () {
      final _TestTabsCubit cubit = _TestTabsCubit(logger: mockLogger);
      expect(cubit.state, _TestTab.tabA);
      cubit.close();
    });

    test('state is the provided initialTab when overridden', () {
      final _TestTabsCubit cubit = _TestTabsCubit(
        logger: mockLogger,
        initialTab: _TestTab.tabB,
      );
      expect(cubit.state, _TestTab.tabB);
      cubit.close();
    });

    test('onTabInitialized callback is called with the initial tab', () {
      final List<_TestTab> initializedTabs = [];
      _TestTabsCubit(
        logger: mockLogger,
        onTabInitialized: initializedTabs.add,
      ).close();
      expect(initializedTabs, [_TestTab.tabA]);
    });

    test(
      'constructs with initial tab when onTabInitialized is not provided',
      () {
        final _TestTabsCubit cubit = _TestTabsCubit(logger: mockLogger);
        expect(cubit.state, _TestTab.tabA);
        cubit.close();
      },
    );
  });

  // ---------------------------------------------------------------------------
  group('updateTab -', () {
    blocTest<_TestTabsCubit, _TestTab>(
      'emits new tab when updateTab is called',
      build: () => _TestTabsCubit(logger: mockLogger),
      act: (cubit) => cubit.updateTab(_TestTab.tabB),
      expect: () => [_TestTab.tabB],
    );

    blocTest<_TestTabsCubit, _TestTab>(
      'emits each tab in sequence when updateTab is called multiple times',
      build: () => _TestTabsCubit(logger: mockLogger),
      act: (cubit) {
        cubit.updateTab(_TestTab.tabB);
        cubit.updateTab(_TestTab.tabC);
      },
      expect: () => [_TestTab.tabB, _TestTab.tabC],
    );

    blocTest<_TestTabsCubit, _TestTab>(
      'emits current tab even when updateTab is called with the same tab',
      build: () => _TestTabsCubit(logger: mockLogger),
      act: (cubit) => cubit.updateTab(_TestTab.tabA),
      expect: () => [_TestTab.tabA],
    );

    blocTest<_TestTabsCubit, _TestTab>(
      'emits tab again after switching away and back',
      build: () => _TestTabsCubit(logger: mockLogger),
      act: (cubit) {
        cubit.updateTab(_TestTab.tabB);
        cubit.updateTab(_TestTab.tabA);
      },
      expect: () => [_TestTab.tabB, _TestTab.tabA],
    );
  });

  // ---------------------------------------------------------------------------
  group('resetTabs -', () {
    blocTest<_TestTabsCubit, _TestTab>(
      'emits initial tab after switching to another tab',
      build: () => _TestTabsCubit(logger: mockLogger),
      act: (cubit) {
        cubit.updateTab(_TestTab.tabB);
        cubit.resetTabs();
      },
      expect: () => [_TestTab.tabB, _TestTab.tabA],
    );

    blocTest<_TestTabsCubit, _TestTab>(
      'emits initial tab even when already at initial tab',
      build: () => _TestTabsCubit(logger: mockLogger),
      act: (cubit) => cubit.resetTabs(),
      expect: () => [_TestTab.tabA],
    );

    blocTest<_TestTabsCubit, _TestTab>(
      'emits initial tab after resetting from a custom initialTab',
      build: () =>
          _TestTabsCubit(logger: mockLogger, initialTab: _TestTab.tabC),
      act: (cubit) {
        cubit.updateTab(_TestTab.tabA);
        cubit.resetTabs();
      },
      expect: () => [_TestTab.tabA, _TestTab.tabC],
    );
  });

  // ---------------------------------------------------------------------------
  group('resetTabs then updateTab -', () {
    blocTest<_TestTabsCubit, _TestTab>(
      'can switch tabs normally after a reset',
      build: () => _TestTabsCubit(logger: mockLogger),
      act: (cubit) {
        cubit.updateTab(_TestTab.tabB);
        cubit.resetTabs();
        cubit.updateTab(_TestTab.tabC);
      },
      expect: () => [_TestTab.tabB, _TestTab.tabA, _TestTab.tabC],
    );
  });
}
