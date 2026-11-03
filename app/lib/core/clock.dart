// Code that depends on today's date asks a Clock, so tests can fix the date.

import 'day.dart';

abstract class Clock {
  DateTime now();

  /// Today as a local calendar day.
  String today() => Day.of(now());
}

class SystemClock extends Clock {
  @override
  DateTime now() => DateTime.now();
}

class FixedClock extends Clock {
  FixedClock(this.value);

  DateTime value;

  @override
  DateTime now() => value;
}
