*===========================================================================*
* bubble_chart_panel.do — multi-period SMALL-MULTIPLES bubble chart
*
* Draws the same weighted bubble scatter once per time period (e.g. year) and
* combines them side-by-side with ONE shared legend, so you can watch entities
* drift across the plane over time (cross-year observation).
*
* WHY IT LOOKS THE WAY IT DOES
*   - Axes are FIXED identical across every panel (`xscale(range())` + fixed
*     `ylabs`) — comparison across years is only meaningful on a common frame.
*   - A single invisible "anchor" point carrying the GLOBAL max size is added to
*     every panel so [aw=] scales bubble area the SAME way in each panel; without
*     it, each panel would rescale to its own largest bubble and sizes would not
*     be comparable across years.
*   - One legend via grc1leg2 instead of a legend per panel.
*
* DATA SHAPE: long panel — one row per entity-period.
*   needs a `time' variable (year) in addition to x / y / size / group / name.
*
* HOW TO USE: edit the SETTINGS block, run in Stata 15+ (tested on Stata 18 MP).
*   stata-mp -b do bubble_chart_panel.do
*===========================================================================*

version 15
clear all
set more off

*------------------------------ SETTINGS -----------------------------------*
local data    "bubble_panel_data.csv"   // .dta or .csv (long panel)
local time     year                      // period variable (one panel per value)
local x         gdp
local y         hours
local size      pop
local group     region                   // string or numeric+label
local name      country
local flag      labelme                  // 1 = label this entity (set "" = none)

local xlog      1
local xrange    "2 180"                  // fixed x range shared by all panels
local xlabs     "2 5 10 20 50 100 180"
local ylabs     "15(5)40"                // fixed y ticks shared by all panels
local yrange    "15 40"                  // fixed y range; start at the data minimum
local xtitle    "GDP per adult ($000s, synthetic)"
local ytitle    "Weekly hours worked"
local sharey    1                        // 1 = show Y axis + ytitle only on the
                                         //   first panel (shared-axis small-multiples);
                                         //   0 = repeat Y axis on every panel
local gtitle    "Work and wealth over time"   // overall title
local note      "ILLUSTRATIVE SYNTHETIC DATA - not real statistics. Bubble area proportional to population."

local scheme    white_tableau
local palette   tableau
local opacity   35                       // lower => more transparent / softer overlap
local bubmult   1.3
local gridcolor gs9                       // X & Y gridline color (lower gs = darker/stronger)
local trend     qfit                     // qfit | lfit | none (per panel)
local labelpanel "last"                  // which panel gets text labels: first | last | all
local out       "bubble_chart_panel.png"
*---------------------------------------------------------------------------*


*========================= (logic below — generic) =========================*
foreach p in schemepack grstyle palettes colrspace grc1leg2 {
    capture which `p'
    if _rc capture noisily ssc install `p', replace
}

if strpos(lower("`data'"), ".csv") import delimited "`data'", clear varnames(1) case(preserve)
else if "`data'" != "" use "`data'", clear

capture confirm string variable `group'
if !_rc {
    tempvar gnum
    encode `group', gen(`gnum')
    local group `gnum'
}

* anchor: one invisible obs per period carrying the global max size, so [aw=]
* scales bubble area identically in every panel (cross-panel comparability).
quietly summarize `size'
local gmax = r(max)
gen byte _anchor = 0
quietly levelsof `time', local(times)
foreach t of local times {
    local nn = _N + 1
    set obs `nn'
    quietly replace _anchor = 1 in `nn'
    quietly replace `time'  = `t'    in `nn'
    quietly replace `size'  = `gmax' in `nn'
    * park the anchor at the x/y midpoint so it never expands the fixed axes
    quietly replace `x' = 10 in `nn'
    quietly replace `y' = 20 in `nn'
}

set scheme `scheme'
grstyle init
grstyle set plain
grstyle set legend 6, nobox

quietly levelsof `group', local(glevs)
local ng : word count `glevs'
colorpalette `palette', n(`ng') nograph
forvalues i = 1/`ng' {
    local col`i' "`r(p`i')'"
}

local xsc ""
if `xlog'==1 local xsc "xscale(log range(`xrange'))"
else local xsc "xscale(range(`xrange'))"

* which periods get text labels (labelling every panel is usually too busy)
local firsttime : word 1 of `times'
local lasttime  : word `: word count `times'' of `times'

local names ""
foreach t of local times {
    * one transparent anchor scatter (drives consistent bubble scaling)
    local anchor (scatter `y' `x' if _anchor==1 & `time'==`t' [aw=`size'], ///
        msymbol(O) mcolor(none) mlcolor(none) msize(*`bubmult'))

    * one bubble overlay per group
    local plots ""
    local legord ""
    local i = 0
    foreach g of local glevs {
        local ++i
        local plots `plots' (scatter `y' `x' if `group'==`g' & `time'==`t' & _anchor==0 [aw=`size'], ///
            msymbol(O) mcolor("`col`i''"%`opacity') mlcolor("`col`i''") mlwidth(vthin) msize(*`bubmult'))
        local glab : label (`group') `g'
        if "`glab'" == "" local glab "`g'"
        local legord `legord' `=`i'+1' "`glab'"   // +1 because anchor is plot 1
    }

    * trend line for this period
    local trplot ""
    if "`trend'" != "none" local trplot (`trend' `y' `x' if `time'==`t' & _anchor==0, ///
        lpattern(dash) lcolor(gs6) lwidth(medthick))

    * labels only on the chosen panel(s)
    local labplot ""
    local dolabel = ("`flag'"!="") & ("`labelpanel'"=="all" ///
        | ("`labelpanel'"=="last" & `t'==`lasttime') ///
        | ("`labelpanel'"=="first" & `t'==`firsttime'))
    if `dolabel' local labplot (scatter `y' `x' if `flag'==1 & `time'==`t' & _anchor==0, ///
        msymbol(none) mlabel(`name') mlabsize(vsmall) mlabcolor(black) mlabposition(12) mlabgap(*1.2))

    * shared-axis small multiples: only the first panel carries the Y axis +
    * ytitle; inner panels keep the same range (so bubbles line up) but hide the
    * redundant tick numbers and title, which also widens their plot area.
    local grid grid glcolor(`gridcolor') glwidth(thin)
    * shared-axis small multiples: only the first panel carries the Y axis (here a
    * black solid line) + tick numbers + ytitle; inner panels keep the same range
    * (so bubbles line up) but drop the line, numbers and title.
    if `sharey'==1 & `t'!=`firsttime' {
        local yt   ytitle("")
        local ylab ylabel(`ylabs', angle(0) nolabels noticks `grid')
        local ysc  yscale(range(`yrange') noline)
    }
    else {
        local yt   ytitle("`ytitle'", size(small))
        local ylab ylabel(`ylabs', angle(0) `grid')
        local ysc  yscale(range(`yrange') lcolor(black) lwidth(medthin))
    }
    local xlab xlabel(`xlabs', format(%9.0g) `grid')

    twoway `anchor' `plots' `trplot' `labplot', ///
        `xsc' `xlab' `ylab' `ysc' ///
        xtitle("`xtitle'", size(small)) `yt' ///
        title("`t'", size(medium)) ///
        legend(order(`legord') cols(4) size(vsmall) symxsize(*0.4) region(lcolor(none))) ///
        name(g`t', replace) nodraw

    local names `names' g`t'
}

* combine all periods with ONE shared legend
grc1leg2 `names', rows(1) legendfrom(g`lasttime') position(6) ///
    title("`gtitle'", size(medium)) ///
    note("`note'", size(vsmall)) ///
    imargin(small) graphregion(color(white))

graph export "`out'", replace width(3200)
display "WROTE: `out'"
grstyle clear
