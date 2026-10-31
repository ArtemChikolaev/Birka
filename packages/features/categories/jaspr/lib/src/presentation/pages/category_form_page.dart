import 'dart:async';

import 'package:categories_common/categories_common.dart';
import 'package:design_jaspr/design_jaspr.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_bloc/jaspr_bloc.dart';
import 'package:l10n/l10n.dart';

/// The form of a new or an existing category.
///
/// It needs a [CategoryFormCubit] above it.
class CategoryFormPage extends StatelessComponent {
  /// Creates the page. [onClose] is called when the form is done or
  /// cancelled.
  const CategoryFormPage({required this.onClose, super.key});

  /// Closes the form.
  final VoidCallback onClose;

  @override
  Component build(BuildContext context) {
    return BlocConsumer<CategoryFormCubit, CategoryFormState>(
      // A link can lead to a category that this browser does not have.
      listenWhen: (previous, current) =>
          current.status == CategoryFormStatus.saved ||
          (previous.status == CategoryFormStatus.loading &&
              current.status == CategoryFormStatus.failed),
      listener: (_, _) => onClose(),
      builder: (context, state) => switch (state.status) {
        CategoryFormStatus.loading => const div([]),
        _ => _form(context, state),
      },
    );
  }

  Component _form(BuildContext context, CategoryFormState state) {
    final cubit = context.read<CategoryFormCubit>();
    final form = t.categories.form;
    return BirkaForm(
      leading: GlyphBadge(
        glyph: BirkaGlyph.named(state.icon),
        color: state.color,
        size: 44,
      ),
      title: state.isNew ? form.newTitle : form.editTitle,
      closeLabel: t.app.close,
      onClose: onClose,
      submitLabel: form.save,
      onSubmit: () => unawaited(cubit.save()),
      submitting: state.status == CategoryFormStatus.saving,
      failure: state.status == CategoryFormStatus.failed ? form.failed : null,
      children: [
        BirkaTextField(
          label: form.name,
          value: state.name,
          hint: form.namePlaceholder,
          error: state.nameMissing ? form.nameMissing : null,
          onChanged: cubit.nameChanged,
          sentence: true,
        ),
        if (state.isNew)
          BirkaChoice(
            label: form.kind,
            children: [
              GlassSegmented<CategoryKind>(
                segments: {
                  CategoryKind.expense: t.categories.expense,
                  CategoryKind.income: t.categories.income,
                },
                selected: state.kind,
                onChanged: cubit.kindChanged,
              ),
            ],
          ),
        if (state.parents.isNotEmpty)
          BirkaChoice(
            label: form.parent,
            children: [
              BirkaChip(
                label: form.noParent,
                selected: state.parentId == null,
                onTap: () => cubit.parentChanged(null),
              ),
              for (final parent in state.parents)
                BirkaChip(
                  label: parent.name,
                  selected: parent.id == state.parentId,
                  onTap: () => cubit.parentChanged(parent.id),
                ),
            ],
          ),
        BirkaChoice(
          label: form.color,
          children: [
            div(classes: 'category-form__swatches', [
              for (final color in categoryColors)
                button(
                  classes: color == state.color
                      ? 'category-form__swatch category-form__swatch--selected'
                      : 'category-form__swatch',
                  type: ButtonType.button,
                  onClick: () => cubit.colorChanged(color),
                  attributes: {
                    'aria-label': '${form.color} ${color.substring(1)}',
                    'aria-pressed': '${color == state.color}',
                  },
                  [
                    span(
                      classes: 'category-form__dot',
                      styles: Styles(raw: {'background': color}),
                      const [],
                    ),
                  ],
                ),
            ]),
          ],
        ),
        BirkaChoice(
          label: form.icon,
          children: [
            for (final icon in categoryIcons)
              button(
                classes: 'category-form__icon',
                type: ButtonType.button,
                onClick: () => cubit.iconChanged(icon),
                attributes: {
                  'aria-label': icon,
                  'aria-pressed': '${icon == state.icon}',
                },
                [
                  GlyphBadge(
                    glyph: BirkaGlyph.named(icon),
                    color: icon == state.icon
                        ? state.color
                        : 'var(--color-text-muted)',
                    size: 44,
                  ),
                ],
              ),
          ],
        ),
        if (!state.isNew)
          GlassListGroup(
            children: [
              GlassListRow(
                title: state.archived ? form.restore : form.archive,
                onTap: cubit.toggleArchived,
              ),
            ],
          ),
      ],
    );
  }

  /// The styles of the page.
  @css
  static List<StyleRule> get styles => [
    css('.category-form__swatches').styles(
      raw: {
        'display': 'grid',
        'grid-template-columns': 'repeat(7, 1fr)',
        'width': '100%',
      },
    ),
    css('.category-form__swatch').styles(
      raw: {
        'aspect-ratio': '1',
        'background': 'none',
        'border': '2px solid transparent',
        'border-radius': 'var(--radius-pill)',
        'box-sizing': 'border-box',
        'cursor': 'pointer',
        'padding': 'var(--space-xs)',
        'transition': 'border-color var(--duration-fast)',
      },
    ),
    css('.category-form__swatch--selected').styles(
      raw: {'border-color': 'var(--color-text)'},
    ),
    css('.category-form__dot').styles(
      raw: {
        'border-radius': 'var(--radius-pill)',
        'display': 'block',
        'height': '100%',
        'width': '100%',
      },
    ),
    css('.category-form__icon').styles(
      raw: {
        'background': 'none',
        'border': '0',
        'border-radius': 'var(--radius-sm)',
        'cursor': 'pointer',
        'padding': '0',
      },
    ),
  ];
}
