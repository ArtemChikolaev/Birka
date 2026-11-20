# Birka feature map

| Journey | Start in the app | Command from the repository root | Evidence |
| --- | --- | --- | --- |
| [Category limits](category-limit.md) | Overview → All limits, then Operations → New operation | `make verify-web FLOW=category-limit BASE=/Birka/` | The quick-add previews agree with the saved limit, including after reload. |
| [Backup and restore](backup-roundtrip.md) | Data → Save a copy, then Data → Restore from a copy in another browser profile | `make verify-web FLOW=backup-roundtrip BASE=/Birka/` | Both expenses, the account balance and the limit survive the move. |
