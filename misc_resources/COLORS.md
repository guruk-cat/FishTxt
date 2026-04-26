# Design Principles for App Color Palletes

## FishTxt's UI Layout

With the unifieid, macOS-level toolbar/window title bar at the top, the app's window presents the following elements in order, from left to right:

- Sidebar buttons column. Always present.
- Sidebar panels. Expandable and Collapsible.
- Either: (a) Dashboard, or (b) Editor. Always present.

Note that the Dashboard will usually also have "cards," which contain text and are presented in an ordered grid on top of the Dashboard area.

## Hue Tier Structure

A palette is organized along three hue tiers, loosely following the idea of the 60-30-10 rule:

- **Tier 1:** This is the dominant hue. It includes most "background" elements in the UI, as well as most of the text that appears in them.
- **Tier 2:** This should be distinguishable from the tier 1 hue, but the contrast should not be too conspicuous.
- **Tier 3:** These colors provide an accent-like hue contrast via certain text elements and buttons when active.

## Mapping colors to usage

The following are key values in `colors.json` and their corresponding usage in the FishTxt app.

| Key | Usage |
| --- | ----- |
| `surface` | background for the text editor and blob cards in the dashboard |
| `surface_sunken` | background for the dashboard area (behind cards) |
| `surface_raised` | overlayed with an `opacity` argument when an element is selected or hovered |
| `border_card` | a thin outline around folder and blob cards in the dashboard |
| `chrome_sidebar` | background for the sidebar button column |
| `chrome_panel` | background for expandable sidebar panels (file navigator, outline, merge) |
| `chrome_toolbar` | color of the unified window title bar + toolbar in macOS 13+ |
| `text_body` | main body text in the editor and blob cards; hovered elements in the sidebar |
| `text_resting` | list items in the file navigator and similar contexts where legibility matters but prominence does not |
| `text_muted` | inactive UI elements that can be clicked; used to make elements inconspicuous |
| `text_heading` | headings in the editor; headings and section labels in sidebar panels; selected folder/blob in the file navigator; within-panel interactive elements that appear with headings (chevrons, back-buttons) |
| `meta_indication` | cursor color; active formatting buttons in the editor toolbar |
| `meta_confirmation` | success states (e.g., save confirmation) |
| `destructive` | delete-related features; rarely visible |

## Luminosity Contrast

FishTxt's palettes are intentionally medium-contrast. Legibility is maintained through slight differences in hue and saturation *in addition to* differences in luminosity. Sharp contrast in luminosity are avoided in order to accommodate for astigmatism.

When calculating, comparing, or evaluating luminosity of certain color roles or the whole palette, a weighted luminosity is used: 0.2126R + 0.7152G + 0.0722B.

Moreover, when calculating the average luminosity of a palette, colors that occur rarely in the UI are excluded from this calculation. These are the `meta_*` colors and `destructive`.

## Key Contrast Pairs

The ratios below describe the most legibility-critical pairings in the UI:

- `text_body` over `surface` (e.g., body text in editor). This is by far the most important. The luminosity gap between these two should be usually higher than the gap between other elements.
- `text_resting` over `chrome_panel` (e.g., file navigator list).

## Details on Text and Foreground Colors

The text roles form a spectrum from hue-close to hue-distinct relative to the *surface* background:

**`text_muted`** is used for inconspicuous, inactive elements that don't need to draw attention. Because it appears frequently and at low prominence, it should stay very close to the surface hue family — essentially a desaturated, lightened/darkened version of it. Too much hue deviation here would create visual noise.

**`text_resting`** serves a similar role to muted but where legibility still matters. It also stays within the surface hue family, slightly lighter/darker and more neutral than `text_muted`, but should not introduce a distinct hue.

**`text_body`** is the most-used foreground color. Because it appears constantly, it cannot be too hue-distinct from the surface without causing eye strain. A shift toward a neighboring or near-neutral hue is appropriate; the goal is subtle differentiation in hue, not contrast in hue.

**`text_heading`** is used for headings and selected states, which appear less frequently. This creates room for more hue distinction. An adjacent or near-complementary hue to the surface works well here — the goal is an "accent-like" color that adds visual interest to headings. Avoid pure complementary pairings (e.g., green text on a red background), as these create vibration and strain even at medium contrast.

Note that `text_heading` also appears over the chrome zone (panel headers, selected items in the file navigator). Thus, this color is chosen to remain legible and coherent over both the surface and chrome backgrounds.

**`meta_indication`** is a special case. Usually, it returns to the surface hue family, but at high saturation. But this color can afford to deviate more from the main hue family. The decision is made based on how much hue contrast `text_heading` provides (or doesn't provide) already.

**`meta_confirmation`** should be a distinct hue. When possible, green is preferred. However, if the main hue family of the palette is already green, a different color is acceptable.

**`destructive`** is functionally determined and independent of the palette's hue logic. It should be red.
