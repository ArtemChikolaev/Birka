import 'package:accounts_common/accounts_common.dart';
import 'package:design_flutter/design_flutter.dart';

/// The art of the design system for [art] of an account.
CardArt cardArtOf(AccountArt art) => CardArt.values.byName(art.name);
