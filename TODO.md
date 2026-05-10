aaaaaaaaaaaaaaaaaaaaaaaaasssssssssssssssssssssssssssssssssssssssssssssssssssssssssssssss  # API 403 Token Fix + Popup Menu Fix — COMPLETE

## Token Fix (Done)
- [x] `articles_services.dart` — Fixed error swallowing bug + 403 auto-logout
- [x] `main.dart` — Global navigator key
- [x] `auth_provider.dart` — `handleTokenInvalid()` method
- [x] `bottom_navbar.dart` — Wire up `onTokenInvalid` callback

## Popup Menu Fix (Done)
- [x] `popup_menu.dart` — Changed `Navigator.pop(context)` to `onDismiss` callback
- [x] `detail_screen.dart` — Passed `onDismiss: () => setState(() => isMenuOpen = false)`

## Status: ✅ COMPLETE
