# App Color Palette Guidelines

## Color Tier Structure (60-30-10)

FishTxt palettes are organized around three visual tiers, loosely following the 60-30-10 rule:

- **Tier 1 — Surfaces**: the dominant zone, covering most "background" elements in the UI. These colors form a cohesive family and should feel immersive and quiet.
- **Tier 2 — Headings**: provide hue contrast for certain *text* elements such as headings, and selected contexts in the sidebar panels (e.g., file navigator).
- **Tier 3 — Emphasis**: active button states and accent colors. These provide hierarchy and draw attention where needed.

## Mapping colors to usage

The following are key values in `colors.json` and their corresponding usage in the FishTxt app.

**Tier 1 - Surfaces:**

| Key | Usage | Luminosity range |
| --- | ----- | ---------------- |
| `surface` | background for the text editor and blob cards in the dashboard | 30–38 |
| `surface_sunken` | background for the dashboard area (behind cards) | 47–63 |
| `surface_raised` | overlayed with an `opacity` argument when an element is selected or hovered | 70–89 |
| `border_card` | a thin outline around folder and blob cards in the dashboard | 46–54 |
| `chrome_sidebar` | background for the sidebar button column | 28–42 |
| `chrome_panel` | background for expandable sidebar panels (file navigator, outline, merge) | 38–48 |
| `chrome_toolbar` | color of the unified window title bar + toolbar in macOS 13+ | 62–77 |
| `text_body` | main body text in the editor and blob cards; hovered elements in the sidebar | 191–199 |
| `text_resting` | list items in the file navigator and similar contexts where legibility matters but prominence does not | 175–188 |
| `text_muted` | inactive UI elements that can be clicked; used to make elements inconspicuous | 133–140 |

**Tier 2 - Headings:**

| Key | Usage | Luminosity range |
| --- | ----- | ---------------- |
| `text_heading` | headings in the editor; headings and section labels in sidebar panels; selected folder/blob in the file navigator; within-panel interactive elements that appear with headings (chevrons, back-buttons) | 160–180 |

**Tier 2 - Emphasis:**

| Key | Usage | Luminosity range |
| --- | ----- | ---------------- |
| `accent` | cursor color; active formatting buttons in the editor toolbar; active navigation buttons in the sidebar button column | varies by palette |
| `confirmation` | success states (e.g., save confirmation) | varies by palette |
| `destructive` | delete-related features; rarely visible | ~108 (fixed) |

## Luminosity and Contrast

### Design Philosophy

FishTxt's palettes are intentionally medium-contrast. Legibility is maintained through luminosity differences and slight hue differences between background and foreground roles, but the harshness of high-contrast pairings is avoided. This is a deliberate accommodation for astigmatism. New palettes should follow this same principle: avoid stark or near-pure-black/white pairings, and keep the overall feel soft and atmospheric.

### Overall Luminosity Target

Palette luminosity is measured as a weighted average (0.2126R + 0.7152G + 0.0722B) across a subset of roles called the **main tier**: `surface`, all `surface_*` colors, all `chrome_*` colors, and all `text_*` colors. The target for this average is approximately **115** (0–255 scale).

The rest are excluded from the main tier and should be treated separately when making palette-wide luminosity adjustments.

### Key Contrast Pairs

The ratios below describe the most legibility-critical pairings in the UI:

- `text_body` over `surface` (body text in editor). This is by far the most important. The luminosity gap between these two should be usually higher than the gap between other elements
- `text_resting` over `chrome_panel` (file navigator list)
- `accent` over `surface` (cursor, active UI elements)

As mentioned above, both luminosity differences and hue differences are utilized to maintain legibility without relying on sharp contrast. When making new palettes or adjusting existing ones, it is important to consider how the *perceived* luminosity is affected by the hue, and vice versa.

## Hue Selection

### Background colors: two approaches

All background roles (`surface`, `surface_sunken`, `surface_raised`, `border_card`, `chrome_sidebar`, `chrome_panel`, `chrome_toolbar`) belong to the same or closely related hue family. The visual distinction is achieved purely through luminosity and saturation steps.

This approach produces a more monochromatic, immersive feel. The risk is that the zones can blur together if the luminosity steps are too small, so care is needed to maintain enough separation between `surface`, `chrome_panel`, and `chrome_sidebar` in particular.itor and sidebar

### Text and foreground colors

The text roles form a spectrum from hue-close to hue-distinct relative to the *surface* background:

**`text_muted`** is used for inconspicuous, inactive elements that don't need to draw attention. Because it appears frequently and at low prominence, it should stay very close to the surface hue family — essentially a desaturated, lightened version of it. Too much hue deviation here would create visual noise.

**`text_resting`** serves a similar role to muted but where legibility still matters. It also stays within the surface hue family, slightly lighter and more neutral than muted, but should not introduce a distinct hue.

**`text_body`** is the most-used foreground color — body text, hovered elements. Because it appears constantly, it cannot be too hue-distinct from the surface without causing eye strain. A shift toward a neighboring or near-neutral hue is appropriate; the goal is subtle differentiation, not contrast.

**`text_heading`** is used for headings and selected states, which appear less frequently. This creates room for more hue distinction. An adjacent or near-complementary hue to the surface works well here — the goal is a second "accent-like" color that adds visual interest to headings. Avoid pure complementary pairings (e.g., green text on a red background), as these create vibration and strain even at medium contrast. The hue can be either warmer or colder than the surface; any sufficiently distinct hue that reads well as text is valid. However, if possible, it should stay reasonably close to the `text_body` hue.

Note that `text_heading` also appears over the chrome zone (panel headers, selected items in the file navigator). When using Approach B (split hue family), verify that `text_heading` remains legible and coherent over both the surface and chrome backgrounds.

**`accent`** is a special case: usually, it returns to the surface hue family, but at high saturation. It draws attention through vividness rather than hue contrast, keeping it visually coherent with the rest of the palette. However, if the two main text colors are already close to the surface hue, `accent` should deviate from this pattern and provide more hue contrast to the overall palette.

**`confirmation`** should be a distinct hue. When possible, green is preferred. However, if the main hue family of the palette is already green, a different color is acceptable.

**`destructive`** is functionally determined and independent of the palette's hue logic.
