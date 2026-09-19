# OnMyWay UI contract

The rules every OnMyWay mobile screen follows. They come from the Figma file
(`OMW`, node 72:282) and the screens already built from it: sign-in, sender
Home, courier Feed, Activity and Account.

Every new screen must follow this contract. When Figma and this file disagree,
Figma wins: update the tokens first, then this file.

```dart
import 'package:omw_delivery/design_system.dart';
```

That one import brings in every token, the theme and all shared components.

---

## 1. Ground rules

1. **Monochrome.** Black ink on white. Grey is used only for fills and
   hairlines. The mascot's dark green comes from its artwork and is never
   used as a UI colour.
2. **Tokens only.** Never write raw `Color(0x…)`, font sizes, radii or
   durations in screen code. Use `AppColors`, `AppText`, `AppSpacing`,
   `AppRadii` and `AppMotion`. If a value is missing, add a token.
3. **Reuse before building.** Check §8 for an existing component before
   writing a new one. Promote anything used twice into `lib/widgets/` and
   export it from `lib/design_system.dart`.
4. **Native widgets.** Build with responsive Flutter widgets. Never use a
   screenshot as a background. No web views and no HTML/CSS.
5. **Local only.** No runtime network calls for fonts, images or data. Every
   asset is bundled (§10).

---

## 2. Colours — `AppColors` (`lib/theme/app_colors.dart`)

| Token | Value | Use |
|---|---|---|
| `ink` | `#000000` | Text, outlines, icons, primary buttons, active states |
| `surface` | `#FFFFFF` | Page background, cards, text on ink |
| `fillMuted` | `#F5F5F5` | Selected cargo tile, custom-amount pill, route icon discs |
| `fillButton` | `#EEEEEE` | Secondary sign-in buttons (`SoftButton`) |
| `divider` | `#E6E6E6` | Rules, unselected filter-pill outline, sheet drag handle |
| `fieldBorder` | `#E0E0E0` | Resting text-field outline |
| `textMuted` | `#828282` | Placeholders, "or", legal copy **only** |
| `inkSoft` | `rgba(0,0,0,.9)` | Selected filter pill |
| `error` | `#B3261E` | Validation errors only |
| `scrim` | `rgba(15,23,42,.6)` | Overlay behind notification sheets only |
| `inkAt(o)` | ink at opacity `o` | Secondary copy: **0.6** captions, **0.7** footnotes, **0.5** inactive nav |

Rules:
- Secondary text is `ink` at reduced opacity (`inkAt`), not a separate grey.
  This matches Figma.
- `textMuted` on white is about 3.9:1 contrast. Keep it to placeholder and
  legal copy, as in Figma, and never use it for content people need to read.
- There is no dark theme yet. Do not add colours for one screen only.

---

## 3. Typography — `AppText` (`lib/theme/app_text.dart`)

The only typeface is **Inter**, bundled in `assets/fonts/inter/` at weights
400–900 (OFL licence alongside). Base line height is 1.2 unless listed.

| Style | Size / weight | Where |
|---|---|---|
| `authTitle` | 16 / 600, lh 1.5 | "Create an account" |
| `authBody` | 14 / 400, lh 1.5 | Sign-in subtitle |
| `fieldText` | 14 / 400, lh 1.4 | Text-field input and hint |
| `button` | 14 / 500, lh 1.4 | Sign-in buttons, text buttons |
| `legal` | 12 / 400, lh 1.5, `textMuted` | Terms and fine print |
| `cardEyebrow` | 12 / 800, UPPERCASE | "FAST COURIER MATCH", "DELIVERY OFFER" |
| `badge` | 11 / 700, white | ETA and fare chips |
| `routeLabel` | 11 / 800 | "Pickup Spot", small labels |
| `routeValue` | 13 / 500 | Addresses, list titles |
| `sectionTitle` | 18 / 800 | "Parcel Cargo", screen and sheet titles |
| `tileTitle` / `tileTitleSelected` | 12 / 700 → 800 | Cargo tile name |
| `tileCaption` / `tileCaptionSelected` | 10 / 500 → 700 | Cargo tile weight |
| `caption` | 11 / 500 | Helper and footnote copy |
| `price` | 32 / 900, lh 1.1 | "₹120" |
| `inputLabel` | 13 / 600 | "Custom amount:" |
| `inputValue` | 14 / 800 | Inline numeric input, trailing fare |
| `cta` | 15 / 800, white | Full-width pill CTA |
| `navActive` / `navInactive` | 11 / 800 → 600 | Bottom nav labels |
| `pill` | 14 / 500, lh 1.4 | Filter pills |
| `brandTitle` | 24 / 900 | Landing "OnMyWay" wordmark (text) |
| `tagline` | 10 / 800, ink 61% | "GOOD FOOD. LESS WAIT.", choice-card subtitles |
| `headline` | 30 / 900, lh 1.15 | Landing "On the route? Grab the loot." |
| `choiceTitle` | 16 / 800 | Landing ORDER / DELIVER |
| `stopTitle` / `stopDetail` | 16 / 800 · 12 / 500 ink 60% | Compact detour card stops |
| `statValue` / `statCaption` | 12 / 800 · 9 / 500 ink 60% | Compact detour card stats |
| `priceCompact` | 24 / 900 | Compact card fare |
| `ctaCompact` | 12 / 800, white | Compact "ACCEPT" button |
| `sheetTitle` / `sheetBody` | 20 / 800 · 14 / 400 ink 60% | Notification header title and subtitle |
| `trackingTitle` | 24 / 800 | "On the way to Pickup" |
| `orderMeta` / `orderCaption` | 12 / 600 · 11 / 500, ink 60% | "ORDER #…", "PICKUP" captions |
| `orderValue` / `orderValueStrong` | 14 / 500 · 15 / 700 | Order card values; names and stop titles |
| `chip` | 13 / 700 | "Order ID: #…" chip |
| `buttonLarge` | 16 / 600 | Notification sheet buttons |

Rules:
- Eyebrows are written in UPPERCASE in the source string, not transformed.
- Prices are always `₹` plus a whole number with no space: `₹120`.
- Wrap screen and section titles in `Semantics(header: true)`.
- Inter has no geometric-shape glyphs (e.g. "▾", "▷"). Use a Material
  icon instead of typing the character.
- Single-line labels in constrained rows use `maxLines: 1` with an ellipsis
  so they survive large text sizes.

---

## 4. Spacing — `AppSpacing`

A 4-point scale: `xxs 2 · xs 4 · sm 8 · md 12 · lg 16 · xl 20 · xxl 24`.

| Context | Value |
|---|---|
| App page gutter (`gutter`) | 16 horizontal |
| Sign-in page gutter (`authGutter`) | 24 horizontal; content max width **327** |
| Gap between stacked cards and sections | `lg` 16 |
| Card inner padding | `lg` 16 |
| Eyebrow → content inside a card | `md` 12 |
| Gap between cargo tiles, filter pills | `sm` 8 |
| Section title → its content | `sm` 8 |
| Sign-in blocks (copy, form, divider, buttons, legal) | `xxl` 24 |
| Field → primary button | `lg` 16 |
| Scroll view bottom padding | `xl` 20 |

---

## 5. Radii and outlines — `AppRadii`

| Token | Value | Applies to |
|---|---|---|
| `field` | 8 | Text fields, sign-in buttons |
| `tile` | 12 | Route sub-cards, cargo tiles |
| `card` | 16 | `OmwCard` |
| `pill` | 100 | CTAs, badges, custom-amount input |
| (literal) 20 | — | Filter pills, bottom-sheet top corners |

| Stroke token | Width | Applies to |
|---|---|---|
| `hairline` | 1 | Route sub-cards, unselected tiles, input pills, text fields |
| `stroke` | 1.5 | Cards, avatar ring, selected tile icon ring, outlined buttons |
| `strokeBold` | 2 | Selected cargo tile, dashed route connector |

Rules:
- Outlines are `ink`, apart from text fields (`fieldBorder`, `ink` when
  focused, `error` on error) and unselected filter pills (`divider`).
- **No shadows or elevation.** Depth comes from outlines and grey fills.
- Selection is shown by a **thicker outline plus the `fillMuted` fill plus a
  heavier label weight**, never by colour alone.

---

## 6. Buttons

| Component | Look | When |
|---|---|---|
| `PillButton` (default) | Black pill, height 48, `cta` text, optional leading icon | The one primary action on a screen ("Broadcast…", "Accept…") |
| `PillButton(radius: AppRadii.field, height: 40, textStyle: AppText.button…)` | Black rectangle, radius 8 | Primary action on the sign-in frames |
| `SoftButton` | `fillButton`, radius 8, height 40, optional leading logo | Secondary sign-in options |
| `OutlinedButton` + `StadiumBorder` | 1.5 ink outline, height 48 | Low-emphasis actions (e.g. "Sign out") |
| `TextButton` | Ink text, min height 44 | Dismiss or tertiary ("Done") |
| `IconButton` + `SvgIcon` | Figma icon, with a tooltip | Icon-only actions (e.g. clear with ✕) |

Rules:
- At most **one** black `PillButton` per view.
- Figma's "▷" play glyph is `Icons.play_arrow_outlined`, 20px, white, passed
  as `leading`.
- Disabled buttons use `onPressed: null`; `PillButton` fades itself to 35%.
- Async actions use `busy: true`, which swaps the label for a spinner. Never
  add a second loading indicator.
- The label **is** the semantic label. Put amounts in the string
  ("…for ₹120").
- Touch targets are at least 48×48 (40 for pills and sign-in buttons, as in
  Figma).

---

## 7. Cards and content blocks

- **`OmwCard`**: white, 1.5 ink outline, radius 16, padding 16. The container
  for every grouped block. `strokeWidth: AppRadii.strokeBold` gives the 2px
  outline of compact feed cards.
- **`CardEyebrow`**: 8px ink dot + 6 gap + UPPERCASE `cardEyebrow` label,
  with an optional trailing widget pinned right. `hollowDot: true` draws an
  outlined dot ("SLIGHT DETOUR"). Every `OmwCard` starts with
  one, unless it is an identity or summary card.
- **`EtaBadge`**: black pill, padding 10×4, `send` icon 12 + "~N mins".
- **`RouteStops`**: pickup sub-card, a dashed connector (2px ink, 3 on / 3
  off, 16 tall, 26 from the left), then the destination sub-card.
  - Sub-cards have a 1 ink outline, radius 12 and padding 12.
  - Each has a 28px `fillMuted` icon disc and a trailing Figma icon:
    `circleArrowLeft` on pickup, `arrowUpRight` on destination.
  - Pass the `onEdit…` callbacks to make the stops tappable; leave them null
    for read-only.
- **`ParcelOptionCard`**: cargo tile. With `onTap` it is selectable; with
  `onTap: null` it is a static summary (see the courier feed).
- **Compact request card** ("request-card-3", courier feed): 2px `OmwCard`,
  hollow-dot eyebrow, and an outlined distance pill. Below that, three
  columns: 28px outlined stop discs with `stopTitle`/`stopDetail`,
  icon + `statValue`/`statCaption` stats, and `priceCompact` above a black
  radius-8 "ACCEPT" `FilledButton` (min 72×40). Used when
  `DeliveryRequest.isDetour`.
- **Editable price** (sender offer card): the `price` text is the input,
  with a 2px cursor at ink 60% and a 1.5px underline at ink 20% (60% when
  focused, `error` when invalid). It commits on blur or Done.
- **Collapsible multi-select** ("Delivery source"): `fillMuted` box with a
  1 ink outline and radius 16. The header row is `inputLabel` plus a caret
  that rotates. Below the ink-10% divider are 18px checkboxes (1.5 ink,
  radius 4, filled ink with a white check when on) and `routeValue` labels.
  Rows are at least 40 tall.
- **Notification sheets** (`lib/widgets/notice_sheet.dart`; Figma
  "notification-order-accepted" 164:116, 163:76, 163:315):
  - Open them only with `showNoticeSheet`: white, 2px ink top edge, 32 top
    radius, over `AppColors.scrim`. Swipe down, tapping the overlay, or
    tapping the handle all dismiss.
  - `NoticeSheet`: 24 gutter with a 40×4 ink handle (a 48×24 target
    labelled "Dismiss").
  - `NoticeHeader`: 48 disc, filled ink (success) or 2px ring (cancelled),
    plus `sheetTitle` and `sheetBody`.
  - `NoticeRule`: 2px ink rule with 20 above and below.
  - `NoticeCard`: `fillMuted`, 2px ink outline, radius 16.
  - `NoticeStop`: ink disc with a white dot (pickup) or square (delivery).
  - `OutlinePillButton`: 48 tall with a 2px ink outline.
  - Figma draws these over a live map. The app has no maps, so they open
    over the current screen.
- **Price block**: centred `cardEyebrow` label → `price` → optional `caption`
  at `inkAt(0.6)`.
- **Inline input pill** (custom amount): `fillMuted` pill with a 1 ink
  outline, containing a white pill with a 1 ink outline. It turns `error` on
  invalid input, and the message appears below in `caption`/`error` inside
  `Semantics(liveRegion: true)`.
- **Bottom sheets**: `showModalBottomSheet(isScrollControlled: true,
  useSafeArea: true)`. The theme supplies the white surface, 20 top radius
  and drag handle. Pad the content 16–24 horizontally and 24 at the bottom,
  plus `MediaQuery.viewInsetsOf(context).bottom` when the sheet has a field.
- **Empty states**: mascot badge at 72 → `sectionTitle` → `caption` at
  `inkAt(0.6)`, centred.

---

## 8. Navigation

- **Shell** (`MainShell` in `lib/main.dart`): `SafeArea(bottom: false)` →
  `AppHeader` → `Expanded` body in an `AnimatedSwitcher` → `AppBottomNav` in
  `Scaffold.bottomNavigationBar`.
- **`AppHeader`**: mascot badge 46 on the left (goes to the role's home tab),
  avatar 40 in a 1.5 ink ring with `userRound` 24 on the right (opens
  Account). Padding 12×16. Both are 48×48 targets with tooltips.
- **`AppBottomNav`**: `NavDestination(icon | glyph, label, badge)` list.
  `indicator: NavIndicator.underline` (shells) or `NavIndicator.disc`
  (landing: a 32px ink disc behind a white icon, inactive tabs at full ink).
  - Each item is 64 wide: 20px Figma icon, `navActive` or `navInactive`
    label, then a 24×2 ink indicator that grows in when active.
  - Inactive items are at 50% opacity.
  - Row padding is 10×24, spaced apart, with the bottom safe area applied.
  - Hide the nav while the keyboard is open.
- **Stages** (`AppState.stage`): splash → sign-in → **landing** → shell.
  Landing ORDER goes to `enterAs(AppRole.sender)` and DELIVER to
  `enterAs(AppRole.courier)`. The header mascot returns to the landing
  (`goToLanding`).
- **Notices**: `AppState` queues `SenderNotice`s (accepted or cancelled)
  for the sender's own requests. `SenderNoticeHost` (sender shell only)
  shows the oldest one. Closing the sheet in any way dismisses it. The
  courier gets its confirmation straight from the feed
  (`presentCourierAccepted`).
- **Tab sets** come from Figma. Do not add tabs without a design:
  - Landing: **Home** · **Orders** (opens sender Activity) · **Favorites**
    (no design yet, shows a snackbar) · **Account**
  - Sender: **Home** (`truck`) · **Activity** (`clipboardCheck`) · **Account** (`idCard`)
  - Courier: **Feed** (`truck`) · **Account** (`idCard`)
- **Filter row**: horizontal `ListView` of `FilterPill`s, height 40, gutter
  16, gap 8, placed directly under the header.
- **Flow state** (stage, role, tab) lives in `AppState`. Screens switch tabs
  through `AppState`, not `Navigator.push`. Use modal sheets for sub-tasks.
- The system status bar and home indicator are drawn by the OS. Never draw
  the Figma "Status Bar" or "Home Indicator" layers.

---

## 9. Mascot and brand usage

| Asset | Size | Where | Rules |
|---|---|---|---|
| `AppImages.mascotBadge` (`assets/figma/mascot_badge.png`) | 46 (header), 72 (sheets, empty states) | App header, confirmations, empty states | Always inside `ClipOval`, never recoloured |
| `AppImages.mascotTraveler` (`assets/brand/mascot_traveler.png`) | ~26% of screen height, 140–240 | Landing hero | Static PNG; keep the aspect ratio |
| `AppImages.mascotLogo` (`assets/brand/logo.jpeg`) | 206×209, scaled down to 120 min on short screens | Sign-in hero | Only on auth screens; keep the aspect ratio |
| `AppImages.wordmarkVideo` / `wordmarkStill` | ~72% of width, 200–360 | Splash | Through `BrandVideoWordmark` only |

Rules:
- **Never replace, redraw, recolour, crop or generate the mascot, logo or
  animation files.** Use the supplied files as they are.
- One mascot per view. It is a brand accent, not decoration to scatter
  around.
- Decorative mascot images use `excludeFromSemantics: true`. A mascot that
  carries meaning gets a label ("OnMyWay mascot").
- `assets/brand/badge_mascot.png` (60×56) is too low-resolution. Use
  `AppImages.mascotBadge` instead.
- Available but **not yet used**, pending design: `mascot_offer.png`,
  `mascot_peeking.png`, `route_signpost.png`,
  `avatar_user.png`, and the mascot MP4s `namaste`, `celebration`,
  `running`, `dancing`, `back_flip` and `onmyway`. Before using one, add it
  to `AppImages` and follow §11.
- `Landing_page.png`, `a636c0a2-….jpg`, `WhatsApp Video ….mp4`,
  `Final OMW handwritten.mp4` and `files (1)/` are reference or duplicate
  material. Do not reference them from code.

---

## 10. Asset paths

| Folder | Contents | Referenced through |
|---|---|---|
| `assets/figma/` | Figma exports: `ic_*.svg` (Lucide icons: send, map_pin, circle_arrow_left, globe, arrow_up_right, file, box, package, sliders_horizontal, circle_x, truck, clipboard_check, id_card, user_round), `logo_google.svg`, `logo_apple.png`, `mascot_badge.png` | `AppIcons.*`, `AppImages.*` |
| `assets/brand/` | Brand stills and MP4s supplied by the team | `AppImages.*` |
| `assets/fonts/inter/` | Inter 400–900 + `OFL.txt` | `pubspec.yaml` `fonts:` → `AppText.family` |
| `assets/` (root, hash-named files) | Legacy exports, unused | Do not reference |

Rules:
- Paths live **only** in `lib/theme/app_icons.dart`. Screens use constants,
  never string literals.
- Icons render through `SvgIcon(path, size:, color:)`, which recolours to
  `ink` by default and is decorative unless given a `semanticLabel`.
  Multicolour logos (Google) use `SvgPicture.asset` without a colour filter.
- **`AppGlyphs`** (in `app_icons.dart`) holds temporary Material stand-ins
  for Figma icons not exported yet: bag, arrow-right, store, user, alarm,
  navigation, check, phone, and the landing nav icons. Use them only through `AppGlyphs`.
  When the SVG is exported, add it to `AppIcons` and swap the call site.
- Icon sizes: 12 (badges), 16 (cards, tiles, inputs), 20 (nav, CTA play
  glyph), 24 (avatar), 32 (clear ✕).
- New Figma exports go into `assets/figma/` with snake_case names:
  `ic_<lucide_name>.svg`, or `.png` at 2–3× the rendered size. Drop
  duplicates of files already in `assets/brand/`.
- Never depend on Figma asset URLs at runtime.

---

## 11. Motion — `AppMotion`

| Token | Value | Use |
|---|---|---|
| `fast` | 150 ms | Opacity, text swaps, disabled fade |
| `medium` | 220 ms | Selection (tile, pill, nav indicator), tab body switch |
| `slow` | 400 ms | Stage cross-fade (splash → sign-in → app) |
| `curve` | `Curves.easeOutCubic` | All of the above |

Rules:
- **Implicit animations only**: `AnimatedContainer`, `AnimatedOpacity`,
  `AnimatedSwitcher`, `AnimatedSize` and `AnimatedDefaultTextStyle`. Reach
  for an explicit controller only for video.
- Keep motion restrained. Nothing loops, bounces or exceeds 400 ms, apart
  from the one-shot brand video. The largest scale change is 0.96 → 1.0
  (price change).
- Animate state changes, not decoration: selection, value changes, content
  swaps, and screens appearing.
- **Reduce motion.** Check `MediaQuery.disableAnimationsOf(context)`. Brand
  videos must show their static fallback when it is true.
- **Brand videos** (`BrandVideoWordmark` pattern):
  - Muted, played once, with `mixWithOthers`.
  - Fall back to a still on any error, and never show a broken player.
  - Hold a blank box of the same size while loading.
  - Give the viewer a way to skip, and a safety timeout
    (`SplashScreen.maxDuration`).
- Every `AnimatedSwitcher` child needs a `ValueKey` of the value that changed.

---

## 12. Accessibility and layout checklist (every screen)

- [ ] `SafeArea` on the page; bottom inset handled by the nav or the sheet.
- [ ] Scrollable body (`ListView` / `SingleChildScrollView`) with
      `keyboardDismissBehavior: onDrag` when it has inputs.
- [ ] Fields stay visible above the keyboard (`resizeToAvoidBottomInset`
      default, `viewInsets` padding in sheets).
- [ ] Layout works from 320 to 430 wide; sign-in content is capped at 327.
- [ ] Every tappable element has a semantic label and `button: true`;
      selectable ones set `selected`.
- [ ] Headers are marked with `Semantics(header: true)`; dynamic results use
      `liveRegion`.
- [ ] Touch targets are at least 48 (40 for pills and sign-in buttons).
- [ ] Only tokens used; no raw colours, sizes or durations.
- [ ] Anything simulated (sign-in, payments, matching) is labelled as a demo.
      No real payments, maps, Firebase or external APIs.
- [ ] `flutter analyze` is clean and a widget test covers the main path.
