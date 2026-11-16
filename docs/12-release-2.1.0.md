# Billing Guru 2.1.0 — Release Notes

Release date: 2026-11-16 · Package: `BillingGuru-2.1.0-windows-x64-2026-11-16.zip`

## Before you upgrade

- No database changes (schema stays v7). 2.0.0 backups restore in 2.1.0.
- Start 2.1.0 **once from the same folder you used to start 2.0.0** (for
  example the same shortcut). That lets it find your existing data and copy
  it to the new fixed location (see below). Then open **Settings → Data** and
  check that your products and sales are there.

## What's new

### Automatic backups

- A full backup (products, sales, expenses, customers, settings, product
  images, expense receipts, receipt logo) is made **every day when the app
  starts** and **again whenever the app is closed**. While closing, the screen
  shows "Saving backup before closing…" (never longer than 60 seconds).
- One file per day: `billing-guru-auto-YYYY-MM-DD.zip`. The latest backup of
  the day replaces that day's file. The **last 30 days** are kept.
- **Choose where backups go** (installer): **Settings → Data → Choose backup
  folder**. To survive a computer failure, pick a **OneDrive / Google Drive
  folder, a USB drive or a network drive**. Until a folder is chosen, backups
  go to `%APPDATA%\Vasista Technologies\BillingApp\backups` and the Data tab
  warns that they are only on this computer.
- If the chosen folder is not available (USB unplugged, network down), the
  backup is saved on this computer instead and the Data tab shows a warning.
  The next backup goes back to the chosen folder once it is available again.
- The Data tab shows the last backup time and file, and has **Back up now**.
- To recover: **Settings → Data → Restore from backup** and pick any of the
  daily `.zip` files. This works on a new computer too.

### Data tab for admins

| | Installer | Admin |
|---|:-:|:-:|
| See last backup, **Back up now**, **Save backup as…** | ✓ | ✓ |
| Choose backup folder | ✓ | |
| Restore from backup | ✓ | |

### Database always in the same place

- Before 2.1.0 the database was stored in a `.dart_tool` folder inside
  whatever folder the app was started from, so starting the app a different
  way (new shortcut, re-extracted zip) could show an empty shop.
- The database now always lives in
  `%APPDATA%\Vasista Technologies\BillingApp\database\pos_billing.db`
  (shown under **Settings → Data → About**).
- On first start, 2.1.0 copies the existing database there automatically. The
  old file is left where it was as an extra safety copy; it can be deleted
  once everything checks out.
