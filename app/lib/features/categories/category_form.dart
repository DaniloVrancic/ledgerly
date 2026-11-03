// The form for a new or changed category: name, type, where it belongs, icon or own picture,
// colour, and which accounts offer it. Used in Categories and inside the Add sheet.

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../app/providers.dart';
import '../../core/ids.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/category_repository.dart';
import '../../ui/icons/ledger_icon.dart';
import '../../ui/theme/ledgerly_colors.dart';
import '../../ui/widgets/category_avatar.dart';
import '../../ui/widgets/undo.dart';

/// The icons a person can choose for a category, all from the one line set.
const pickableIcons = [
  'basket',
  'fork',
  'coffee',
  'home',
  'car',
  'bus',
  'fuel',
  'plane',
  'bag',
  'shirt',
  'gift',
  'heart',
  'pulse',
  'dumbbell',
  'sparkle',
  'paw',
  'leaf',
  'book',
  'music',
  'game',
  'ticket',
  'phone',
  'bolt',
  'wrench',
  'receipt',
  'repeat',
  'briefcase',
  'pen',
  'store',
  'trend',
  'key',
  'wallet',
  'target',
  'tag',
  'laptop',
  'dots',
];
const colourNames = [
  'Indigo',
  'Leaf',
  'Sky',
  'Orchid',
  'Pine',
  'Violet',
  'Lavender',
  'Periwinkle',
  'Olive',
  'Rose',
  'Berry',
  'Deep purple',
];

class CategoryForm extends ConsumerStatefulWidget {
  const CategoryForm({
    super.key,
    this.existing,
    this.kind = CategoryKind.expense,
    this.parentId,
    this.forAccountId,
    required this.onDone,
  });

  /// The category being changed, or null for a new one.
  final LedgerCategory? existing;
  final CategoryKind kind;

  /// Makes the new category a subcategory of this one.
  final String? parentId;

  /// When opened from the Add sheet: the account being used, so a limited category includes it.
  final String? forAccountId;

  /// Called with the category's id after it is saved.
  final ValueChanged<String> onDone;

  @override
  ConsumerState<CategoryForm> createState() => _CategoryFormState();
}

class _CategoryFormState extends ConsumerState<CategoryForm> {
  late final TextEditingController _name = TextEditingController(text: widget.existing?.name ?? '');
  late CategoryKind _kind = widget.existing == null
      ? widget.kind
      : CategoryKind.values.byName(widget.existing!.kind);
  late String? _parentId = widget.existing?.parentId ?? widget.parentId;
  late String _icon = widget.existing?.icon ?? 'tag';
  late int _color = widget.existing?.colorSlot ?? 3;
  late String? _imagePath = widget.existing?.imagePath;
  Set<String>? _accounts;
  String? _error;
  bool _saving = false;

  bool get _isNew => widget.existing == null;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final book = ref.watch(categoryBookProvider);
    final accounts = ref.watch(accountsProvider).value ?? const [];
    _accounts ??= widget.existing == null ? {} : {...?book.limits[widget.existing!.id]};
    final parent = book[_parentId];
    final isSub = _parentId != null;
    final previewName = _name.text.trim().isEmpty ? 'New category' : _name.text.trim();
    final accountText = isSub
        ? 'Inside ${parent?.name ?? ''}'
        : _accounts!.isEmpty
        ? 'All accounts'
        : accounts.where((a) => _accounts!.contains(a.id)).map((a) => a.name).join(', ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // A live preview of how it will look on chips and in lists.
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              CategoryAvatar(
                icon: _icon,
                colorSlot: isSub ? (parent?.colorSlot ?? _color) : _color,
                imagePath: _imagePath,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(previewName, style: context.text.subtitle),
                    Text(accountText, style: context.text.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _name,
          autofocus: _isNew,
          maxLength: 32,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(labelText: 'Name', hintText: 'For example Čišćenje', errorText: _error),
          onChanged: (_) => setState(() => _error = null),
        ),
        if (_isNew && widget.parentId == null) ...[
          const SizedBox(height: 8),
          SegmentedButton<CategoryKind>(
            segments: const [
              ButtonSegment(value: CategoryKind.expense, label: Text('Expense')),
              ButtonSegment(value: CategoryKind.income, label: Text('Income')),
            ],
            selected: {_kind},
            onSelectionChanged: (s) => setState(() {
              _kind = s.first;
              _parentId = null;
            }),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String?>(
            isExpanded: true,
            initialValue: _parentId,
            decoration: const InputDecoration(
              labelText: 'Inside',
              helperText: 'One level of subcategories only.',
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('Nothing, a main category')),
              for (final top in book.topLevel(_kind.name))
                DropdownMenuItem(value: top.id, child: Text(top.name)),
            ],
            onChanged: (v) => setState(() => _parentId = v),
          ),
        ],
        const SizedBox(height: 16),
        Text('Icon', style: context.text.label),
        const SizedBox(height: 8),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            for (final name in pickableIcons)
              _IconChoice(
                name: name,
                selected: _imagePath == null && _icon == name,
                onTap: () => setState(() {
                  _icon = name;
                  _imagePath = null;
                }),
              ),
          ],
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _pickImage,
          icon: const LedgerIcon('image'),
          label: Text(_imagePath == null ? 'Use my own picture' : 'Choose another picture'),
        ),
        if (!isSub) ...[
          const SizedBox(height: 16),
          Text('Colour', style: context.text.label),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var slot = 1; slot <= 12; slot++)
                Semantics(
                  label: colourNames[slot - 1],
                  selected: _color == slot,
                  button: true,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => setState(() => _color = slot),
                    child: Container(
                      width: 44,
                      height: 44,
                      alignment: Alignment.center,
                      decoration: _color == slot
                          ? BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: c.accent, width: 2),
                            )
                          : null,
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(color: c.category(slot), shape: BoxShape.circle),
                        child: _color == slot ? LedgerIcon('check', size: 16, color: c.surface1) : null,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Accounts', style: context.text.label),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('All accounts'),
            value: _accounts!.isEmpty,
            onChanged: (all) => setState(() {
              _accounts = all ? {} : {widget.forAccountId ?? (accounts.isEmpty ? '' : accounts.first.id)}
                ..remove('');
            }),
          ),
          if (_accounts!.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final a in accounts)
                  FilterChip(
                    label: Text(a.name),
                    selected: _accounts!.contains(a.id),
                    onSelected: (on) => setState(() {
                      final next = {..._accounts!};
                      on ? next.add(a.id) : next.remove(a.id);
                      if (next.isNotEmpty) _accounts = next; // At least one account stays chosen.
                    }),
                  ),
              ],
            ),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'It is offered on the Add sheet for these accounts. History and reports always keep it.',
              style: context.text.caption,
            ),
          ),
        ],
        const SizedBox(height: 16),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_isNew ? 'Save category' : 'Save changes'),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked == null) return;
    final path = await _storeSquare(await picked.readAsBytes());
    if (mounted) setState(() => _imagePath = path);
  }

  /// Crops nothing, but shrinks the picture to about 96 pixels and keeps it in the app's folder.
  Future<String> _storeSquare(List<int> bytes) async {
    final codec = await ui.instantiateImageCodec(Uint8List.fromList(bytes), targetWidth: 96);
    final frame = await codec.getNextFrame();
    final png = await frame.image.toByteData(format: ui.ImageByteFormat.png);
    final dir = Directory(p.join((await getApplicationSupportDirectory()).path, 'category_images'));
    await dir.create(recursive: true);
    final file = File(p.join(dir.path, '${newId()}.png'));
    await file.writeAsBytes(png!.buffer.asUint8List());
    return file.path;
  }

  Future<void> _save() async {
    final repo = ref.read(categoryRepositoryProvider);
    setState(() => _saving = true);
    try {
      final String id;
      if (_isNew) {
        id = await repo.create(
          name: _name.text,
          kind: _kind,
          parentId: _parentId,
          icon: _icon,
          imagePath: _imagePath,
          colorSlot: _parentId == null
              ? _color
              : (ref.read(categoryBookProvider)[_parentId]?.colorSlot ?? _color),
          accountIds: _accounts ?? {},
        );
      } else {
        id = widget.existing!.id;
        await repo.update(
          id,
          name: _name.text,
          icon: _icon,
          imagePath: _imagePath,
          clearImage: _imagePath == null,
          colorSlot: _color,
        );
        if (widget.existing!.parentId == null) await repo.setAccounts(id, _accounts ?? {});
      }
      widget.onDone(id);
    } on CategoryException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      if (mounted) showProblem(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _IconChoice extends StatelessWidget {
  const _IconChoice({required this.name, required this.selected, required this.onTap});

  final String name;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      label: name,
      selected: selected,
      button: true,
      child: Material(
        color: selected ? c.surfaceTint : c.surface2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: selected ? BorderSide(color: c.accent, width: 1.5) : BorderSide.none,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(child: LedgerIcon(name, size: 24, color: selected ? c.accent : c.textSecondary)),
          ),
        ),
      ),
    );
  }
}
