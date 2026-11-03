// App-wide keys, so a sheet that has just closed can still show its Undo message or open
// the next sheet.

import 'package:flutter/material.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();
final messengerKey = GlobalKey<ScaffoldMessengerState>();
