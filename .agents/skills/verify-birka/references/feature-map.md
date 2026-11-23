# Birka feature map

| Journey | Start in the app | Command from the repository root | Evidence |
| --- | --- | --- | --- |
| [Category limits on the web](category-limit.md) | Overview → All limits, then Operations → New operation | `make verify-web FLOW=category-limit BASE=/Birka/` | The quick-add previews agree with the saved limit, including after reload. |
| [Category limits in Flutter](category-limit.md) | Overview → All limits, then the navigation bar's New operation button | `make verify-flutter FLOW=category-limit` | The same amounts survive closing the app widget and reopening its SQLite ledger. |
| [Backup and restore](backup-roundtrip.md) | Data → Save a copy, then Data → Restore from a copy in another browser profile | `make verify-web FLOW=backup-roundtrip BASE=/Birka/` | Both expenses, the account balance and the limit survive the move. |
| [Backup and restore in Flutter](backup-roundtrip.md) | More → Data → Save a copy, then Restore from a copy in another ledger | `make verify-flutter FLOW=backup-roundtrip` | On macOS the saved file replaces the destination account. After reopening SQLite, the source balance, both expenses and the limit are visible. |
| [Repeated CSV import](statement-reimport.md) | Import → Choose a file → select Test card → Duplicates | `make verify-web FLOW=statement-reimport BASE=/Birka/` | The second import detects both rows and the saved balance stays the same. |
| [Repeated CSV import in Flutter](statement-reimport.md) | More → Import → Test card | `make verify-flutter FLOW=statement-reimport` | On macOS the first import adds two operations. After reopening SQLite the same file shows two skipped rows. The balance and all three entries survive another reopen. |
| [Cross-currency transfer](currency-transfer.md) | Operations → New operation → Transfer | `make verify-web FLOW=currency-transfer BASE=/Birka/` | At 390 and 1440 px the form opens in its expected place. After reload both balances, signed entries and currencies agree. |
| [Cross-currency transfer in Flutter](currency-transfer.md) | Overview → New operation → Transfer | `make verify-flutter FLOW=currency-transfer` | After reopening SQLite, each account shows its balance and signed entry. The credit opens the two-currency transfer. |
