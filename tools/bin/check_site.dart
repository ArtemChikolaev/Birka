import 'dart:io';

import 'package:birka_tools/check_site.dart';

/// Opens every page of the site built in the first argument, served under the
/// base path in the second one, and fails on what the pages report.
Future<void> main(List<String> args) async {
  final buildOnly = args.firstOrNull == '--build-only';
  final [path, base] = buildOnly ? args.sublist(1) : args;
  final site = Directory(path);
  final buildProblem = webBuildProblem(site, base: base);
  if (buildProblem != null) {
    stderr.writeln(buildProblem);
    exitCode = 1;
    return;
  }
  if (buildOnly) {
    stdout.writeln('Web build OK for BASE=$base');
    return;
  }
  final problems = await checkSite(site, base: base);
  final onGitHub = Platform.environment['GITHUB_ACTIONS'] == 'true';
  for (final problem in problems) {
    stderr.writeln(onGitHub ? '::error::$problem' : '$problem');
  }
  if (problems.isEmpty) {
    stdout.writeln('Built site: ${pagesOf(site).length} pages OK');
  } else {
    stderr.writeln('${problems.length} problem(s) on the built site');
    exitCode = 1;
  }
}
