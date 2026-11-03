// A category's icon, or the person's own image, on a soft tile in the category's colour.

import 'dart:io';

import 'package:flutter/material.dart';

import '../../data/database/app_database.dart';
import '../icons/ledger_icon.dart';
import '../theme/ledgerly_colors.dart';

class CategoryAvatar extends StatelessWidget {
  const CategoryAvatar({
    super.key,
    required this.icon,
    required this.colorSlot,
    this.imagePath,
    this.size = 40,
  });

  factory CategoryAvatar.of(LedgerCategory? c, {double size = 40}) => CategoryAvatar(
    icon: c?.icon ?? 'flag',
    colorSlot: c?.colorSlot ?? 0,
    imagePath: c?.imagePath,
    size: size,
  );

  final String icon;
  final int colorSlot;
  final String? imagePath;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final image = imagePath == null ? null : File(imagePath!);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(8)),
      clipBehavior: Clip.antiAlias,
      alignment: Alignment.center,
      child: image != null && image.existsSync()
          ? Image.file(image, width: size, height: size, fit: BoxFit.cover)
          : LedgerIcon(icon, size: size >= 40 ? 20 : 16, color: c.category(colorSlot)),
    );
  }
}
