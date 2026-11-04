import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:help_common/src/domain/app_about.dart';
import 'package:help_common/src/domain/contacts.dart';
import 'package:help_common/src/domain/help_letter.dart';
import 'package:help_common/src/domain/help_links.dart';
import 'package:meta/meta.dart';

/// What came of the last way out, for a short message on the screen.
@immutable
sealed class HelpNotice {
  const HelpNotice();
}

/// No mail app opened the letter, so its [address] went to the clipboard.
final class MailMissing extends HelpNotice {
  /// Creates the notice.
  const MailMissing(this.address);

  /// Where the letter would have gone.
  final String address;
}

/// The browser did not open a page.
final class PageMissing extends HelpNotice {
  /// Creates the notice.
  const PageMissing();
}

/// What the help screen shows.
@immutable
final class HelpState {
  /// Creates the state.
  const HelpState({
    this.query = '',
    this.open,
    this.letter,
    this.about,
    this.notice,
  });

  /// What the search holds.
  final String query;

  /// Which of the common questions stands open, by its place among them all.
  final int? open;

  /// A letter that waits for the mail app.
  final HelpLetter? letter;

  /// What the app says about itself, or `null` until it is read.
  final AppAbout? about;

  /// What came of the last way out. A new one clears it first, so the same
  /// notice twice in a row still comes as news.
  final HelpNotice? notice;

  /// A copy with the given fields changed. [open], [letter] and [notice] are
  /// in records, because `null` is a value for them.
  HelpState copyWith({
    String? query,
    (int?,)? open,
    (HelpLetter?,)? letter,
    AppAbout? about,
    (HelpNotice?,)? notice,
  }) {
    return HelpState(
      query: query ?? this.query,
      open: open == null ? this.open : open.$1,
      letter: letter == null ? this.letter : letter.$1,
      about: about ?? this.about,
      notice: notice == null ? this.notice : notice.$1,
    );
  }
}

/// Searches the common questions, opens one at a time, and writes to the
/// developer through the mail app of the person (ADR 0018).
class HelpCubit extends Cubit<HelpState> {
  /// Creates the cubit on the [_links] of the host. [about] tells what the
  /// letters say about the app, as soon as it is read.
  HelpCubit(this._links, Future<AppAbout> about)
    : _about = about,
      super(const HelpState()) {
    unawaited(
      about.then((about) {
        if (!isClosed) emit(state.copyWith(about: about));
      }),
    );
  }

  final HelpLinks _links;
  final Future<AppAbout> _about;

  /// Searches the questions for [query].
  void search(String query) => emit(state.copyWith(query: query));

  /// Opens the question at [index], or closes it when it stands open, and
  /// closes any other.
  void toggle(int index) =>
      emit(state.copyWith(open: (state.open == index ? null : index,)));

  /// Writes a letter of [kind], which waits in [HelpState.letter] for
  /// [send] or [dismiss].
  Future<void> compose(LetterKind kind) async {
    final letter = HelpLetter.of(kind, await _about);
    if (!isClosed) emit(state.copyWith(letter: (letter,), notice: (null,)));
  }

  /// Lets the letter go.
  void dismiss() => emit(state.copyWith(letter: (null,)));

  /// Hands the letter to the mail app. Without one, the address goes to the
  /// clipboard and the screen says so.
  Future<void> send() async {
    final letter = state.letter;
    if (letter == null) return;
    emit(state.copyWith(letter: (null,), notice: (null,)));
    if (await _links.mail(letter.uri)) return;
    await _links.copy(letter.address);
    if (!isClosed) {
      emit(state.copyWith(notice: (MailMissing(letter.address),)));
    }
  }

  /// Opens the public page of bugs and ideas.
  Future<void> openIssues() async {
    emit(state.copyWith(notice: (null,)));
    if (await _links.open(issuesPage)) return;
    if (!isClosed) emit(state.copyWith(notice: (const PageMissing(),)));
  }
}
