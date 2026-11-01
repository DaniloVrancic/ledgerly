# Usage rules

Short do and don't examples for every component.

| Component | Do | Don't |
|---|---|---|
| ColourTokens | Use `negative` for an expense amount as text. | Use `negative-fill` for text. It only reaches 3:1. |
| TypeScale | Set money in `balance`, `amount-large`, `amount` or `amount-small`. | Set text below 12px, or body text below 14px. |
| Money | Show the original amount first and the conversion smaller below it. | Use a hyphen as a minus, or colour without a sign. |
| HiddenAmounts | Mask with the same dots whatever the length, so the mask reveals nothing. | Leave chart axes or the real value in the accessibility tree. The app must render the label "Hidden amount" instead. |
| IconSet | Give an icon a label when it stands alone. | Mix filled icons or another set. |
| Button | Use one primary button per view. | Use coral for a normal action. Danger is only for delete and reset. |
| TextInput | Keep the label above the field. | Use the placeholder as the label. |
| SearchField | Let 12.50 find amounts. | Add a Search or Apply button. |
| Switch | Apply the change immediately. | Pair it with a Save button. |
| SegmentedControl | Keep labels to one word. | Use it for actions. |
| Checkbox | Use it in multi-select and report sections. | Use it for one instant setting. That is a switch. |
| Card | Keep padding at `space-4`. | Nest cards. |
| ListRow | Let long Bosnian names wrap. | Truncate amounts. |
| SectionHeader | Keep it to two or three words. | Add more than one action. |
| Tooltip | Define every metric the same way everywhere. | Put actions in a tooltip. |
| BottomSheet | Keep actions at the bottom, in thumb reach. | Stack two sheets. |
| Dialog | Name the action on the button. | Use a dialog when Undo would work. |
| Toast | Say what happened, then offer Undo. | Celebrate. No exclamation marks. |
| BottomNav | Keep Add in the centre on every screen. | Show more than five items. |
| NavRail | Keep labels available to screen readers. | Stretch the phone bar across a tablet. |
| Sidebar | Keep the file date visible at all times. | Add an Add button. Desktop is read-only. |
| ReadOnlyLabel | Show the date and time of the file. | Hide it to save space. |
| StatePatterns | Use the line ledger with one icon rising out of it. | Use full-colour illustrations, mascots or guilt. |
| Keypad | Keep keys 56px tall or taller and the pad at phone width, 360px at most. | Stretch the pad across a wide layout. Keys turn into thin bars. |
| CategoryChip | Let chips take the width their label needs and flow onto the next row. | Force chips into equal columns. Long names clip. |
| AddTransaction | Save on the chip tap. Show Undo and Add another afterwards. | Add a Save button to the normal flow. |
| TransactionRow | Pair every colour with a sign. | Show more than the small icons in a row. |
| TransferRow | Name both accounts. | Colour it green or coral. |
| DayGroupHeader | Always show the sign. | Count transfers in the daily net. |
| BalanceCard | Keep Total balance, Earmarked for goals and Free to use separate. | Add anything larger on the same screen. |
| MetricTile | Keep the definition one tap away. | Invent a new metric name. |
| BudgetBar | State the percentage in words beside the bar. | Rely on the bar colour alone. |
| GoalProgress | Call it earmarked. | Subtract it from the total balance. |
| NeedsAttentionRow | Show at most three on Home, hidden when empty. | Link away when the action can run in the row. |
| RecurringBadge | Keep icon and word together. | Post silently. |
| CalendarDayCell | Show the sign and the currency in every cell. | Use the shade alone. |
| BackupStatus | Say that the data is safe when it is. | Imply a server or an online state. |
| QuickAddWidget | Open straight to the keypad. | Put any amount on the home screen. |
| CategoryIdentity | Pick colours from the set. Income categories share colours with expense categories because they never appear in one chart. | Offer a free colour picker. |
| CategoryRow | Name the accounts on the row. | Hide which accounts a category uses. |
| IconPicker | Offer the whole set and an image upload. | Limit people to one icon per category family. |
| CategoryColourPicker | Mark the selected colour with a tick and a ring. | Rely on the colour alone to show selection. |
| AccountPicker | Default to All accounts. | Allow saving with no account chosen. |
| CategoryEditor | Show a live preview at the top. | Make people leave the Add sheet to create one. |
| ChartGroupedBars | Start the axis at zero. | Use a second axis for net. |
| ChartDonut | Colour by rank, and name the category with its icon. | Add a seventh slice. Group the rest as Other. |
| ChartTrendLines | Label the line ends. | Rely on a legend. |
| ChartWeekdayBars | Label each bar. | Sort the days. |
| ChartBalanceLine | Start at zero unless values cross it. | Fill under the line with a gradient. |
| ChartCalendarHeat | Show plus or minus and the currency in every cell. | Leave blank gaps at the start of a month. |
| ChartYearLedger | Keep days in columns, so rent and payday line up down the year. | Use a grid of squares by week. |
| ChartPalette | Reuse slot 1 for the largest item. | Use semantic colours as slots. |
| ChartEmpty | Keep the question as the title. | Draw fake data. |
| AppIcon | Use it at 32px or larger in the interface. | Add currency signs or income and expense colours. The mark stays forest and mint. |
| PrintStyle | Use patterns and words instead of colour. | Print the dark theme. |
| ScreenHome | Check figures against the other screens. | Treat this as implemented. |
| ScreenAddTransaction | Tap the account pill and watch the chips follow it. | Treat this as implemented. |
| ScreenCategories | Add a category and watch it join the list. | Treat this as implemented. |
| ScreenCategoryEditor | Change the icon, colour and accounts. | Treat this as implemented. |
| ScreenHistory | Check the daily totals against Calendar. | Treat this as implemented. |
| ScreenCalendar | Tap a day to see its details. | Treat this as implemented. |
| ScreenAnalytics | Select a bar to see its figures. | Treat this as implemented. |
