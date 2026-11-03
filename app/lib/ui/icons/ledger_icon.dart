// Draws an icon from the design system's line set.

import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'icon_paths.dart';

class LedgerIcon extends StatelessWidget {
  const LedgerIcon(this.name, {super.key, this.size = 20, this.color, this.semanticLabel});

  final String name;

  /// 16, 20 or 24.
  final double size;
  final Color? color;

  /// Give a label when the icon stands alone, without text beside it.
  final String? semanticLabel;

  static bool exists(String name) => ledgerIconPaths.containsKey(name);

  @override
  Widget build(BuildContext context) {
    final path = ledgerIconPaths[name] ?? ledgerIconPaths['dots']!;
    final svg =
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#000" '
        'stroke-width="1.75" stroke-linecap="round" stroke-linejoin="round"><path d="$path"/></svg>';
    final paint = color ?? DefaultTextStyle.of(context).style.color ?? const Color(0xFF000000);
    return SvgPicture.string(
      svg,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(paint, BlendMode.srcIn),
      semanticsLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
    );
  }
}
