import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logger/logger.dart';

abstract class BaseTabsCubit<T> extends Cubit<T> {
  final Logger _logger;
  final T _initialTab;
  final Set<T> _initializedTabs = {};
  final void Function(T)? _onTabInitialized;

  BaseTabsCubit({
    required Logger logger,
    required T initialTab,
    void Function(T)? onTabInitialized,
  }) : _logger = logger,
       _initialTab = initialTab,
       _onTabInitialized = onTabInitialized,
       super(initialTab) {
    // Mark the initial tab as initialized
    _markTabAsInitialized(initialTab);
    _onTabInitialized?.call(initialTab);
  }

  String get kTag;

  void updateTab(T newTab) {
    _logger.d('$kTag updateTab: $newTab');
    // Only mark as initialized if it's a new tab
    if (!_initializedTabs.contains(newTab)) {
      _markTabAsInitialized(newTab);
    }
    emit(newTab);
  }

  void _markTabAsInitialized(T tab) {
    _initializedTabs.add(tab);
    _logger.d('$kTag Tab marked as initialized: $tab');
  }

  void resetTabs() {
    _initializedTabs.clear();
    _logger.d('$kTag resetTabs: All tabs have been reset');
    emit(_initialTab);
  }
}
