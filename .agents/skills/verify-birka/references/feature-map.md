# Birka feature map

| Journey | Start in the app | Command from the repository root | Evidence |
| --- | --- | --- | --- |
| [Category limits on the web](category-limit.md) | Overview → All limits, then Operations → New operation | `make verify-web FLOW=category-limit BASE=/Birka/` | The quick-add previews agree with the saved limit, including after reload. |
| [Category limits in Flutter](category-limit.md) | Overview → All limits, then the navigation bar's New operation button | `make verify-flutter FLOW=category-limit` | The same amounts survive closing the app widget and reopening its SQLite ledger. |
| [Backup and restore](backup-roundtrip.md) | Data → Save a copy, then Data → Restore from a copy in another browser profile | `make verify-web FLOW=backup-roundtrip BASE=/Birka/` | Both expenses, the account balance and the limit survive the move. |
| [Repeated CSV import](statement-reimport.md) | Import → Choose a file → select Test card → Duplicates | `make verify-web FLOW=statement-reimport BASE=/Birka/` | The second import detects both rows and the saved balance stays the same. |
| [Cross-currency transfer](currency-transfer.md) | Operations → New operation → Transfer | `make verify-web FLOW=currency-transfer BASE=/Birka/` | After reload each account shows its own balance and signed entry. The transfer detail shows both currencies. |
