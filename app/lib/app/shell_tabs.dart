// Which main tab is showing, so any screen can switch to another tab.

import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppTab { home, entries, insights, more }

class SelectedTab extends Notifier<AppTab> {
  @override
  AppTab build() => AppTab.home;

  void show(AppTab tab) => state = tab;
}

final selectedTabProvider = NotifierProvider<SelectedTab, AppTab>(SelectedTab.new);
