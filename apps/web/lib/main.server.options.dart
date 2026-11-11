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
import 'package:backup_jaspr/src/presentation/pages/backup_page.dart'
    as _backup_page;
import 'package:birka_web/components/capital_preview.dart' as _capital_preview;
import 'package:birka_web/pages/accounts_island.dart' as _accounts_island;
import 'package:birka_web/pages/backup_island.dart' as _backup_island;
import 'package:birka_web/pages/categories_island.dart' as _categories_island;
import 'package:birka_web/pages/help_island.dart' as _help_island;
import 'package:birka_web/pages/home_route.dart' as _home_route;
import 'package:birka_web/pages/import_island.dart' as _import_island;
import 'package:birka_web/pages/inbox_island.dart' as _inbox_island;
import 'package:birka_web/pages/more_island.dart' as _more_island;
import 'package:birka_web/pages/more_page.dart' as _more_page;
import 'package:birka_web/pages/notifications_island.dart'
    as _notifications_island;
import 'package:birka_web/pages/operations_island.dart' as _operations_island;
import 'package:birka_web/pages/overview_island.dart' as _overview_island;
import 'package:birka_web/pages/page_frame.dart' as _page_frame;
import 'package:birka_web/pages/payday_island.dart' as _payday_island;
import 'package:birka_web/pages/reports_island.dart' as _reports_island;
import 'package:birka_web/pages/schedules_island.dart' as _schedules_island;
import 'package:categories_jaspr/src/presentation/pages/categories_page.dart'
    as _categories_page;
import 'package:categories_jaspr/src/presentation/pages/category_form_page.dart'
    as _category_form_page;
import 'package:design_jaspr/src/account_card.dart' as _account_card;
import 'package:design_jaspr/src/ambient_background.dart'
    as _ambient_background;
import 'package:design_jaspr/src/amount_text.dart' as _amount_text;
import 'package:design_jaspr/src/birka_arrow_button.dart'
    as _birka_arrow_button;
import 'package:design_jaspr/src/birka_bars.dart' as _birka_bars;
import 'package:design_jaspr/src/birka_button.dart' as _birka_button;
import 'package:design_jaspr/src/birka_change_pill.dart' as _birka_change_pill;
import 'package:design_jaspr/src/birka_checkbox.dart' as _birka_checkbox;
import 'package:design_jaspr/src/birka_chip.dart' as _birka_chip;
import 'package:design_jaspr/src/birka_chip_field.dart' as _birka_chip_field;
import 'package:design_jaspr/src/birka_choice.dart' as _birka_choice;
import 'package:design_jaspr/src/birka_column.dart' as _birka_column;
import 'package:design_jaspr/src/birka_date_chip.dart' as _birka_date_chip;
import 'package:design_jaspr/src/birka_fold.dart' as _birka_fold;
import 'package:design_jaspr/src/birka_form.dart' as _birka_form;
import 'package:design_jaspr/src/birka_head.dart' as _birka_head;
import 'package:design_jaspr/src/birka_icon.dart' as _birka_icon;
import 'package:design_jaspr/src/birka_line_chart.dart' as _birka_line_chart;
import 'package:design_jaspr/src/birka_placeholder.dart' as _birka_placeholder;
import 'package:design_jaspr/src/birka_ring.dart' as _birka_ring;
import 'package:design_jaspr/src/birka_select.dart' as _birka_select;
import 'package:design_jaspr/src/birka_split.dart' as _birka_split;
import 'package:design_jaspr/src/birka_step_bars.dart' as _birka_step_bars;
import 'package:design_jaspr/src/birka_switch.dart' as _birka_switch;
import 'package:design_jaspr/src/birka_text_field.dart' as _birka_text_field;
import 'package:design_jaspr/src/card_art.dart' as _card_art;
import 'package:design_jaspr/src/dot_badge.dart' as _dot_badge;
import 'package:design_jaspr/src/file_drop_zone.dart' as _file_drop_zone;
import 'package:design_jaspr/src/forecast_chart.dart' as _forecast_chart;
import 'package:design_jaspr/src/glass_icon_button.dart' as _glass_icon_button;
import 'package:design_jaspr/src/glass_keypad.dart' as _glass_keypad;
import 'package:design_jaspr/src/glass_list.dart' as _glass_list;
import 'package:design_jaspr/src/glass_nav_bar.dart' as _glass_nav_bar;
import 'package:design_jaspr/src/glass_notice.dart' as _glass_notice;
import 'package:design_jaspr/src/glass_option.dart' as _glass_option;
import 'package:design_jaspr/src/glass_page_header.dart' as _glass_page_header;
import 'package:design_jaspr/src/glass_search_field.dart'
    as _glass_search_field;
import 'package:design_jaspr/src/glass_segmented.dart' as _glass_segmented;
import 'package:design_jaspr/src/glass_step_pills.dart' as _glass_step_pills;
import 'package:design_jaspr/src/glass_steps.dart' as _glass_steps;
import 'package:design_jaspr/src/glass_surface.dart' as _glass_surface;
import 'package:design_jaspr/src/glass_toast.dart' as _glass_toast;
import 'package:design_jaspr/src/glyph_badge.dart' as _glyph_badge;
import 'package:design_jaspr/src/section_label.dart' as _section_label;
import 'package:design_jaspr/src/tinted_box.dart' as _tinted_box;
import 'package:design_jaspr/src/welcome_art.dart' as _welcome_art;
import 'package:help_jaspr/src/presentation/pages/help_page.dart' as _help_page;
import 'package:import_jaspr/src/presentation/components/account_step.dart'
    as _account_step;
import 'package:import_jaspr/src/presentation/components/columns_step.dart'
    as _columns_step;
import 'package:import_jaspr/src/presentation/components/copies_step.dart'
    as _copies_step;
import 'package:import_jaspr/src/presentation/components/done_step.dart'
    as _done_step;
import 'package:import_jaspr/src/presentation/components/file_step.dart'
    as _file_step;
import 'package:import_jaspr/src/presentation/components/format_step.dart'
    as _format_step;
import 'package:import_jaspr/src/presentation/components/import_aside.dart'
    as _import_aside;
import 'package:import_jaspr/src/presentation/components/import_bits.dart'
    as _import_bits;
import 'package:import_jaspr/src/presentation/pages/import_page.dart'
    as _import_page;
import 'package:inbox_jaspr/src/presentation/components/inbox_entry.dart'
    as _inbox_entry;
import 'package:inbox_jaspr/src/presentation/components/inbox_row.dart'
    as _inbox_row;
import 'package:inbox_jaspr/src/presentation/components/pair_card.dart'
    as _pair_card;
import 'package:inbox_jaspr/src/presentation/pages/inbox_page.dart'
    as _inbox_page;
import 'package:notifications_jaspr/src/presentation/pages/notifications_page.dart'
    as _notifications_page;
import 'package:onboarding_jaspr/src/presentation/pages/onboarding_page.dart'
    as _onboarding_page;
import 'package:overview_jaspr/src/presentation/pages/overview_page.dart'
    as _overview_page;
import 'package:reports_jaspr/src/presentation/pages/reports_page.dart'
    as _reports_page;
import 'package:schedules_jaspr/src/presentation/components/schedule_bits.dart'
    as _schedule_bits;
import 'package:schedules_jaspr/src/presentation/pages/payday_page.dart'
    as _payday_page;
import 'package:schedules_jaspr/src/presentation/pages/schedule_form_page.dart'
    as _schedule_form_page;
import 'package:schedules_jaspr/src/presentation/pages/schedules_page.dart'
    as _schedules_page;
import 'package:settings_jaspr/src/presentation/components/settings_section.dart'
    as _settings_section;
import 'package:transactions_jaspr/src/presentation/components/back_header.dart'
    as _back_header;
import 'package:transactions_jaspr/src/presentation/components/operation_day_group.dart'
    as _operation_day_group;
import 'package:transactions_jaspr/src/presentation/components/quick_add_tile.dart'
    as _quick_add_tile;
import 'package:transactions_jaspr/src/presentation/pages/account_page.dart'
    as _account_page;
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
    _backup_island.BackupIsland: ClientTarget<_backup_island.BackupIsland>(
      'backup_island',
    ),
    _categories_island.CategoriesIsland:
        ClientTarget<_categories_island.CategoriesIsland>('categories_island'),
    _help_island.HelpIsland: ClientTarget<_help_island.HelpIsland>(
      'help_island',
    ),
    _import_island.ImportIsland: ClientTarget<_import_island.ImportIsland>(
      'import_island',
    ),
    _inbox_island.InboxIsland: ClientTarget<_inbox_island.InboxIsland>(
      'inbox_island',
    ),
    _more_island.MoreIsland: ClientTarget<_more_island.MoreIsland>(
      'more_island',
    ),
    _notifications_island.NotificationsIsland:
        ClientTarget<_notifications_island.NotificationsIsland>(
          'notifications_island',
        ),
    _operations_island.OperationsIsland:
        ClientTarget<_operations_island.OperationsIsland>('operations_island'),
    _overview_island.OverviewIsland:
        ClientTarget<_overview_island.OverviewIsland>('overview_island'),
    _payday_island.PaydayIsland: ClientTarget<_payday_island.PaydayIsland>(
      'payday_island',
    ),
    _reports_island.ReportsIsland: ClientTarget<_reports_island.ReportsIsland>(
      'reports_island',
    ),
    _schedules_island.SchedulesIsland:
        ClientTarget<_schedules_island.SchedulesIsland>('schedules_island'),
  },
  styles: () => [
    ..._account_row.AccountRow.styles,
    ..._account_form_page.AccountFormPage.styles,
    ..._accounts_page.AccountsPage.styles,
    ..._backup_page.BackupPage.styles,
    ..._capital_preview.CapitalPreview.styles,
    ..._home_route.HomeRoute.styles,
    ..._more_page.MorePage.styles,
    ..._page_frame.PageFrame.styles,
    ..._categories_page.CategoriesPage.styles,
    ..._category_form_page.CategoryFormPage.styles,
    ..._account_card.AccountCard.styles,
    ..._ambient_background.AmbientBackground.styles,
    ..._amount_text.AmountText.styles,
    ..._birka_arrow_button.BirkaArrowButton.styles,
    ..._birka_bars.BirkaBars.styles,
    ..._birka_button.BirkaButton.styles,
    ..._birka_change_pill.BirkaChangePill.styles,
    ..._birka_checkbox.BirkaCheckbox.styles,
    ..._birka_chip.BirkaChip.styles,
    ..._birka_chip_field.BirkaChipField.styles,
    ..._birka_choice.BirkaChoice.styles,
    ..._birka_column.BirkaColumn.styles,
    ..._birka_date_chip.BirkaDateChip.styles,
    ..._birka_fold.BirkaFold.styles,
    ..._birka_form.BirkaForm.styles,
    ..._birka_head.birkaBaseStyles,
    ..._birka_icon.BirkaIcon.styles,
    ..._birka_line_chart.BirkaLineChart.styles,
    ..._birka_placeholder.BirkaPlaceholder.styles,
    ..._birka_ring.BirkaRing.styles,
    ..._birka_select.BirkaSelect.styles,
    ..._birka_split.BirkaSplit.styles,
    ..._birka_step_bars.BirkaStepBars.styles,
    ..._birka_switch.BirkaSwitch.styles,
    ..._birka_text_field.BirkaTextField.styles,
    ..._card_art.CardArtSurface.styles,
    ..._card_art.CardArtThumbnail.styles,
    ..._dot_badge.DotBadge.styles,
    ..._file_drop_zone.FileDropZone.styles,
    ..._forecast_chart.ForecastChart.styles,
    ..._glass_icon_button.GlassIconButton.styles,
    ..._glass_keypad.GlassKeypad.styles,
    ..._glass_list.GlassListGroup.styles,
    ..._glass_list.GlassListRow.styles,
    ..._glass_nav_bar.GlassNavBar.styles,
    ..._glass_notice.GlassNotice.styles,
    ..._glass_option.GlassOption.styles,
    ..._glass_page_header.GlassPageHeader.styles,
    ..._glass_search_field.GlassSearchField.styles,
    ..._glass_segmented.GlassSegmented.styles,
    ..._glass_step_pills.GlassStepPills.styles,
    ..._glass_steps.GlassSteps.styles,
    ..._glass_surface.GlassSurface.styles,
    ..._glass_toast.GlassToast.styles,
    ..._glyph_badge.GlyphBadge.styles,
    ..._section_label.SectionLabel.styles,
    ..._tinted_box.TintedBox.styles,
    ..._tinted_box.TintedNotice.styles,
    ..._welcome_art.WelcomeArt.styles,
    ..._help_page.HelpPage.styles,
    ..._account_step.AccountStep.styles,
    ..._columns_step.ColumnsStep.styles,
    ..._copies_step.CopiesStep.styles,
    ..._done_step.DoneStep.styles,
    ..._file_step.FileStep.styles,
    ..._format_step.FormatStep.styles,
    ..._import_aside.ImportAside.styles,
    ..._import_bits.FileCard.styles,
    ..._import_bits.FormatMark.styles,
    ..._import_bits.SummaryRow.styles,
    ..._import_page.ImportPage.styles,
    ..._inbox_entry.InboxCard.styles,
    ..._inbox_entry.InboxTile.styles,
    ..._inbox_row.InboxRow.styles,
    ..._pair_card.PairCard.styles,
    ..._inbox_page.InboxPage.styles,
    ..._notifications_page.NotificationsPage.styles,
    ..._onboarding_page.OnboardingPage.styles,
    ..._overview_page.OverviewPage.styles,
    ..._reports_page.ReportsPage.styles,
    ..._schedule_bits.DateColumn.styles,
    ..._schedule_bits.ScheduleDot.styles,
    ..._payday_page.PaydayPage.styles,
    ..._schedule_form_page.ScheduleFormPage.styles,
    ..._schedules_page.SchedulesPage.styles,
    ..._settings_section.SettingsSection.styles,
    ..._back_header.BackHeader.styles,
    ..._operation_day_group.OperationDayGroup.styles,
    ..._quick_add_tile.QuickAddTile.styles,
    ..._quick_add_tile.QuickAddTiles.styles,
    ..._account_page.AccountPage.styles,
    ..._operation_page.OperationPage.styles,
    ..._operations_page.OperationsPage.styles,
    ..._quick_add_page.QuickAddPage.styles,
  ],
);
