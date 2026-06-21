---
name: stata-bubble-chart
description: >-
  Generate publication-quality weighted bubble / scatter charts in Stata,
  in the editorial style of the IMF "Work and wealth" (F&D magazine) chart —
  bubble AREA proportional to a size variable (population, GDP, sales…),
  bubbles COLORED by a categorical group with a clean legend, a (log or linear)
  axis with custom tick labels, selective text labels on chosen points, and a
  dashed quadratic/linear trend line, using community packages (schemepack,
  grstyle, palettes/colrspace). Use this whenever the user wants a "bubble
  chart", "泡泡圖", a scatter where point size encodes a third variable, an
  Economist/IMF/F&D-style country/firm scatter, GDP-vs-something with dots sized
  by population, or asks to reproduce that IMF working-hours chart — even if they
  don't name Stata explicitly but the data work is clearly in Stata (.dta, .do).
  Not for plain unweighted scatters with no size encoding (base twoway scatter is
  enough), and not for non-Stata tools (matplotlib/ggplot/Excel).
---

# Stata bubble chart (IMF "Work and wealth" style)

Produce a weighted bubble scatter that looks like a magazine chart: bubble area
encodes a size variable, color encodes a group, only a few points are labelled,
and a dashed trend line runs through the cloud. The heart of this skill is a
parametrized do-file template — you adapt its SETTINGS block to the user's data
rather than writing twoway commands from scratch each time.

## Workflow

1. **Understand the data.** You need a dataset with one row per entity (country,
   firm, person…) and these roles. Ask the user only for what's missing:
   - **x**, **y** — the two positional variables.
   - **size** — drives bubble area; must be strictly positive (e.g. population).
   - **group** — a categorical variable for color + legend. Can be a string
     (the template auto-`encode`s it) or a numeric with a value label.
   - **label** + **flag** — a string name var, and a 0/1 flag for *which* points
     to label. Labelling every point is unreadable; default to labelling only
     the notable ones (largest bubbles, or whatever the user cares about).

2. **Copy and adapt the template.** Copy `scripts/bubble_chart.do` next to the
   user's data (or into their project) and edit only the SETTINGS block at the
   top — variable names, axis ticks, titles, log-vs-linear, trend type. Don't
   rewrite the plotting logic below the settings; it is designed to stay generic.
   Read `references/packages.md` before changing styling — it documents the
   scheme/palette/grstyle recipe and the non-obvious gotchas (opacity needs
   Stata 15+, weighted vs unweighted trend, log-axis tick behaviour).

3. **Run it.** The template installs the community packages if absent, builds the
   chart, and exports a PNG. If you have a working Stata you can run headless with
   `stata-mp -b do bubble_chart.do` (or `StataSE`/`stata`); otherwise hand the
   user the do-file to run in their GUI. Open/inspect the PNG and check: bubbles
   not overlapping into mush, legend readable, labels not colliding, trend line
   sensible.

4. **Reproducing the IMF chart specifically.** If the user wants *that* chart
   (GDP per adult vs weekly hours, dots sized by population), follow
   `references/imf-example.md` — it uses the bundled `assets/imf_example_data.csv`
   (synthetic, ~28 countries) and the exact settings that match the original look
   (log x-axis 2→180, 7 region colors, quadratic trend, ~14 labelled countries).

5. **Watching change over time (cross-period / cross-year).** If the user wants to
   compare several years/periods, use `scripts/bubble_chart_panel.do` instead — it
   draws one bubble panel per period and combines them side-by-side with a single
   shared legend (small multiples). It needs a long panel dataset (one row per
   entity-period) with a `time` variable; the bundled `assets/bubble_panel_data.csv`
   (synthetic, 16 entities × 3 years) demonstrates it. Two things make the panels
   genuinely comparable, and you should preserve them: **fixed identical axes**
   across panels (`xscale(range())` + a fixed `ylabs`), and an **invisible anchor
   point** carrying the global-max size so `[aw=]` scales bubble area the same way
   in every panel — otherwise each panel rescales to its own largest bubble and the
   sizes lie. Label only one panel (default: the last) to keep it readable.

## Key design choices (why the template looks the way it does)

- **One `scatter` per group, overlaid in a loop.** This is more verbose than
  Stata 18's single-scatter `colorvar()`, but it gives a clean categorical legend
  and lets you control each group's color/opacity — and it works on Stata 14+.
  See `references/packages.md` for the `colorvar()` alternative if you prefer it.
- **Bubble area, not diameter, ∝ size.** Stata's `[aw=size]` maps the weight to
  marker *area*, which is the perceptually correct encoding. Tune overall size
  with the `bubmult` multiplier, not by transforming the size variable.
- **Selective labels via an invisible overlay.** `mlabel(name) if flag==1` is not
  valid inline; instead a final `scatter … if flag==1, msymbol(none) mlabel(name)`
  draws only the text. This is the standard Stata idiom for labelling a subset.
- **Trend line defaults to unweighted `qfit`.** A quadratic captures the
  rise-then-fall shape in the IMF chart. Weighting it by population (`trendwt 1`)
  makes big countries dominate — offer both; unweighted is the safer default.

## Common adjustments

- **Softer color blending / gradient where bubbles overlap** → lower `opacity`
  (it is a 0-100 SETTING; ~30-45 gives a soft translucent gradient for dense
  data, 60-70 stays crisp for sparse data). The translucent fill plus a slightly
  darker `mlcolor` edge is what gives the layered, gradient-like look — that's by
  design, not a separate gradient fill (Stata markers can't do radial gradients).
  For smoother hue transitions between groups, pick a palette with graded hues
  (`palette viridis` / `plasma` / `spectral`) instead of the categorical `tableau`.
- **Bubbles too big / overlapping** → lower `bubmult` (e.g. 0.8) and/or `opacity`.
- **Linear instead of log x-axis** → set `xlog 0` and give linear `xlabs`.
- **No trend line** → `trend none`. Straight line → `trend lfit`.
- **Labels collide** → reduce how many points are flagged, or use a per-point
  clock-position variable; see the `mlabvpos` note in `references/packages.md`.
- **Different color feel** → change `palette` (any `colorpalette` name, e.g.
  `economist`, `tableau`, `viridis`) or `scheme` (any schemepack scheme).

Keep the user's existing graph conventions if their project already has a scheme
or color standard — match it rather than imposing `white_tableau`.

## Data & attribution

The bundled datasets are **illustrative synthetic data**, not real statistics and
not copied from any IMF/F&D publication — only the chart *type* and *theme* are
shared. This skill reimplements the visual style in standard Stata; it does not
reproduce anyone's figure or data. When you make a chart for the user from real
data, that's their data. Keep a "synthetic / illustrative" note on demo charts so
they are never mistaken for sourced statistics, and never label a chart "IMF" or
copy real published numbers unless the user supplies them.
