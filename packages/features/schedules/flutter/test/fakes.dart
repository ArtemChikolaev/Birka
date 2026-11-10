import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

export 'package:schedules_common/testing.dart';

/// [child] in the theme of Birka on a phone, with [cubit] above it.
Widget phone<C extends StateStreamableSource<Object?>>(
  C cubit,
  Widget child,
) => MaterialApp(
  theme: BirkaTheme.dark(),
  home: BlocProvider<C>.value(value: cubit, child: child),
);
