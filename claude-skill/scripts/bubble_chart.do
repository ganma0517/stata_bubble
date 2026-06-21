*===========================================================================*
* bubble_chart.do — editorial-style weighted bubble scatter (IMF "F&D" look)
*
* WHAT IT DRAWS
*   A scatter where: bubble AREA  proportional to `size'
*                    bubble COLOR proportional to `group' (+ legend)
*                    only flagged points get text labels
*                    a dashed trend line runs through the cloud.
*
* HOW TO USE
*   1. Edit ONLY the SETTINGS block below.
*   2. Run in Stata 15+ (opacity needs 15+). Tested on Stata 18 MP.
*      Headless:  stata-mp -b do bubble_chart.do
*   3. The PNG is written to `out'.
*
* DATA SHAPE (one row per entity, e.g. one country)
*   x var    : horizontal position           (e.g. GDP per adult)
*   y var    : vertical position              (e.g. weekly hours)
*   size var : bubble area weight, MUST be >0 (e.g. population)
*   group    : categorical, color + legend    (string OK -> auto-encoded)
*   name     : string label printed by bubbles
*   flag     : 1 = print this entity's label  (set flag "" to label none)
*===========================================================================*

version 15
clear all
set more off

*------------------------------ SETTINGS -----------------------------------*
* ---- data + variable roles ----
local data    "imf_example_data.csv"   // .dta or .csv next to this do-file
local x        gdp                      // x-axis variable
local y        hours                    // y-axis variable
local size     pop                      // bubble size (area weight) variable
local group    region                   // group var (string or numeric+label)
local name     country                  // string label variable
local flag     labelme                  // 1 = show label, or "" to label none

* ---- axes ----
local xlog      1                       // 1 = log x-axis, 0 = linear
local xlabs     "2 5 10 20 50 100 180"  // x tick positions (in data units)
local ylabs     ""                      // y tick spec (numlist); "" = auto from data min
local xtitle    "GDP per adult (thousands of US$, PPP)"
local ytitle    "Weekly hours worked per adult"
local title     "Work and wealth"
local subtitle  "Income explains only a small fraction of working-hours variation"
local note      "Bubble area is proportional to population. Synthetic data."

* ---- look ----
local scheme    white_tableau           // any schemepack scheme
local palette   tableau                 // any colorpalette name for the groups
local opacity   50                      // bubble fill opacity 0-100; LOWER = softer
                                        //   gradient where bubbles overlap (try 30-45
                                        //   for dense data, 60-70 for sparse)
local bubmult   1.4                     // overall bubble size multiplier
local trend     qfit                    // qfit | lfit | none
local trendwt   0                       // 1 = weight trend by size, 0 = unweighted
local out       "bubble_chart.png"
*---------------------------------------------------------------------------*


*========================= (logic below — generic) =========================*

* ---- ensure community packages are present ----
foreach p in schemepack grstyle palettes colrspace {
    capture which `p'
    if _rc capture noisily ssc install `p', replace
}

* ---- load data ----
if strpos(lower("`data'"), ".csv") {
    import delimited "`data'", clear varnames(1) case(preserve)
}
else if "`data'" != "" {
    use "`data'", clear
}
* (or replace the block above with, e.g.,  sysuse auto, clear)

* ---- basic checks ----
capture confirm numeric variable `size'
if _rc {
    di as error "size variable `size' must be numeric and > 0"
    exit 198
}
quietly count if `size'<=0 & !missing(`size')
if r(N) di as error "WARNING: `r(N)' obs have size<=0; they will be dropped by [aw=]."

* ---- group must be numeric with value labels; encode if string ----
capture confirm string variable `group'
if !_rc {
    tempvar gnum
    encode `group', gen(`gnum')
    local group `gnum'
}

* ---- styling: scheme + minimal horizontal grid ----
set scheme `scheme'
grstyle init
grstyle set plain, horizontal grid
grstyle set legend 6, nobox

* ---- one color per group level ----
quietly levelsof `group', local(glevs)
local ng : word count `glevs'
colorpalette `palette', n(`ng') nograph
forvalues i = 1/`ng' {
    local col`i' "`r(p`i')'"      // capture now; later r-class calls overwrite r()
}

* ---- build one bubble overlay per group (=> clean categorical legend) ----
local plots ""
local legord ""
local i = 0
foreach g of local glevs {
    local ++i
    local plots `plots' (scatter `y' `x' if `group'==`g' [aw=`size'], ///
        msymbol(O) mcolor("`col`i''"%`opacity') mlcolor("`col`i''") ///
        mlwidth(vthin) msize(*`bubmult'))
    local glab : label (`group') `g'
    if "`glab'" == "" local glab "`g'"
    local legord `legord' `i' "`glab'"
}

* ---- dashed trend line (drawn over bubbles) ----
local trplot ""
if "`trend'" != "none" {
    local trwt ""
    if `trendwt'==1 local trwt "[aw=`size']"
    local trplot (`trend' `y' `x' `trwt', lpattern(dash) lcolor(gs6) lwidth(medthick))
}

* ---- selective text labels (invisible markers, text only, on top) ----
local labplot ""
if "`flag'" != "" {
    local labplot (scatter `y' `x' if `flag'==1, msymbol(none) ///
        mlabel(`name') mlabsize(small) mlabcolor(black) ///
        mlabposition(12) mlabgap(*1.4))
}

* ---- x-axis scale ----
local xsc ""
if `xlog'==1 local xsc "xscale(log)"

* ---- draw ----
twoway `plots' `trplot' `labplot', ///
    `xsc' xlabel(`xlabs', format(%9.0g)) ylabel(`ylabs', angle(0)) ///
    xtitle("`xtitle'") ytitle("`ytitle'") ///
    title("`title'", size(large)) subtitle("`subtitle'", size(small)) ///
    note("`note'", size(vsmall)) ///
    legend(order(`legord') pos(6) cols(2) size(vsmall) symxsize(*0.5) ///
        region(lcolor(none))) ///
    graphregion(color(white)) plotregion(margin(medium))

graph export "`out'", replace width(2200)
display "WROTE: `out'"

* reset session styling so this do-file doesn't pollute later graphs
grstyle clear
