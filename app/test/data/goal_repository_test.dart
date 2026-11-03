import 'package:flutter_test/flutter_test.dart';
import 'package:ledgerly/domain/postings.dart';

import 'test_ledger.dart';

void main() {
  late TestLedger l;
  setUp(() async => l = await TestLedger.create());
  tearDown(() => l.dispose());

  test('money set aside is no longer free, and closing frees it', () async {
    final id = await l.goals.create(
      name: 'New laptop',
      icon: 'laptop',
      colorSlot: 3,
      targetMinor: 120000,
      targetDay: '2027-05-01',
    );
    await l.goals.addMoney(id, 30000, freeMinor: 100000);
    expect(await l.goals.watchSetAside().first, 30000);
    final goal = (await l.goals.watchGoals().first).single;
    expect(goal.savedMinor, 30000);
    expect(goal.planOn('2026-10-29').perMonthNeededMinor, 15000);
    final undo = await l.goals.close(id);
    expect(await l.goals.watchSetAside().first, 0);
    await undo();
    expect(await l.goals.watchSetAside().first, 30000);
  });

  test('setting money aside does not move or spend it', () async {
    final id = await l.goals.create(name: 'Trip', icon: 'plane', colorSlot: 8, targetMinor: 50000);
    await l.goals.addMoney(id, 20000, freeMinor: 100000);
    expect(await l.balance(l.bank), 100000);
    expect((await l.entries.totals('2026-10-01', '2026-10-31')).spendingMinor, 0);
  });

  test('cannot set aside more than is free, or take out more than is saved', () async {
    final id = await l.goals.create(name: 'Trip', icon: 'plane', colorSlot: 8, targetMinor: 50000);
    expect(() => l.goals.addMoney(id, 20000, freeMinor: 10000), throwsA(isA<RuleException>()));
    await l.goals.addMoney(id, 5000, freeMinor: 10000);
    expect(() => l.goals.takeOut(id, 6000), throwsA(isA<RuleException>()));
    final undo = await l.goals.takeOut(id, 2000);
    expect((await l.goals.watchGoals().first).single.savedMinor, 3000);
    await undo();
    expect((await l.goals.watchGoals().first).single.savedMinor, 5000);
  });
}
