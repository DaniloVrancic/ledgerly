// Renders the Windows app icon from the design system's SVG. Run it from app/ after the SVG
// changes:
//
//   flutter test tool/render_icons.dart
//
// It runs under `flutter test` because that gives Flutter's renderer without a window. It
// writes windows/runner/resources/app_icon.ico (16 to 256 px, each a PNG inside the ICO,
// which Windows Vista and later read) and copies the SVG to assets/brand for the app itself.

import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

const _source = '../design-system/brand/app-icon.svg';
const _viewBox = 96.0;
const _sizes = [16, 24, 32, 48, 64, 256];

void main() {
  testWidgets('render the Windows app icon', (tester) async {
    await tester.runAsync(() async {
      final svg = File(_source).readAsStringSync();
      File('assets/brand/app-icon.svg').writeAsStringSync(svg);
      final info = await vg.loadPicture(SvgStringLoader(svg), null);
      final pngs = <Uint8List>[];
      for (final size in _sizes) {
        // flutter_svg draws in view box units, so the canvas is scaled to the size wanted.
        final recorder = ui.PictureRecorder();
        ui.Canvas(recorder)
          ..scale(size / _viewBox)
          ..drawPicture(info.picture);
        final image = await recorder.endRecording().toImage(size, size);
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        pngs.add(png!.buffer.asUint8List());
      }
      File('windows/runner/resources/app_icon.ico').writeAsBytesSync(icoWithPngs(_sizes, pngs));
    });
  });
}

/// An ICO file holding [pngs], one per size: a 6-byte header, a 16-byte entry per image,
/// then the PNG data. A size of 256 is written as 0, as the format asks.
Uint8List icoWithPngs(List<int> sizes, List<Uint8List> pngs) {
  final header = ByteData(6 + 16 * sizes.length)
    ..setUint16(0, 0, Endian.little)
    ..setUint16(2, 1, Endian.little)
    ..setUint16(4, sizes.length, Endian.little);
  var offset = header.lengthInBytes;
  for (var i = 0; i < sizes.length; i++) {
    final at = 6 + 16 * i;
    header
      ..setUint8(at, sizes[i] >= 256 ? 0 : sizes[i])
      ..setUint8(at + 1, sizes[i] >= 256 ? 0 : sizes[i])
      ..setUint8(at + 2, 0)
      ..setUint8(at + 3, 0)
      ..setUint16(at + 4, 1, Endian.little)
      ..setUint16(at + 6, 32, Endian.little)
      ..setUint32(at + 8, pngs[i].length, Endian.little)
      ..setUint32(at + 12, offset, Endian.little);
    offset += pngs[i].length;
  }
  final out = BytesBuilder(copy: false)..add(header.buffer.asUint8List());
  for (final png in pngs) {
    out.add(png);
  }
  return out.takeBytes();
}
