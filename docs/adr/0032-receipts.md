# ADR 0032 — Receipts by their QR code

**Status:** accepted 2026-11-15.

## Context

- Typing in a purchase takes longer than paying for it, and a paper receipt
  already says the sum to the kopeck and the minute it was paid. In Russia
  every fiscal receipt carries a QR code: a query string such as
  `t=20261118T0912&s=620.00&fn=7380440700076541&i=24611&fp=2531297412&n=1`
  with the moment, the sum, the fiscal drive («ФН»), the number of the
  document («ФД»), its fiscal sign («ФП») and the kind of the receipt.
- The code holds no items and no shop. They come from the service of the tax
  office, which wants the person's own login and a server between, or from
  reading the printed text, which thermal paper and a camera make
  unreliable.
- Birka keeps the money of the person on the phone and sends it nowhere.
- The boards «Чек по QR» of the canvas draw:
  - the button «Чек» in the header of quick add;
  - the scanner: a frame that looks, snaps to a receipt and turns green,
    a code that is not a receipt, the torch and «Ввести вручную»;
  - quick add filled from a receipt, for a new till and for a known one;
  - the sheet «Этот чек уже в Birka»;
  - the question about the camera on iPhone and Android, and its refusal;
  - the operation with its receipt.

## Decision

1. Birka reads the QR code only, on the phone, and sends nothing about the
   receipt anywhere. The code gives the operation its sum, its day and its
   moment, and whether money left the person: «Приход» and «Возврат
   расхода» are expenses, «Возврат прихода» and «Расход» incomes. A code
   without the kind is a sale, as older receipts printed none.
2. The transaction keeps its receipt: the fiscal drive, the number of the
   document, the fiscal sign and the kind, in four columns of
   `transactions` (schema 15) and in the copy (format 11). Its source is
   `receipt`, «Из чека». A change of the operation keeps the receipt; a
   transfer is never one.
3. The drive, the document and the sign name one receipt. The scanner finds
   a receipt that the ledger already has and opens its operation instead of
   making a second one.
4. The drive names the till. A receipt of a till that a receipt came from
   before takes the category and the note of its latest operation, and the
   line over the sum says «знакомая касса». The memory is that operation, so
   it needs no table: changing its category changes what the till gives,
   and deleting it forgets the till. The first receipt of a till says as
   quick add closes that the next ones go to its category.
5. The sum comes in on the account of the sheet when it holds rubles, else on
   the first account in rubles.
6. The moment of the receipt stays while the day of the operation is the day
   of the receipt; another day drops it.
7. A statement of the bank does not record the purchase twice: the import
   already finds an operation of the same amount on the same day or a day
   apart ([ADR 0021](0021-statements.md)).
8. On the phone the chip «Чек» in the header of a new operation opens the
   scanner, which fades in over quick add. The scanner is a page of Birka
   drawn by the kit over the camera of `mobile_scanner`: AVFoundation and
   Apple Vision on iOS, CameraX with the bundled model of ML Kit on
   Android, so a code reads offline and without the services of Google. It
   reads QR codes only. A receipt snaps the frame to the code, and the
   scanner closes itself a moment later; the sum of the receipt rolls into
   quick add.
9. The question about the camera says why Birka asks and that no picture
   is kept («Камера нужна, чтобы прочитать QR-код чека…»). A refusal shows
   what to do instead: «Открыть настройки», through the channel
   `birka/settings` of the app, and quick add by hand. A camera that does
   not open, such as that of a simulator, offers quick add by hand.

## Consequences

- An operation from a receipt is as quick as the camera: the sum, the day
  and the time come from the till, and a known till picks the category too.
- Items and shop names are not there, and the operation page says so.
- Format 11 of the copy is new: an older Birka refuses a copy from this one,
  as with every format before.
- The model of ML Kit makes the APK 3–10 MB bigger. The model of Google
  Play services would cost 0.6 MB, but would not read a code on a phone
  without them.
- The site has no scanner: a computer seldom has the receipt and a camera
  together. It shows the source «Из чека» like the phone.

## Options considered

- **The service of the tax office:** gives the items and the shop, but
  needs the person's login and a server that sees their purchases.
- **Reading the printed text:** works without a QR code, but misreads
  thermal paper, and the model for Cyrillic is not on every phone.
- **A table of tills:** would keep a till after its operations are gone and
  need its own place in the copy; the latest operation already says the
  same.
