import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const _view = ValueKey<String>('view');

/// White rows of 100 on black in a view of 400, so a faded edge goes dark.
Widget list(int rows, {ScrollController? controller}) => Directionality(
  textDirection: TextDirection.ltr,
  child: Center(
    child: RepaintBoundary(
      key: _view,
      child: SizedBox(
        width: 100,
        height: 400,
        child: ColoredBox(
          color: const Color(0xFF000000),
          child: ScrollEdgeFade(
            child: ListView(
              controller: controller,
              children: [
                for (var i = 0; i < rows; i++)
                  const SizedBox(
                    height: 100,
                    child: ColoredBox(color: Color(0xFFFFFFFF)),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  ),
);

/// How bright the top and the bottom lines of the view are, from 0 to 255.
Future<({int top, int bottom})> edgesOf(WidgetTester tester) async {
  final view = tester.renderObject<RenderRepaintBoundary>(find.byKey(_view));
  final image = (await tester.runAsync(view.toImage))!;
  final bytes = (await tester.runAsync(image.toByteData))!;
  int redAt(int y) => bytes.getUint8((y * image.width + image.width ~/ 2) * 4);
  return (top: redAt(0), bottom: redAt(image.height - 1));
}

void main() {
  testWidgets('fades the bottom while more lies below', (tester) async {
    await tester.pumpWidget(list(10));
    await tester.pump();

    final edges = await edgesOf(tester);
    expect(edges.top, greaterThan(240));
    expect(edges.bottom, lessThan(16));
  });

  testWidgets('fades the top, and not the bottom, at the end', (
    tester,
  ) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(list(10, controller: controller));
    controller.jumpTo(controller.position.maxScrollExtent);
    await tester.pump();

    final edges = await edgesOf(tester);
    expect(edges.top, lessThan(16));
    expect(edges.bottom, greaterThan(240));
  });

  testWidgets('deepens over the first stretch of scrolling', (tester) async {
    final controller = ScrollController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(list(10, controller: controller));
    controller.jumpTo(BirkaTokens.sizeScrollEdge / 2);
    await tester.pump();

    expect((await edgesOf(tester)).top, inInclusiveRange(96, 160));
  });

  testWidgets('leaves alone a list that fits', (tester) async {
    await tester.pumpWidget(list(4));
    await tester.pump();

    final edges = await edgesOf(tester);
    expect(edges.top, greaterThan(240));
    expect(edges.bottom, greaterThan(240));
  });
}
