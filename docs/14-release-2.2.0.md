# Billing Guru 2.2.0 — Release Notes

Release date: 2026-11-20 · Package: `BillingGuru-2.2.0-windows-x64-2026-11-20.zip`

## Before you upgrade

- No database changes (schema stays v7). 2.1.x data and backups work as-is.
- Install the same way as 2.1.1: unzip and replace the previous program folder.
- **Check Settings → Business once after upgrading.** The old free-text
  receipt header is copied into the new separate fields automatically, but
  city, state and postal code cannot be split out of free text. They end up
  in **Address line 2** and may need moving to their own fields.

## What's new

### Clearer payment buttons

- On the checkout screen, **Pay** is now **Pay without receipt** and
  **Print receipt** is now **Pay and print receipt**.
- **Pay and print receipt** records the sale once, opens the print dialog,
  then clears the cart and returns to the PoS, like a normal payment.

### Receipt settings for Sellers and Admins

- Sellers can now open **Settings**. They see only the **Printer** tab.
- Admins also get the **Printer** tab, next to their existing tabs.
- On that tab, Sellers and Admins can change the bill receipt template and
  printer size and preview a receipt. The receipt logo can still be
  changed only by the Installer.

### Separate business details fields

- **Settings → Business** now has separate fields for Business name,
  Address line 1, Address line 2, City, State, Postal code, Phone and
  Tax ID, instead of one receipt header text box.
- Printed receipts and the receipt preview are built from these fields.
  Empty fields are left off the receipt.

### Add product

- **Stock quantity** starts at **0**.
- The **Price** field shows the currency symbol chosen in
  **Settings → Business → Regional** (for example €, $, £ or ₹) instead of
  a fixed euro sign.
