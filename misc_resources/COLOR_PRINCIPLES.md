# General Principles for Colors

## Hue strategy (two hue groups)

Each palette is built around two hue groups that are somewhat complementary:

- **Backgrounds** use one hue family (e.g. blue-green, deep red, muted gray-green)
- **Text** uses a different, somewhat complementary hue family (e.g. warm amber/cream, mauve, warm cream)

The two hue groups don't need to be exact opposites on the color wheel — "somewhat complementary" is enough. The key is that they don't fight each other.

Current palette hue pairings:

- **Coast**: blue-green backgrounds + warm amber/cream text
- **Cherry**: deep red backgrounds + mauve/violet text
- **Flora**: muted gray-green backgrounds + warm cream/burnt orange text

## Font colors

### Primary text

- Luminance contrast ~5.5–6.0x against primary background
- Hue from the text hue group, but relatively muted/desaturated — readable without drawing attention
- Should not feel like a color cast or filter against the background

### Secondary text

- Sits between the background hue and the primary text hue — more character than primary, more accent-like, but not so vivid it competes with the actual accent color
- Slightly lower luminance than primary is acceptable
- Saturation is the main dial to adjust character: spread channels further apart while keeping average luminance constant (push dominant channel up, pull minor channels down by equal amounts)

### Tertiary text

- Echoes the background hue closely — looks like a lighter version of the background
- Must be legible against both `background_primary` and `sidebar_background` (~3x minimum contrast)
- Lower luminance and lower saturation than primary and secondary

## Accent color

- A hyper-saturated, neon version of the background hue — same hue family as the background, dialed up dramatically in saturation and luminance
- Should feel "at home" in the palette while clearly standing out
- Target ~3.7x luminance contrast against `sidebar_background`
- Should not be too similar in hue to the text colors

## Background luminosity

From darkest to lightest:
`primary` → `sidebar` → `secondary` → `toolbar`

Differences should be incremental; no big jumps. Scale background tiers proportionally from the primary background's channel ratios to preserve hue identity across all luminance levels.

`background_highlight` is independent — used for selections/hover states, just needs to be visually distinct from whatever it sits on.

The `card_border` sits between `primary` and `secondary` background luminance.

## Saturation mechanics

To increase saturation without changing luminance (average):

- Push the dominant channel up by N
- Pull the minor channel(s) down by N (distributed evenly)
- The average stays the same; the channel spread increases

To decrease saturation: reverse the above.
