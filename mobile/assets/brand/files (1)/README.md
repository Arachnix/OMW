# Mascot self-draw animation — portable files

Two versions of the same animation, traced directly from your source artwork
(the circle, hat, body, arm and pouch are one continuous traced line; the eyes
fill in solid once their outline finishes).

## Files

- **`mascot.svg`** — a single, self-contained SVG with its own embedded
  `<script>`. Plays itself on load. Use this for plain HTML/web.
- **`MascotAnimation.jsx`** — a React component version (refs instead of
  `getElementById`, styled via a `<style>` tag scoped to the component,
  props for `size`, `ink`, and `bg` colors).

## Plain HTML / web

Just drop `mascot.svg` in wherever you want it:

```html
<img src="mascot.svg" width="240" alt="logo" />
```

The file's intrinsic size is 1254×1254 — set `width`/`height` (as attributes
or CSS) on whatever element displays it to size it down. `height:auto` on
the SVG itself will keep it square when you constrain width via CSS.

⚠️ **`<img>` tags do not run the embedded script** (browsers block scripts
inside images loaded this way for security). To get the animation, either:

- Inline the SVG's contents directly into your HTML (copy everything from
  `<svg ...>` to `</svg>` straight into the page), or
- Load it via `<object data="mascot.svg" type="image/svg+xml"></object>`,
  which does allow the internal script to run.

The SVG exposes `window.playMascotAnimation()` (or the equivalent inside the
`<object>`'s content document) if you want to trigger a replay from a button
elsewhere on the page.

## React (web)

```jsx
import MascotAnimation from "./MascotAnimation";

<MascotAnimation size={280} ink="#16302e" bg="#dfe9e8" />
```

Plays once on mount; clicking the logo replays it (remove the `onClick` in
the file if you don't want that). Swap `ink`/`bg` to match your theme.

## React Native

Neither file works as-is — RN doesn't have a DOM, so `getTotalLength()` and
CSS transitions aren't available. Your best path:

1. Convert the path data into an [`react-native-svg`](https://github.com/software-mansion/react-native-svg)
   `<Path>`.
2. Use [`react-native-reanimated`](https://docs.swmansion.com/react-native-reanimated/)
   to animate `strokeDashoffset` on a shared value, driven by `withTiming`.
3. The exact timing numbers in `MascotAnimation.jsx` (durations, stagger,
   easing curve `cubic-bezier(.65,.05,.36,1)`) carry over directly — you're
   just re-expressing the same animation in Reanimated's API instead of CSS
   transitions.

Happy to build this version directly if you want — just say the word and
confirm you're using `react-native-svg` + `reanimated` (or name a different
stack if you're using something else, e.g. Lottie).

## Flutter

Similar story — use [`flutter_svg`](https://pub.dev/packages/flutter_svg) to
render the path, and drive the "drawing" effect with a custom `Path` +
`AnimationController` using a `PathMetric`/`extractPath` approach (Flutter's
equivalent of `stroke-dasharray`/`dashoffset`). Let me know if you want a
concrete implementation.

## The path data itself

The traced path in both files is the same vector data — if you just want the
raw `d` attribute to bring into Figma, Illustrator, or your own custom
animation code, it's easiest to grab it straight out of `mascot.svg` (look
for `id="p-lines"`).
