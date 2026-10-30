import 'package:accounts_common/accounts_common.dart';
import 'package:design_jaspr/design_jaspr.dart';

/// The art of the design system for [art] of an account.
CardArt cardArtOf(AccountArt art) => CardArt.values.byName(art.name);
