# Worked example: reproduce the IMF "Work and wealth" chart

Recreates the F&D magazine chart — GDP per adult (log axis) vs weekly hours
worked, bubbles sized by population, colored by world region, ~14 countries
labelled, dashed quadratic trend. Uses the bundled synthetic dataset
`assets/imf_example_data.csv` (~28 countries; values are illustrative, not the
real Gethin–Saez numbers).

## Fastest path

The default SETTINGS in `scripts/bubble_chart.do` are already tuned for this
chart. Copy the do-file and the CSV into the same folder and run:

```bash
stata-mp -b do bubble_chart.do      # or run in the Stata GUI
```

That produces `bubble_chart.png`. The settings that matter for matching the look:

```stata
local x        gdp
local y        hours
local size     pop
local group    region          // string -> auto-encoded; 7 regions
local name     country
local flag     labelme         // 14 countries pre-flagged in the CSV
local xlog      1
local xlabs     "2 5 10 20 50 100 180"
local ylabs     ""              // "" = auto y-axis from data min (clearer proportions)
local scheme    white_tableau
local palette   tableau
local trend     qfit            // rise-then-fall quadratic
local trendwt   0               // unweighted, like the original dashed curve
```

## Self-contained version (no external CSV)

If you want a single do-file with the data inline (handy for sharing), replace
the data-loading block with an `input` block. Sketch:

```stata
clear
input str20 country str40 region double(gdp hours pop) byte labelme
"China"          "East and Southeast Asia"  25 31 1412 1
"India"          "South Asia"               12 25 1417 1
"United States"  "Western Europe and Anglosphere" 100 22 333 1
* ... (remaining rows from imf_example_data.csv) ...
end
```

Then continue with the same styling/plot logic from `bubble_chart.do` (everything
below its SETTINGS block).

## Notes on fidelity

- The original labels ~14 countries and lets bubbles overlap with transparency —
  hence `opacity 55` and the selective `labelme` flag rather than labelling all 28.
- The real chart's x-axis runs 2→180 thousand $ on a log scale; `xscale(log)` +
  the custom `xlabs` reproduces the uneven tick spacing.
- The dashed curve is a quadratic fit; population-weighting it would pull it
  toward China/India, so the example keeps it unweighted (`trendwt 0`).
- To get closer to the exact F&D palette, swap `palette economist` or define the
  seven region colors by hand and pass them as `col1…col7`.
