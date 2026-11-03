import 'dart:async';

import 'package:design_flutter/src/components/in_sight.dart';
import 'package:design_flutter/src/theme/birka_motion.dart';
import 'package:flutter/widgets.dart';

/// A column whose children open when they come and close when they go.
///
/// Each child needs a key. A child that comes grows to its height over
/// `duration.slow` and fades in, and one that goes fades and shrinks away,
/// so that the others move to their places instead of jumping. Nothing moves
/// the first time the column shows, nor when the system asks for less motion;
/// a child that comes while the column is out of sight opens once it shows.
class AnimatedColumn extends StatefulWidget {
  /// Creates a column of [children].
  const AnimatedColumn({
    required this.children,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
    super.key,
  });

  /// The children, each with a key.
  final List<Widget> children;

  /// How the children line up across the column.
  final CrossAxisAlignment crossAxisAlignment;

  @override
  State<AnimatedColumn> createState() => _AnimatedColumnState();
}

class _Row {
  _Row(this.child, this.open)
    : height = open.drive(CurveTween(curve: BirkaMotion.standardCurve)),
      opacity = open.drive(
        CurveTween(curve: Interval(0.25, 1, curve: BirkaMotion.fadeCurve)),
      );

  Widget child;

  /// How far the row has opened, from 0 to 1.
  final AnimationController open;

  final Animation<double> height;
  final Animation<double> opacity;

  /// Takes the row away once it has closed, while it goes.
  AnimationStatusListener? closing;

  Key get key => child.key!;
}

class _AnimatedColumnState extends State<AnimatedColumn>
    with TickerProviderStateMixin, InSight {
  late List<_Row> _rows = [
    for (final child in widget.children) _row(child, open: true),
  ];

  _Row _row(Widget child, {required bool open}) {
    assert(child.key != null, 'Each child of an AnimatedColumn needs a key.');
    return _Row(
      child,
      AnimationController(
        vsync: this,
        duration: BirkaMotion.slow,
        value: open ? 1 : 0,
      ),
    );
  }

  @override
  void didUpdateWidget(AnimatedColumn oldWidget) {
    super.didUpdateWidget(oldWidget);
    final moves = !BirkaMotion.reduced(context);
    final before = {for (final row in _rows) row.key: row};
    final keys = {for (final child in widget.children) child.key!};
    final rows = <_Row>[];
    for (final child in widget.children) {
      final row = before[child.key];
      if (row == null) {
        rows.add(_row(child, open: !moves));
        continue;
      }
      row.child = child;
      if (row.closing case final closing?) {
        row.open.removeStatusListener(closing);
        row.closing = null;
        unawaited(row.open.forward());
      }
      rows.add(row);
    }
    // A row that goes stays after the row it followed until it has closed.
    for (final (index, row) in _rows.indexed) {
      if (keys.contains(row.key)) continue;
      if (!moves || !inSight) {
        row.open.dispose();
        continue;
      }
      final after = index == 0
          ? -1
          : rows.indexWhere((other) => other.key == _rows[index - 1].key);
      rows.insert(after + 1, row);
      _close(row);
    }
    _rows = rows;
    if (moves) whenInSight(_openComing);
  }

  void _openComing() {
    for (final row in _rows) {
      if (row.closing == null && row.open.value < 1 && !row.open.isAnimating) {
        unawaited(row.open.forward());
      }
    }
  }

  void _close(_Row row) {
    if (row.closing != null) return;
    void closed(AnimationStatus status) {
      if (!status.isDismissed) return;
      row.open.removeStatusListener(closed);
      if (mounted) setState(() => _rows.remove(row));
      row.open.dispose();
    }

    row.closing = closed;
    row.open.addStatusListener(closed);
    unawaited(row.open.reverse());
  }

  @override
  void dispose() {
    for (final row in _rows) {
      row.open.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: widget.crossAxisAlignment,
      children: [
        for (final row in _rows)
          KeyedSubtree(
            key: row.key,
            child: SizeTransition(
              sizeFactor: row.height,
              axisAlignment: -1,
              child: FadeTransition(opacity: row.opacity, child: row.child),
            ),
          ),
      ],
    );
  }
}
