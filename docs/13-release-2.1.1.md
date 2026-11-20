# Billing Guru 2.1.1 — Release Notes

Release date: 2026-11-19 · Package: `BillingGuru-2.1.1-windows-x64-2026-11-19.zip`

## Before you upgrade

- No database changes (schema stays v7). 2.1.0 data and backups work as-is.
- Install the same way as 2.1.0: unzip and replace the previous program folder.

## What's new

### Dashboard can be switched off

- **Settings → Modules** now has a **Dashboard** switch, like Home and PoS.
  It is on by default.
- When it is off, Dashboard disappears from the navigation menu. The app
  opens on Home instead, or on the next module that is switched on.

## Fixes

- **Settings stays on the tab you are using.** Switching **Payment screen**
  (or **Expenses**) on or off in **Settings → Modules** used to jump back to
  the **Business** tab. It now stays on **Modules**.
- Saving a payment option no longer switches to another Settings tab.
