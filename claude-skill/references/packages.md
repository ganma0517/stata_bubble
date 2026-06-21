# Community packages, styling recipe & gotchas

Verified building blocks for the bubble chart. Version notes matter: **opacity
(`color%pct`) needs Stata 15+**; the single-scatter `colorvar()` alternative
needs **Stata 18+**. The template uses the loop-overlay approach so it runs on
Stata 14.2+ (schemepack/grstyle/palettes all require ≥14.2).

## Install

```stata
ssc install schemepack, replace   // Asjad Naqvi — editorial schemes
ssc install grstyle, replace      // Ben Jann — fine-grained style control
ssc install palettes, replace     // Ben Jann — colorpalette (color sets)
ssc install colrspace, replace    // Ben Jann — color engine palettes depends on
```

The template installs any that are missing automatically (`capture which` →
`ssc install`).

## Scheme + minimal grid recipe

```stata
set scheme white_tableau           // clean white bg, Tableau-10 categorical colors
grstyle init
grstyle set plain, horizontal grid // no box/background; horizontal gridlines only
grstyle set legend 6, nobox        // legend at 6 o'clock, no surrounding box
```

- Good clean schemes for this look: **`white_tableau`** (best for ≤10 groups),
  `white_w3d`, `gg_tableau` (ggplot grey panel). Avoid sequential schemes
  (`white_viridis`, `white_cividis`) for *categorical* groups.
- `grstyle set plain` strips the box/background; the trailing `horizontal`/
  `vertical` keep only those gridlines. Omit a direction to drop it.
- `grstyle clear` reverts styling for the session — the template calls it at the
  end so it doesn't bleed into the user's later graphs. grstyle changes are **not
  persisted** across Stata sessions unless you re-run them.

## Colors per group

```stata
colorpalette tableau, n(7) nograph   // 7 distinct colors -> r(p1)..r(p7)
local c1 "`r(p1)'"                    // capture immediately; next r-class call wipes r()
```

- `n(#)` sets how many colors; results in `r(p1)…r(p#)`, full list in `r(p)`.
- **Gotcha:** `r(p*)` is overwritten by the *next* r-class command. The template
  copies all colors into `col1…colN` locals in a tight `forvalues` loop *before*
  building any plots. If you reorder things and colors come out wrong/empty, this
  is why.
- Any palette name works: `tableau`, `economist`, `viridis`, `set1`, `d3`, etc.
  Run `colorpalette, list` to browse.

## Coloring bubbles by group — two approaches

**(A) Loop overlay — what the template uses. Works Stata 14+.**
```stata
local plots ""
forvalues k = 1/`ng' {
    local plots `plots' (scatter y x if grp==`k' [aw=size], ///
        msymbol(O) mcolor("`col`k''"%55) mlcolor("`col`k''"))
}
twoway `plots', legend(order(1 "A" 2 "B" ...))
```
Full control over each group's color/opacity/label and a clean categorical
legend. Verbose but robust.

**(B) Stata 18 single-scatter `colorvar()`.** Terser, but legend reordering is
clumsy and per-group marker labels are hard. Use only if you're on 18+ and don't
need selective labels per group:
```stata
twoway scatter y x [aw=size], colorvar(grp) colordiscrete ///
    coloruseplegend plegend(order(7 6 5 4 3 2 1))
```

## Weighted bubble size

```stata
scatter y x [aw=size], msymbol(O) msize(*1.4) mcolor(navy%40) mlcolor(navy)
```
- With `[aw=]`, marker **AREA** ∝ weight — the perceptually correct mapping. Do
  **not** pre-transform size to "fix" bubble sizes; tune `msize(*mult)` instead.
- Use filled `msymbol(O)` so opacity shows; `Oh` is hollow (outline only).
- Opacity = `colorname%pct` (Stata 15+): `mcolor(navy%40)`. Separate fill/line
  with `mfcolor(navy%30) mlcolor(navy%80)`.
- `[aw=]` silently drops obs with weight ≤ 0 or missing — the template warns.

## Log x-axis with custom ticks

```stata
..., xscale(log) xlabel(2 5 10 20 50 100 180, format(%9.0g))
```
`xscale(log)` log-transforms the axis; `xlabel()` places ticks at those **data
values** (not exponents). The trend line shares the axis, so it bends correctly.

## Selective text labels

`mlabel(name) if flag==1` is **not** valid inline — `if` qualifies the whole
scatter. Standard idiom: a final overlay with an invisible marker carrying only
the label:
```stata
(scatter y x if flag==1, msymbol(none) mlabel(name) ///
    mlabsize(small) mlabposition(12) mlabgap(*1.4))
```
- `mlabposition(#)` is a clock position (1–12, 0 = centered).
- For per-point placement (to dodge collisions), make a variable holding a clock
  position per obs and pass `mlabvpos(thatvar)`.

## Trend line

```stata
(qfit y x [aw=size], lpattern(dash) lcolor(gs6) lwidth(medthick))   // quadratic
(lfit y x,            lpattern(dash) lcolor(gs6))                    // straight
```
- **`qfit`/`lfit` + weights:** `[aw=]` makes it a *weighted* least-squares fit, so
  large-population points dominate the curve. For a trend that reflects the
  unweighted relationship, drop the weight on the fit (template default
  `trendwt 0`) and keep it only on the bubbles.
- Neither `qfit` nor `lfit` auto-adds a *size* legend for the bubbles; like
  IMF/Economist charts, note "bubble area ∝ <var>" in the caption instead.
