import 'dart:convert';

import 'package:accounts_common/accounts_common.dart';
import 'package:accounts_flutter/accounts_flutter.dart';
import 'package:birka_mobile/app/app.dart';
import 'package:birka_mobile/app/placeholder_page.dart';
import 'package:categories_common/categories_common.dart';
import 'package:categories_flutter/categories_flutter.dart';
import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:l10n/l10n.dart';

/// The accounts in memory: the app under test needs no database.
final class _NoAccounts implements AccountsRepository {
  @override
  Stream<List<AccountBalance>> watchAccounts() => Stream.value(const []);

  @override
  Future<Account?> account(String id) async => null;

  @override
  Future<void> add(AccountDraft draft) async {}

  @override
  Future<void> update(String id, AccountDraft draft) async {}

  @override
  Future<void> setArchived(String id, {required bool archived}) async {}
}

final class _NoCategories implements CategoriesRepository {
  @override
  Stream<List<Category>> watchCategories(CategoryKind kind) =>
      Stream.value(const []);

  @override
  Future<Category?> category(String id) async => null;

  @override
  Future<void> add(CategoryDraft draft) async {}

  @override
  Future<void> addAll(List<CategoryDraft> drafts) async {}

  @override
  Future<void> update(String id, CategoryDraft draft) async {}

  @override
  Future<void> setArchived(String id, {required bool archived}) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late GetIt getIt;

  setUp(() {
    getIt = GetIt.asNewInstance();
    final AccountsRepository accounts = _NoAccounts();
    final CategoriesRepository categories = _NoCategories();
    getIt
      ..registerFactory(() => AccountsCubit(accounts))
      ..registerFactoryParam<AccountFormCubit, String?, void>(
        (accountId, _) => AccountFormCubit(accounts, accountId: accountId),
      )
      ..registerFactory(() => CategoriesCubit(categories))
      ..registerFactoryParam<CategoryFormCubit, String?, CategoryKind?>(
        (categoryId, kind) => CategoryFormCubit(
          categories,
          categoryId: categoryId,
          kind: kind ?? CategoryKind.expense,
        ),
      );
  });

  testWidgets('opens on the overview', (tester) async {
    await tester.pumpWidget(BirkaApp(getIt: getIt));
    await tester.pumpAndSettle();

    // The title of the page and the label of the tab.
    expect(find.text(t.app.overview), findsNWidgets(2));
    expect(find.text(t.app.operations), findsOneWidget);
  });

  testWidgets('dresses the app in the Birka theme', (tester) async {
    await tester.pumpWidget(BirkaApp(getIt: getIt));
    await tester.pumpAndSettle();

    final theme = Theme.of(tester.element(find.byType(GlassNavBar)));
    expect(theme.extension<BirkaColors>(), same(BirkaColors.dark));
    expect(find.byType(AmbientBackground), findsOneWidget);
  });

  testWidgets('a tab opens its page, and the bar follows', (tester) async {
    await tester.pumpWidget(BirkaApp(getIt: getIt));
    await tester.pumpAndSettle();

    await tester.tap(find.text(t.app.reports));
    await tester.pumpAndSettle();

    expect(find.text(t.app.reports), findsNWidgets(2));
    final bar = tester.widget<GlassNavBar>(find.byType(GlassNavBar));
    expect(bar.selectedIndex, 2);
  });

  testWidgets('the action opens quick add, and closing returns', (
    tester,
  ) async {
    await tester.pumpWidget(BirkaApp(getIt: getIt));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel(t.app.newOperation));
    await tester.pumpAndSettle();
    expect(find.byType(QuickAddPlaceholder), findsOneWidget);
    expect(find.byType(GlassNavBar), findsNothing);

    await tester.tap(find.bySemanticsLabel(t.app.close));
    await tester.pumpAndSettle();
    expect(find.byType(QuickAddPlaceholder), findsNothing);
    expect(find.byType(GlassNavBar), findsOneWidget);
  });

  testWidgets('accounts open from the more tab, over the bar', (tester) async {
    await tester.pumpWidget(BirkaApp(getIt: getIt));
    await tester.pumpAndSettle();

    await tester.tap(find.text(t.app.more));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.accounts.title));
    await tester.pumpAndSettle();

    expect(find.byType(AccountsPage), findsOneWidget);
    expect(find.byType(GlassNavBar), findsNothing);

    await tester.tap(find.bySemanticsLabel(t.accounts.add));
    await tester.pumpAndSettle();
    expect(find.byType(AccountFormPage), findsOneWidget);

    await tester.tap(find.bySemanticsLabel(t.app.close));
    await tester.pumpAndSettle();
    expect(find.byType(AccountsPage), findsOneWidget);

    await tester.tap(find.bySemanticsLabel(t.accounts.back));
    await tester.pumpAndSettle();
    expect(find.byType(GlassNavBar), findsOneWidget);
  });

  testWidgets('categories open from the more tab with the kind on screen', (
    tester,
  ) async {
    await tester.pumpWidget(BirkaApp(getIt: getIt));
    await tester.pumpAndSettle();

    await tester.tap(find.text(t.app.more));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.categories.title));
    await tester.pumpAndSettle();
    expect(find.byType(CategoriesPage), findsOneWidget);

    await tester.tap(find.text(t.categories.income.toUpperCase()));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel(t.categories.add));
    await tester.pumpAndSettle();

    final form = tester.element(find.byType(CategoryFormPage));
    expect(
      form.read<CategoryFormCubit>().state.kind,
      CategoryKind.income,
    );

    await tester.tap(find.bySemanticsLabel(t.app.close));
    await tester.pumpAndSettle();
    expect(find.byType(CategoriesPage), findsOneWidget);
  });

  test('bundles the fonts of the design system and their licenses', () async {
    final manifest =
        jsonDecode(await rootBundle.loadString('FontManifest.json'))
            as List<Object?>;
    final families = [
      for (final font in manifest.cast<Map<String, Object?>>()) font['family'],
    ];
    expect(
      families,
      containsAll([
        for (final family in bundledFonts) 'packages/$fontPackage/$family',
      ]),
    );

    for (final family in bundledFonts) {
      final license = await rootBundle.loadString(
        'packages/$fontPackage/fonts/$family-OFL.txt',
      );
      expect(license, contains('SIL OPEN FONT LICENSE'));
    }
  });
}
