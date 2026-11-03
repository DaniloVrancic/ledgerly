// Savings goals. Money set aside for a goal stays in the person's accounts: it is not spent
// and not moved, only marked as no longer free to use. Closing a goal frees its money again.

import 'package:drift/drift.dart';

import '../../core/ids.dart';
import '../../domain/goal_plan.dart';
import '../../domain/postings.dart';
import '../database/app_database.dart';
import 'repository.dart';

class GoalWithMoves {
  const GoalWithMoves(this.goal, this.moves);

  final Goal goal;

  /// Oldest first.
  final List<GoalMove> moves;

  String get id => goal.id;
  bool get isOpen => goal.closedAt == null;
  int get savedMinor => moves.fold(0, (s, m) => s + m.amountMinor);

  GoalPlan planOn(String today) => planGoal(
        targetMinor: goal.targetMinor,
        targetDay: goal.targetDay,
        moves: [for (final m in moves) GoalMoveInput(m.day, m.amountMinor)],
        today: today,
      );
}

class GoalRepository extends Repository {
  GoalRepository(super.db, super.clock);

  /// Every goal with its money moves, open goals first.
  Stream<List<GoalWithMoves>> watchGoals() {
    final goals = (db.select(db.goals)..where((g) => g.deletedAt.isNull())..orderBy([(g) => OrderingTerm(expression: g.createdAt)])).watch();
    return goals.asyncMap((list) async {
      final moves = await (db.select(db.goalMoves)
            ..where((m) => m.deletedAt.isNull())
            ..orderBy([(m) => OrderingTerm(expression: m.day), (m) => OrderingTerm(expression: m.createdAt)]))
          .get();
      final out = [for (final g in list) GoalWithMoves(g, moves.where((m) => m.goalId == g.id).toList())];
      out.sort((a, b) => (a.isOpen ? 0 : 1).compareTo(b.isOpen ? 0 : 1));
      return out;
    });
  }

  /// Money set aside in open goals, in EUR. It is subtracted from "Free to use".
  Stream<int> watchSetAside() => db
      .customSelect(
        'SELECT COALESCE(SUM(m.amount_minor), 0) AS total FROM goal_moves m JOIN goals g ON g.id = m.goal_id '
        'WHERE m.deleted_at IS NULL AND g.deleted_at IS NULL AND g.closed_at IS NULL',
        readsFrom: {db.goalMoves, db.goals},
      )
      .watch()
      .map((rows) => rows.first.read<int>('total'));

  Future<String> create({required String name, required String icon, required int colorSlot, required int targetMinor, String? targetDay, String? accountId}) async {
    if (name.trim().isEmpty) throw RuleException('Give the goal a name.');
    if (targetMinor <= 0) throw RuleException('Enter a target above zero.');
    final id = newId();
    await db.into(db.goals).insert(GoalsCompanion.insert(
          id: id,
          name: name.trim(),
          icon: icon,
          colorSlot: Value(colorSlot),
          targetMinor: targetMinor,
          targetDay: Value(targetDay),
          accountId: Value(accountId),
          createdAt: now,
          updatedAt: now,
        ));
    return id;
  }

  Future<void> update(String id, {String? name, String? icon, int? colorSlot, int? targetMinor, String? targetDay, bool clearTargetDay = false, String? accountId}) {
    if (name != null && name.trim().isEmpty) throw RuleException('Give the goal a name.');
    if (targetMinor != null && targetMinor <= 0) throw RuleException('Enter a target above zero.');
    return (db.update(db.goals)..where((g) => g.id.equals(id))).write(GoalsCompanion(
      name: name == null ? const Value.absent() : Value(name.trim()),
      icon: icon == null ? const Value.absent() : Value(icon),
      colorSlot: colorSlot == null ? const Value.absent() : Value(colorSlot),
      targetMinor: targetMinor == null ? const Value.absent() : Value(targetMinor),
      targetDay: clearTargetDay ? const Value(null) : (targetDay == null ? const Value.absent() : Value(targetDay)),
      accountId: accountId == null ? const Value.absent() : Value(accountId),
      updatedAt: Value(now),
    ));
  }

  /// Sets money aside for a goal. [freeMinor] is what is free to use now; more cannot be set aside.
  Future<Undo> addMoney(String goalId, int amountMinor, {required int freeMinor, String? note}) async {
    if (amountMinor <= 0) throw RuleException('Enter an amount above zero.');
    if (amountMinor > freeMinor) throw RuleException('That is more than is free to use.');
    return _move(goalId, amountMinor, note);
  }

  /// Takes money back out of a goal, for example to pay for part of it early.
  Future<Undo> takeOut(String goalId, int amountMinor, {String? note}) async {
    if (amountMinor <= 0) throw RuleException('Enter an amount above zero.');
    final saved = await _saved(goalId);
    if (amountMinor > saved) throw RuleException('Only ${saved ~/ 100} is set aside for this goal.');
    return _move(goalId, -amountMinor, note);
  }

  /// Finishes a goal. Its money is free to use again, ready to pay for what it was saved for.
  Future<Undo> close(String goalId) async {
    await _setClosed(goalId, now);
    return () => _setClosed(goalId, null);
  }

  Future<Undo> delete(String goalId) async {
    await (db.update(db.goals)..where((g) => g.id.equals(goalId))).write(GoalsCompanion(deletedAt: Value(now), updatedAt: Value(now)));
    return () => (db.update(db.goals)..where((g) => g.id.equals(goalId))).write(GoalsCompanion(deletedAt: const Value(null), updatedAt: Value(now)));
  }

  Future<Undo> _move(String goalId, int amountMinor, String? note) async {
    final id = newId();
    await db.into(db.goalMoves).insert(GoalMovesCompanion.insert(
          id: id,
          goalId: goalId,
          day: today,
          amountMinor: amountMinor,
          note: Value(note),
          createdAt: now,
          updatedAt: now,
        ));
    return () => (db.delete(db.goalMoves)..where((m) => m.id.equals(id))).go();
  }

  Future<int> _saved(String goalId) async {
    final row = await db.customSelect(
      'SELECT COALESCE(SUM(amount_minor), 0) AS s FROM goal_moves WHERE goal_id = ? AND deleted_at IS NULL',
      variables: [Variable.withString(goalId)],
    ).getSingle();
    return row.read<int>('s');
  }

  Future<void> _setClosed(String goalId, DateTime? when) =>
      (db.update(db.goals)..where((g) => g.id.equals(goalId))).write(GoalsCompanion(closedAt: Value(when), updatedAt: Value(now)));
}
