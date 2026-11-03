// Ids are UUIDv7: time ordered and unique across devices, so a later sync never collides.

import 'package:uuid/uuid.dart';

const _uuid = Uuid();

String newId() => _uuid.v7();
