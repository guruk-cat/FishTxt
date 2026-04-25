# App Color Palette Guidelines

## Color Tier Structure (60-30-10)

FishTxt palettes are organized around three visual tiers, loosely following the 60-30-10 rule:

- **60% — Writing surface**: the dominant zone, covering the text editor, dashboard (including cards and its background), and body text. These colors form a cohesive family and should feel immersive and quiet.
- **30% — App chrome**: the navigation zone, covering the sidebar button column, expandable panels, and macOS toolbar. These colors anchor the UI shell and create a clear boundary from the content area.
- **10% — Emphasis**: headings, active states, accent colors. These provide hierarchy and draw attention where needed.

## Mapping colors to usage

The following are key values in `colors.json` and their corresponding usage in the FishTxt app.

**60% — Writing surface:**

| Key | Usage | Luminosity range |
| --- | ----- | ---------------- |
| `surface` | background for the text editor and blob cards in the dashboard | 30–38 |
| `surface_sunken` | background for the dashboard area (behind cards) | 47–63 |
| `surface_raised` | overlayed with an `opacity` argument when an element is selected or hovered | 70–89 |
| `border_card` | a thin outline around folder and blob cards in the dashboard | 46–54 |
| `text_body` | main body text in the editor and blob cards; hovered elements in the sidebar | 191–199 |
| `text_resting` | list items in the file navigator and similar contexts where legibility matters but prominence does not | 175–188 |
| `text_muted` | inactive UI elements that can be clicked; used to make elements inconspicuous | 133–140 |

**30% — App chrome:**

| Key | Usage | Luminosity range |
| --- | ----- | ---------------- |
| `chrome_sidebar` | background for the sidebar button column | 28–42 |
| `chrome_panel` | background for expandable sidebar panels (file navigator, outline, merge) | 38–48 |
| `chrome_toolbar` | color of the unified window title bar + toolbar in macOS 13+ | 62–77 |

**10% — Emphasis:**

| Key | Usage | Luminosity range |
| --- | ----- | ---------------- |
| `text_heading` | headings in the editor; headings and section labels in sidebar panels; selected folder/blob in the file navigator; within-panel interactive elements (chevrons, toggles) | 160–178 |
| `accent` | cursor color; active formatting buttons in the editor toolbar; active navigation buttons in the sidebar button column | varies by palette |
| `confirmation` | success states (e.g., save confirmation) | varies by palette |
| `destructive` | delete-related features; rarely visible | ~108 (fixed) |

## Luminosity and Contrast

### Design Philosophy

FishTxt's palettes are intentionally medium-contrast. Legibility is maintained through luminosity differences and slight hue differences between background and foreground roles, but the harshness of high-contrast pairings is avoided. This is a deliberate accommodation for astigmatism. New palettes should follow this same principle: avoid stark or near-pure-black/white pairings, and keep the overall feel soft and atmospheric.

### Overall Luminosity Target

Palette luminosity is measured as a weighted average (0.2126R + 0.7152G + 0.0722B) across a subset of roles called the **main tier**: `surface`, `surface_*`, `border_card`, `chrome_sidebar`, `chrome_panel`, `chrome_toolbar`, and all `text_*` colors. The target for this average is approximately **115** (0–255 scale).

The rest are excluded from the main tier and should be treated separately when making palette-wide luminosity adjustments.

### Key Contrast Pairs

The ratios below describe the most legibility-critical pairings in the UI, expressed as foreground luminosity / background luminosity. These serve as a reference when evaluating new palettes or auditing drift.

| Pair | morning seafoam | wild berries | 70's carpet | portland fog | douglas fir |
| ---- | --------------- | ------------ | ----------- | ------------ | ----------- |
| `text_body` over `surface` (body text in editor) | — | — | — | — | — |
| `text_resting` over `chrome_panel` (file navigator list) | — | — | — | — | — |
| `accent` over `surface` (cursor, active UI elements) | — | — | — | — | — |

*(Ratios to be filled in after palette values are finalized.)*

As mentioned above, both luminosity differences and hue differences are utilized to maintain legibility without relying on sharp contrast. When making new palettes or adjusting existing ones, it is important to consider how the *perceived* luminosity is affected by the hue, and vice versa.

## Hue Selection

### Background colors: two approaches

The 60% and 30% zones can be hued in one of two ways. Both are valid; the choice defines the overall character of the palette.

---

**Approach A — Single hue family:**

All background roles (`surface`, `surface_sunken`, `surface_raised`, `border_card`, `chrome_sidebar`, `chrome_panel`, `chrome_toolbar`) belong to the same or closely related hue family. The visual distinction between the 60% and 30% zones is achieved purely through luminosity and saturation steps — the chrome zone is typically slightly lighter or more saturated than the surface zone.

This approach produces a more monochromatic, immersive feel. The risk is that the zones can blur together if the luminosity steps are too small, so care is needed to maintain enough separation between `surface` and `chrome_panel` in particular.

*Most of the existing palettes follow this approach.*

---

**Approach B — Split hue family:**

The 60% zone (`surface`, `surface_sunken`, `surface_raised`, `border_card`) uses one hue family, and the 30% zone (`chrome_sidebar`, `chrome_panel`, `chrome_toolbar`) uses a distinctly different hue family. The hue contrast itself creates a clear visual boundary between the content area and the navigation chrome, reducing reliance on luminosity differences alone.

The two hues should:

- Be clearly distinguishable at the boundary between editor and sidebar
- Avoid vibration — pure complementary pairings at this boundary can be harsh; analogous or warm/cool pairings tend to be smoother
- Still feel intentional together, not accidental

One practical consideration: several text colors (`text_body`, `text_heading`, `text_resting`, `text_muted`) appear over *both* the 60% zone (editor, cards) and the 30% zone (panels, chrome). When using split hues, these shared text colors should be chosen to remain legible and visually coherent over both backgrounds. This is easiest when the two background hues are not too far apart in perceived temperature.

---

Within either approach, `surface_sunken` and `surface_raised` should remain clearly within the 60% hue family, as they are variations of the editor surface rather than chrome elements.

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
