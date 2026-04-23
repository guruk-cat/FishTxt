# App Color Palette Guidelines

## Mapping colors to usage

The following are key values in `colors.json` and their corresponding usage in the FishTxt app.

**Background colors:**

| Key | Usage | Luminosity range |
| --- | ----- | ---------------- |
| `background_primary` | background for text editor, the buttons column section of the sidebar, and cards within the dashboard | 30–38 |
| `background_secondary` | background for the dashboard area | 47–63 |
| `background_highlight` | overlayed with an `opacity` argument when an element is selected | 70–89 |
| `sidebar_background` | background for the expandable section of the sidebar (e.g., file navigator) | 38–48 |
| `toolbar_background` | color of the unified window title bar + toolbar in macOS 13+ | 62–77 |

**Font and other UI elements:**

| Key | Usage | Luminosity range |
| --- | ----- | ---------------- |
| `content_primary` | main body text in the editor, body text in dashboard blob cards, and clickable elements in the sidebar when hovered by mouse | 191–199 |
| `content_secondary` | headings in the text editor; headings in sidebar panels and settings panel; and selected context (folder or blob) in the sidebar and its expandable panels | 168–178 |
| `content_tertiary` | inactive UI elements that can be clicked (usually turns into `content_primary` when hovered); used to make elements inconspicuous | 133–140 |
| `content_resting` | similar to `content_tertiary`, but used when legibility is still needed (e.g., list of blobs and folders in the file navigator) | 175–188 |
| `accent` | cursor color, formatting buttons when active, certain UI elements in the sidebar | varies by palette |
| `confirmation` | used to indicate that an action (e.g., saving) has been successful | varies by palette |
| `card_border` | a thin outline around folder and blob cards in the dashboard | 46–54 |
| `destructuve` | used for delete-related features; rarely in use | ~108 (fixed) |

## Luminosity and Contrast

### Design Philosophy

FishTxt's palettes are intentionally medium-contrast. Legibility is maintained through luminosity differences and slight hue differences between background and foreground roles, but the harshness of high-contrast pairings is avoided. This is a deliberate accommodation for astigmatism. New palettes should follow this same principle: avoid stark or near-pure-black/white pairings, and keep the overall feel soft and atmospheric.

### Overall Luminosity Target

Palette luminosity is measured as a weighted average (0.2126R + 0.7152G + 0.0722B) across a subset of roles called the **main tier**: `background_primary`, `sidebar_background`, `card_border`, `toolbar_background`, all `content_*` colors, and `confirmation`. The target for this average is approximately **115** (0–255 scale).

The following roles are excluded from the main tier and should be treated separately when making palette-wide luminosity adjustments:

- **`background_secondary` and `background_highlight`**: already elevated relative to other backgrounds; apply a smaller adjustment delta to avoid pushing them into mid-tone territory
- **`accent`**: the dominant channel is intentionally bright to make it pop; adjust conservatively to preserve that quality
- **`destructive`**: fixed at [204, 82, 82] across all palettes; not adjusted

### Key Contrast Pairs

The ratios below describe the most legibility-critical pairings in the UI, expressed as foreground luminosity / background luminosity. These serve as a reference when evaluating new palettes or auditing drift.

| Pair | Coast | Cherry | Flora |
| ---- | ----- | ------ | ----- |
| `content_primary` over `background_primary` (e.g., body text in editor) | 5.1× | 6.4× | 5.5× |
| `content_resting` over `sidebar_background` (e.g., file navigator list) | 4.3× | 4.6× | 3.7× |
| `accent` over `background_primary` (e.g., cursor, active UI elements) | 4.3× | 4.1× | 5.4× |

As mentioned above, both luminosity differences and hue differences are utilized to maintain legibility without relying on sharp contrat. When making new palettes or adjusting existing ones, it is important to consider how the *perceived* luminosity is affected by the hue, and vice versa.

## Hue Selection

### Background colors

Background colors (`background_primary`, `background_secondary`, `background_highlight`, `sidebar_background`, `toolbar_background`, `card_border`) should all belong to the same hue family. They are simply variations in lightness and saturation of the palette's defining hue.

### Font and foreground colors

The content roles form a spectrum from hue-close to hue-distinct relative to the background:

**`content_tertiary`** is used for inconspicuous, inactive elements that don't need to draw attention. Because it appears frequently and at low prominence, it should stay very close to the background's hue family — essentially a desaturated, lightened version of it. Too much hue deviation here would create visual noise.

**`content_resting`** serves a similar role to tertiary but where legibility still matters. It also stays within the background's hue family, slightly lighter and more neutral than tertiary, but should not introduce a distinct hue.

**`content_primary`** is the most-used foreground color — body text, primary labels, hovered elements. Because it appears constantly, it cannot be too hue-distinct from the background without causing eye strain. A shift toward a neighboring or near-neutral hue is appropriate; the goal is subtle differentiation, not contrast.

**`content_secondary`** is used for headings and selected states, which appear less frequently. This creates room for more hue distinction. A near-complementary or adjacent hue to the background works well here — the goal is a second "accent-like" color that adds visual interest to headings. Avoid pure complementary pairings (e.g., green text on a red background), as these create vibration and strain even at medium contrast. The hue can either be warmer or colder than the background; any sufficiently distinct hue that reads well as text is valid.

**`accent`** is a special case: it returns to the background's hue family, but at high saturation. It draws attention through vividness rather than hue contrast, keeping it visually coherent with the rest of the palette.

**`confirmation`** should be green when possible. However, if the main hue family of the palette is already green, a different color is acceptable.

**`destructive`** is functionally determined and independent of the palette's hue logic.
