import 'package:flutter/material.dart';

/// Lets code above MaterialApp (e.g. the checkout listener in app.dart) show
/// dialogs on whichever screen is open.
final GlobalKey<NavigatorState> globalNavigatorKey =
    GlobalKey<NavigatorState>();
