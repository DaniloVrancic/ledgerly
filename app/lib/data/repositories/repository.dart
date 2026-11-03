// What every repository shares: the database, the clock, and the Undo type.

import '../../core/clock.dart';
import '../database/app_database.dart';

/// Reverses a change. Every change a person can make returns one, for the Undo button.
typedef Undo = Future<void> Function();

abstract class Repository {
  Repository(this.db, this.clock);

  final AppDatabase db;
  final Clock clock;

  DateTime get now => clock.now();
  String get today => clock.today();
}
