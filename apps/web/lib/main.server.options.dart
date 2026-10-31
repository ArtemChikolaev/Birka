// dart format off
// ignore_for_file: type=lint

// GENERATED FILE, DO NOT MODIFY
// Generated with jaspr_builder

import 'package:jaspr/server.dart';
import 'package:accounts_jaspr/src/presentation/components/account_row.dart'
    as _account_row;
import 'package:accounts_jaspr/src/presentation/pages/account_form_page.dart'
    as _account_form_page;
import 'package:accounts_jaspr/src/presentation/pages/accounts_page.dart'
    as _accounts_page;
import 'package:birka_web/components/capital_preview.dart' as _capital_preview;
import 'package:birka_web/pages/accounts_island.dart' as _accounts_island;
import 'package:birka_web/pages/categories_island.dart' as _categories_island;
import 'package:birka_web/pages/home_route.dart' as _home_route;
import 'package:birka_web/pages/more_island.dart' as _more_island;
import 'package:birka_web/pages/more_page.dart' as _more_page;
import 'package:birka_web/pages/operations_island.dart' as _operations_island;
import 'package:birka_web/pages/overview_island.dart' as _overview_island;
import 'package:birka_web/pages/page_frame.dart' as _page_frame;
import 'package:birka_web/pages/reports_island.dart' as _reports_island;
import 'package:categories_jaspr/src/presentation/pages/categories_page.dart'
    as _categories_page;
import 'package:categories_jaspr/src/presentation/pages/category_form_page.dart'
    as _category_form_page;
import 'package:design_jaspr/src/account_card.dart' as _account_card;
import 'package:design_jaspr/src/ambient_background.dart'
    as _ambient_background;
import 'package:design_jaspr/src/amount_text.dart' as _amount_text;
import 'package:design_jaspr/src/birka_bars.dart' as _birka_bars;
import 'package:design_jaspr/src/birka_button.dart' as _birka_button;
import 'package:design_jaspr/src/birka_chip.dart' as _birka_chip;
import 'package:design_jaspr/src/birka_chip_field.dart' as _birka_chip_field;
import 'package:design_jaspr/src/birka_choice.dart' as _birka_choice;
import 'package:design_jaspr/src/birka_column.dart' as _birka_column;
import 'package:design_jaspr/src/birka_date_chip.dart' as _birka_date_chip;
import 'package:design_jaspr/src/birka_form.dart' as _birka_form;
import 'package:design_jaspr/src/birka_head.dart' as _birka_head;
import 'package:design_jaspr/src/birka_icon.dart' as _birka_icon;
import 'package:design_jaspr/src/birka_line_chart.dart' as _birka_line_chart;
import 'package:design_jaspr/src/birka_placeholder.dart' as _birka_placeholder;
import 'package:design_jaspr/src/birka_ring.dart' as _birka_ring;
import 'package:design_jaspr/src/birka_switch.dart' as _birka_switch;
import 'package:design_jaspr/src/birka_text_field.dart' as _birka_text_field;
import 'package:design_jaspr/src/card_art.dart' as _card_art;
import 'package:design_jaspr/src/glass_icon_button.dart' as _glass_icon_button;
import 'package:design_jaspr/src/glass_keypad.dart' as _glass_keypad;
import 'package:design_jaspr/src/glass_list.dart' as _glass_list;
import 'package:design_jaspr/src/glass_nav_bar.dart' as _glass_nav_bar;
import 'package:design_jaspr/src/glass_notice.dart' as _glass_notice;
import 'package:design_jaspr/src/glass_page_header.dart' as _glass_page_header;
import 'package:design_jaspr/src/glass_search_field.dart'
    as _glass_search_field;
import 'package:design_jaspr/src/glass_segmented.dart' as _glass_segmented;
import 'package:design_jaspr/src/glass_surface.dart' as _glass_surface;
import 'package:design_jaspr/src/glyph_badge.dart' as _glyph_badge;
import 'package:design_jaspr/src/section_label.dart' as _section_label;
import 'package:overview_jaspr/src/presentation/pages/overview_page.dart'
    as _overview_page;
import 'package:reports_jaspr/src/presentation/pages/reports_page.dart'
    as _reports_page;
import 'package:transactions_jaspr/src/presentation/components/quick_add_tile.dart'
    as _quick_add_tile;
import 'package:transactions_jaspr/src/presentation/pages/operation_page.dart'
    as _operation_page;
import 'package:transactions_jaspr/src/presentation/pages/operations_page.dart'
    as _operations_page;
import 'package:transactions_jaspr/src/presentation/pages/quick_add_page.dart'
    as _quick_add_page;

/// Default [ServerOptions] for use with your Jaspr project.
///
/// Use this to initialize Jaspr **before** calling [runApp].
///
/// Example:
/// ```dart
/// import 'main.server.options.dart';
///
/// void main() {
///   Jaspr.initializeApp(
///     options: defaultServerOptions,
///   );
///
///   runApp(...);
/// }
/// ```
ServerOptions get defaultServerOptions => ServerOptions(
  clientId: 'main.client.dart.js',
  clients: {
    _capital_preview.CapitalPreview:
        ClientTarget<_capital_preview.CapitalPreview>('capital_preview'),
    _accounts_island.AccountsIsland:
        ClientTarget<_accounts_island.AccountsIsland>('accounts_island'),
    _categories_island.CategoriesIsland:
        ClientTarget<_categories_island.CategoriesIsland>('categories_island'),
    _more_island.MoreIsland: ClientTarget<_more_island.MoreIsland>(
      'more_island',
    ),
    _operations_island.OperationsIsland:
        ClientTarget<_operations_island.OperationsIsland>('operations_island'),
    _overview_island.OverviewIsland:
        ClientTarget<_overview_island.OverviewIsland>('overview_island'),
    _reports_island.ReportsIsland: ClientTarget<_reports_island.ReportsIsland>(
      'reports_island',
    ),
  },
  styles: () => [
    ..._account_row.AccountRow.styles,
    ..._account_form_page.AccountFormPage.styles,
    ..._accounts_page.AccountsPage.styles,
    ..._capital_preview.CapitalPreview.styles,
    ..._home_route.HomeRoute.styles,
    ..._more_page.MorePage.styles,
    ..._page_frame.PageFrame.styles,
    ..._categories_page.CategoriesPage.styles,
    ..._category_form_page.CategoryFormPage.styles,
    ..._account_card.AccountCard.styles,
    ..._ambient_background.AmbientBackground.styles,
    ..._amount_text.AmountText.styles,
    ..._birka_bars.BirkaBars.styles,
    ..._birka_button.BirkaButton.styles,
    ..._birka_chip.BirkaChip.styles,
    ..._birka_chip_field.BirkaChipField.styles,
    ..._birka_choice.BirkaChoice.styles,
    ..._birka_column.BirkaColumn.styles,
    ..._birka_date_chip.BirkaDateChip.styles,
    ..._birka_form.BirkaForm.styles,
    ..._birka_head.birkaBaseStyles,
    ..._birka_icon.BirkaIcon.styles,
    ..._birka_line_chart.BirkaLineChart.styles,
    ..._birka_placeholder.BirkaPlaceholder.styles,
    ..._birka_ring.BirkaRing.styles,
    ..._birka_switch.BirkaSwitch.styles,
    ..._birka_text_field.BirkaTextField.styles,
    ..._card_art.CardArtSurface.styles,
    ..._card_art.CardArtThumbnail.styles,
    ..._glass_icon_button.GlassIconButton.styles,
    ..._glass_keypad.GlassKeypad.styles,
    ..._glass_list.GlassListGroup.styles,
    ..._glass_list.GlassListRow.styles,
    ..._glass_nav_bar.GlassNavBar.styles,
    ..._glass_notice.GlassNotice.styles,
    ..._glass_page_header.GlassPageHeader.styles,
    ..._glass_search_field.GlassSearchField.styles,
    ..._glass_segmented.GlassSegmented.styles,
    ..._glass_surface.GlassSurface.styles,
    ..._glyph_badge.GlyphBadge.styles,
    ..._section_label.SectionLabel.styles,
    ..._overview_page.OverviewPage.styles,
    ..._reports_page.ReportsPage.styles,
    ..._quick_add_tile.QuickAddTile.styles,
    ..._quick_add_tile.QuickAddTiles.styles,
    ..._operation_page.OperationPage.styles,
    ..._operations_page.OperationsPage.styles,
    ..._quick_add_page.QuickAddPage.styles,
  ],
);
