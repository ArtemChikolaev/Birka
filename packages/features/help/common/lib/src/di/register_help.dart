import 'package:get_it/get_it.dart';
import 'package:help_common/src/domain/app_about.dart';
import 'package:help_common/src/presentation/help_cubit.dart';

/// Registers the feature in [getIt], which has to know the `HelpLinks` of
/// the host. [about] reads what the letters say about the app, once, when
/// help opens for the first time.
void registerHelp(GetIt getIt, {required Future<AppAbout> Function() about}) {
  Future<AppAbout>? read;
  getIt.registerFactory(() => HelpCubit(getIt(), read ??= about()));
}
