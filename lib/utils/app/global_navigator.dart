import 'package:flutter/material.dart';

/// Lets code above MaterialApp (e.g. the checkout listeners in app.dart) show
/// dialogs on whichever screen is open.
final GlobalKey<NavigatorState> globalNavigatorKey =
    GlobalKey<NavigatorState>();

/// Lets code above MaterialApp show snackbars on whichever screen is open.
final GlobalKey<ScaffoldMessengerState> globalScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();
