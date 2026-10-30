import 'package:categories_common/categories_common.dart';
import 'package:categories_flutter/src/presentation/widgets/category_look.dart';
import 'package:design_flutter/design_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l10n/l10n.dart';

/// The form of a new or an existing category.
///
/// It needs a [CategoryFormCubit] above it.
class CategoryFormPage extends StatelessWidget {
  /// Creates the page. [onClose] is called when the form is done or
  /// cancelled.
  const CategoryFormPage({required this.onClose, super.key});

  /// Closes the form.
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AmbientBackground(
        child: SafeArea(
          child: BlocConsumer<CategoryFormCubit, CategoryFormState>(
            listenWhen: (previous, current) =>
                previous.status != current.status,
            listener: (context, state) {
              if (state.status == CategoryFormStatus.saved) onClose();
            },
            buildWhen: (previous, current) =>
                previous.status == CategoryFormStatus.loading,
            builder: (context, state) => switch (state.status) {
              CategoryFormStatus.loading => const SizedBox.shrink(),
              _ => _Form(initial: state, onClose: onClose),
            },
          ),
        ),
      ),
    );
  }
}

class _Form extends StatefulWidget {
  const _Form({required this.initial, required this.onClose});

  final CategoryFormState initial;
  final VoidCallback onClose;

  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  late final _name = TextEditingController(text: widget.initial.name);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CategoryFormCubit>();
    final styles = BirkaTextStyles.of(context);
    final colors = BirkaColors.of(context);
    final form = t.categories.form;
    return BlocBuilder<CategoryFormCubit, CategoryFormState>(
      builder: (context, state) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              BirkaTokens.spaceLg,
              BirkaTokens.spaceXs,
              BirkaTokens.spaceLg,
              BirkaTokens.spaceSm,
            ),
            child: Row(
              children: [
                GlyphBadge(
                  glyph: glyphOf(state.icon),
                  color: colorOf(state.color),
                  size: BirkaTokens.sizeTouchTarget,
                ),
                const SizedBox(width: BirkaTokens.spaceSm),
                Expanded(
                  child: Text(
                    state.isNew ? form.newTitle : form.editTitle,
                    style: styles.heading.copyWith(color: colors.text),
                  ),
                ),
                GlassIconButton(
                  glyph: BirkaGlyph.close,
                  label: t.app.close,
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.symmetric(
                horizontal: BirkaTokens.spaceLg,
                vertical: BirkaTokens.spaceXs,
              ),
              children: [
                BirkaTextField(
                  label: form.name,
                  controller: _name,
                  hint: form.namePlaceholder,
                  error: state.nameMissing ? form.nameMissing : null,
                  onChanged: cubit.nameChanged,
                  textCapitalization: TextCapitalization.sentences,
                ),
                if (state.isNew) ...[
                  const SizedBox(height: BirkaTokens.spaceMd),
                  _Label(form.kind),
                  GlassSegmented<CategoryKind>(
                    segments: {
                      CategoryKind.expense: t.categories.expense,
                      CategoryKind.income: t.categories.income,
                    },
                    selected: state.kind,
                    onChanged: cubit.kindChanged,
                  ),
                ],
                if (state.parents.isNotEmpty) ...[
                  const SizedBox(height: BirkaTokens.spaceMd),
                  _Label(form.parent),
                  Wrap(
                    spacing: BirkaTokens.spaceXs,
                    runSpacing: BirkaTokens.spaceXs,
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
                ],
                const SizedBox(height: BirkaTokens.spaceMd),
                _Label(form.color),
                Row(
                  children: [
                    for (final color in categoryColors)
                      Expanded(
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: _Swatch(
                            color: colorOf(color),
                            selected: color == state.color,
                            label: '${form.color} ${color.substring(1)}',
                            onTap: () => cubit.colorChanged(color),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: BirkaTokens.spaceMd),
                _Label(form.icon),
                Wrap(
                  spacing: BirkaTokens.spaceSm,
                  runSpacing: BirkaTokens.spaceSm,
                  children: [
                    for (final icon in categoryIcons)
                      Semantics(
                        button: true,
                        selected: icon == state.icon,
                        label: icon,
                        excludeSemantics: true,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => cubit.iconChanged(icon),
                          child: GlyphBadge(
                            glyph: glyphOf(icon),
                            color: icon == state.icon
                                ? colorOf(state.color)
                                : colors.textMuted,
                            size: BirkaTokens.sizeTouchTarget,
                          ),
                        ),
                      ),
                  ],
                ),
                if (!state.isNew) ...[
                  const SizedBox(height: BirkaTokens.spaceLg),
                  GlassListGroup(
                    children: [
                      GlassListRow(
                        title: state.archived ? form.restore : form.archive,
                        onTap: cubit.toggleArchived,
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: BirkaTokens.spaceMd),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              BirkaTokens.spaceLg,
              BirkaTokens.spaceXs,
              BirkaTokens.spaceLg,
              BirkaTokens.spaceMd,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (state.status == CategoryFormStatus.failed) ...[
                  Text(
                    form.failed,
                    textAlign: TextAlign.center,
                    style: styles.caption.copyWith(color: colors.negative),
                  ),
                  const SizedBox(height: BirkaTokens.spaceXs),
                ],
                BirkaButton(
                  label: form.save,
                  onPressed: state.status == CategoryFormStatus.saving
                      ? null
                      : cubit.save,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: BirkaTokens.spaceXs),
      child: Text(
        text,
        style: BirkaTextStyles.of(
          context,
        ).caption.copyWith(color: BirkaColors.of(context).textMuted),
      ),
    );
  }
}

/// A round sample of a color, with a ring when it is picked.
class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.selected,
    required this.label,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = BirkaColors.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(BirkaTokens.spaceXs),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? colors.text : const Color(0x00000000),
              width: 2,
            ),
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }
}
