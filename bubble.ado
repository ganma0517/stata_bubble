*! bubble v1.0  21Jun2026
*! Weighted bubble / scatter plot in the editorial style of the IMF "Work and
*! wealth" (F&D) chart: bubble AREA proportional to a size weight, bubbles
*! COLOURED by a group with a legend, optional log axes with custom ticks,
*! selective point labels, a dashed quadratic/linear trend line, and a
*! small-multiples (one panel per period) mode for cross-period comparison.
*!
*! Syntax:
*!   bubble yvar xvar [if] [in] [aweight] [ , options ]
*!
*! ---- size, grouping & colour ----
*!   [aweight=sizevar] bubble AREA is proportional to this weight (e.g. population)
*!   by(varname)       colour bubbles by this group and add a legend (string OK)
*!   palette(string)   any colorpalette name for the groups (default tableau)
*!   opacity(#)        bubble fill opacity 0-100 (default 50; lower = softer overlap)
*!   bubble(#)         overall bubble-size multiplier (default 1.3)
*!
*! ---- point labels ----
*!   mlabel(varname)   text label variable
*!   labelif(varname)  only label points where this 0/1 indicator is 1
*!
*! ---- faceting / cross-period ----
*!   panel(varname)    draw one bubble panel per level and combine (small multiples)
*!   sharey            show the Y axis (line + ticks + title) only on the first panel
*!   labelpanel(string) which panel is labelled: first | last | all (default last)
*!   cols(#)           number of columns when faceting (default: one row)
*!
*! ---- axes ----
*!   xlog ylog         log-scale the x and/or y axis
*!   xlabels(numlist)  custom x tick positions (data units), e.g. 2 5 10 20 50 100
*!   ylabels(numlist)  custom y tick positions
*!   xrange(# #) yrange(# #)  fixed axis ranges (shared across panels)
*!
*! ---- styling ----
*!   scheme(string)    schemepack scheme (default white_tableau)
*!   gridcolor(string) X & Y gridline colour (default gs9; lower gs = stronger)
*!   trend(string)     trend line: qfit | lfit | none (default none)
*!   legcols(#)        legend columns (default 2, or 4 in panel mode)
*!
*! ---- titles & output ----
*!   title() subtitle() xtitle() ytitle() note()   passed through
*!   saving() name() nodraw export(filename)        save / export the graph
*!
*! Requires: Stata 15 or newer, and the SSC packages schemepack, grstyle,
*!           palettes, colrspace (and grc1leg2 for panel mode). bubble installs
*!           any that are missing on first use.

program define bubble
    version 15.0
    syntax varlist(min=2 max=2 numeric) [if] [in] [aweight] ,            ///
        [                                                               ///
          BY(varname)                                                   ///
          PALette(string) OPacity(integer 50) BUBble(real 1.3)          ///
          MLABel(varname) LABELIf(varname)                              ///
          PANel(varname) SHAREy LABELPanel(string) COLs(integer 0)      ///
          XLOG YLOG XLABels(numlist) YLABels(numlist)                   ///
          XRANGE(numlist min=2 max=2) YRANGE(numlist min=2 max=2)       ///
          SCHeme(string) GRIDColor(string) TRend(string)                ///
          LEGCols(integer 0)                                            ///
          title(string) SUBtitle(string)                                ///
          XTITle(string) YTITle(string) note(string)                    ///
          saving(string asis) name(string) NODRAW EXPORT(string asis) ]

    gettoken yv xv : varlist
    marksample touse, novarlist

    * ---- defaults ----
    if "`palette'"==""     local palette   "tableau"
    if "`scheme'"==""      local scheme    "white_tableau"
    if "`gridcolor'"==""   local gridcolor "gs9"
    if "`trend'"==""       local trend     "none"
    if "`labelpanel'"==""  local labelpanel "last"
    local trend = lower("`trend'")
    if !inlist("`trend'","qfit","lfit","none") {
        di as error "trend() must be qfit, lfit, or none"
        exit 198
    }

    * ---- weight (bubble size) ----
    local awt ""
    if "`weight'"!="" local awt "[`weight'`exp']"
    else di as text "(no aweight given: bubbles drawn at a fixed size; add [aw=sizevar] to scale by size)"

    * ---- ensure community packages ----
    local need schemepack grstyle palettes colrspace
    if "`panel'"!="" local need `need' grc1leg2
    foreach p of local need {
        capture which `p'
        if _rc capture noisily ssc install `p', replace
    }

    * ---- group: encode if string, so it drives colour + a value-labelled legend ----
    local grp "`by'"
    if "`by'"!="" {
        capture confirm string variable `by'
        if !_rc {
            tempvar genc
            encode `by', gen(`genc')
            local grp "`genc'"
        }
    }

    * ---- styling ----
    set scheme `scheme'
    grstyle init
    grstyle set plain
    grstyle set legend 6, nobox

    * =====================================================================
    * Build the option strings shared by single- and panel-mode panels.
    * =====================================================================
    if "`xlog'"=="xlog"  local xlogf 1
    else local xlogf 0
    if "`ylog'"=="ylog"  local ylogf 1
    else local ylogf 0

    * preserve before any data modification (panel mode adds anchor rows)
    preserve
    quietly keep if `touse'

    if "`panel'"=="" {
        BubbleOne, yv(`yv') xv(`xv') grp(`grp') awt(`awt') ///
            palette(`palette') opacity(`opacity') bubble(`bubble') ///
            mlabel(`mlabel') labelif(`labelif') trend(`trend') ///
            xlogf(`xlogf') ylogf(`ylogf') gridcolor(`gridcolor') ///
            xlabels(`xlabels') ylabels(`ylabels') ///
            xrange(`xrange') yrange(`yrange') sharey(0) yaxisline(1) ///
            legcols(`legcols') ///
            title(`"`title'"') subtitle(`"`subtitle'"') ///
            xtitle(`"`xtitle'"') ytitle(`"`ytitle'"') note(`"`note'"') ///
            name(`"`name'"') nodraw(`"`nodraw'"')
    }
    else {
        BubblePanel, yv(`yv') xv(`xv') grp(`grp') size(`exp') awt(`awt') ///
            panel(`panel') sharey("`sharey'") labelpanel(`labelpanel') cols(`cols') ///
            palette(`palette') opacity(`opacity') bubble(`bubble') ///
            mlabel(`mlabel') labelif(`labelif') trend(`trend') ///
            xlogf(`xlogf') ylogf(`ylogf') gridcolor(`gridcolor') ///
            xlabels(`xlabels') ylabels(`ylabels') ///
            xrange(`xrange') yrange(`yrange') legcols(`legcols') ///
            title(`"`title'"') xtitle(`"`xtitle'"') ytitle(`"`ytitle'"') ///
            note(`"`note'"') name(`"`name'"')
    }

    grstyle clear
    if `"`saving'"'!="" graph save `saving'
    if `"`export'"'!="" graph export `export', replace width(2400)
end


* ---------------------------------------------------------------------------
* BubbleOne: draw a single bubble panel (also used as one cell of a facet).
* ---------------------------------------------------------------------------
program define BubbleOne
    syntax , yv(string) xv(string) [ grp(string) awt(string) ///
        palette(string) opacity(integer 50) bubble(real 1.3) ///
        mlabel(string) labelif(string) trend(string) ///
        xlogf(integer 0) ylogf(integer 0) gridcolor(string) ///
        xlabels(string) ylabels(string) xrange(string) yrange(string) ///
        sharey(integer 0) yaxisline(integer 1) firstpanel(integer 1) ///
        legcols(integer 0) title(string) subtitle(string) ///
        xtitle(string) ytitle(string) note(string) ///
        paneltitle(string) name(string asis) nodraw(string) ///
        anchorif(string) extraplot(string asis) ]

    * ---- colours, one per group level ----
    * extraplot (a transparent anchor scatter, panel mode) takes plot slot #1,
    * so legend keys are offset by `extra'.
    local extra = (`"`extraplot'"'!="")
    local plots `extraplot'
    local legord ""
    if "`grp'"!="" {
        quietly levelsof `grp', local(glevs)
        local ng : word count `glevs'
        colorpalette `palette', n(`ng') nograph
        forvalues i = 1/`ng' {
            local col`i' "`r(p`i')'"
        }
        local i = 0
        foreach g of local glevs {
            local ++i
            local plots `plots' (scatter `yv' `xv' if `grp'==`g' `anchorif' `awt', ///
                msymbol(O) mcolor("`col`i''"%`opacity') mlcolor("`col`i''") ///
                mlwidth(vthin) msize(*`bubble'))
            local glab : label (`grp') `g'
            if "`glab'"=="" local glab "`g'"
            local legord `legord' `=`i'+`extra'' "`glab'"
        }
    }
    else {
        local plots `plots' (scatter `yv' `xv' if 1 `anchorif' `awt', ///
            msymbol(O) mcolor(navy%`opacity') mlcolor(navy) msize(*`bubble'))
    }

    * ---- trend line ----
    local trplot ""
    if "`trend'"!="none" {
        local trplot (`trend' `yv' `xv' if 1 `anchorif', ///
            lpattern(dash) lcolor(gs6) lwidth(medthick))
    }

    * ---- selective labels ----
    local labplot ""
    if "`mlabel'"!="" {
        local lif ""
        if "`labelif'"!="" local lif "& `labelif'==1"
        local labplot (scatter `yv' `xv' if 1 `lif' `anchorif', msymbol(none) ///
            mlabel(`mlabel') mlabsize(vsmall) mlabcolor(black) ///
            mlabposition(12) mlabgap(*1.3))
    }

    * ---- axis option strings ----
    local grid grid glcolor(`gridcolor') glwidth(thin)

    if `xlogf'==1 {
        if "`xrange'"!="" local xsc xscale(log range(`xrange'))
        else local xsc xscale(log)
    }
    else {
        if "`xrange'"!="" local xsc xscale(range(`xrange'))
        else local xsc ""
    }
    if "`xlabels'"!="" local xlab xlabel(`xlabels', format(%9.0g) `grid')
    else local xlab xlabel(, `grid')

    if `ylogf'==1 local yscl yscale(log)
    else local yscl ""

    * Y axis: optionally hide on non-first panels (sharey); first panel can carry
    * a solid black axis line.
    if `sharey'==1 & `firstpanel'==0 {
        local yt ytitle("")
        if "`ylabels'"!="" local ylab ylabel(`ylabels', angle(0) nolabels noticks `grid')
        else local ylab ylabel(, angle(0) nolabels noticks `grid')
        if "`yrange'"!="" local yscl `yscl' yscale(range(`yrange') noline)
        else local yscl `yscl' yscale(noline)
    }
    else {
        local yt ytitle("`ytitle'", size(small))
        if "`ylabels'"!="" local ylab ylabel(`ylabels', angle(0) `grid')
        else local ylab ylabel(, angle(0) `grid')
        if `yaxisline'==1 {
            if "`yrange'"!="" local yscl `yscl' yscale(range(`yrange') lcolor(black) lwidth(medthin))
            else local yscl `yscl' yscale(lcolor(black) lwidth(medthin))
        }
        else if "`yrange'"!="" local yscl `yscl' yscale(range(`yrange'))
    }

    * ---- legend ----
    local lc = cond(`legcols'>0, `legcols', 2)
    if "`grp'"=="" local leg legend(off)
    else local leg legend(order(`legord') cols(`lc') size(vsmall) symxsize(*0.5) region(lcolor(none)))

    * ---- titles (panel cell uses paneltitle; single chart uses title) ----
    local ttl
    if `"`paneltitle'"'!="" local ttl title("`paneltitle'", size(medium))
    else if `"`title'"'!="" local ttl title("`title'", size(large))
    local sttl
    if `"`subtitle'"'!="" local sttl subtitle("`subtitle'", size(small))
    local nt
    if `"`note'"'!="" local nt note("`note'", size(vsmall))
    local xt
    if `"`xtitle'"'!="" local xt xtitle("`xtitle'", size(small))
    else local xt xtitle("`xv'", size(small))

    local nm
    if `"`name'"'!="" local nm name(`name', replace)

    twoway `plots' `trplot' `labplot', ///
        `xsc' `xlab' `ylab' `yscl' ///
        `xt' `yt' `ttl' `sttl' `nt' `leg' ///
        graphregion(color(white)) plotregion(margin(medium)) ///
        `nm' `nodraw'
end


* ---------------------------------------------------------------------------
* BubblePanel: one BubbleOne per level of panel(), combined with one legend.
* ---------------------------------------------------------------------------
program define BubblePanel
    syntax , yv(string) xv(string) panel(string) [ grp(string) size(string) ///
        awt(string) sharey(string) labelpanel(string) cols(integer 0) ///
        palette(string) opacity(integer 50) bubble(real 1.3) ///
        mlabel(string) labelif(string) trend(string) ///
        xlogf(integer 0) ylogf(integer 0) gridcolor(string) ///
        xlabels(string) ylabels(string) xrange(string) yrange(string) ///
        legcols(integer 0) title(string) xtitle(string) ///
        ytitle(string) note(string) name(string asis) ]

    if `"`name'"'=="" local name "bubble"
    local shareyf = ("`sharey'"!="")

    * size variable (strip the leading "= ") for the anchor trick
    local sizev ""
    if "`size'"!="" {
        local sizev = subinstr("`size'", "=", "", 1)
        local sizev = trim("`sizev'")
    }

    * anchor: one invisible obs per period carrying the GLOBAL max size, so [aw=]
    * scales bubble area identically in every panel (cross-panel comparability).
    local anchorif ""
    if "`sizev'"!="" {
        quietly summarize `sizev', meanonly
        local gmax = r(max)
        tempvar anchor
        quietly gen byte `anchor' = 0
        quietly levelsof `panel', local(plevs)
        * a within-range parking spot so the anchor never expands the fixed axes
        local px = 10
        local py = 20
        if "`xrange'"!="" {
            local xlo : word 1 of `xrange'
            local xhi : word 2 of `xrange'
            local px = (`xlo'+`xhi')/2
        }
        if "`yrange'"!="" {
            local ylo : word 1 of `yrange'
            local yhi : word 2 of `yrange'
            local py = (`ylo'+`yhi')/2
        }
        foreach t of local plevs {
            local nn = _N + 1
            quietly set obs `nn'
            quietly replace `anchor' = 1      in `nn'
            quietly replace `panel'  = `t'    in `nn'
            quietly replace `sizev'  = `gmax' in `nn'
            quietly replace `xv'     = `px'   in `nn'
            quietly replace `yv'     = `py'   in `nn'
        }
        local anchorif "& `anchor'==0"
    }
    else quietly levelsof `panel', local(plevs)

    local firsttime : word 1 of `plevs'
    local lasttime  : word `: word count `plevs'' of `plevs'

    local names ""
    local first = 1
    foreach t of local plevs {
        local fp = (`t'==`firsttime')

        * which panel(s) get text labels
        local mlab "`mlabel'"
        local dolab = ("`labelpanel'"=="all") ///
            | ("`labelpanel'"=="last"  & `t'==`lasttime') ///
            | ("`labelpanel'"=="first" & `t'==`firsttime')
        if !`dolab' local mlab ""

        * anchor scatter for this period (transparent; drives bubble scaling)
        local anc ""
        if "`sizev'"!="" local anc (scatter `yv' `xv' if `anchor'==1 & `panel'==`t' `awt', msymbol(O) mcolor(none) mlcolor(none) msize(*`bubble'))

        BubbleOne, yv(`yv') xv(`xv') grp(`grp') awt(`awt') ///
            palette(`palette') opacity(`opacity') bubble(`bubble') ///
            mlabel(`mlab') labelif(`labelif') trend(`trend') ///
            xlogf(`xlogf') ylogf(`ylogf') gridcolor(`gridcolor') ///
            xlabels(`xlabels') ylabels(`ylabels') ///
            xrange(`xrange') yrange(`yrange') ///
            sharey(`shareyf') firstpanel(`fp') yaxisline(1) ///
            legcols(`=cond(`legcols'>0,`legcols',4)') ///
            xtitle(`"`xtitle'"') ytitle(`"`ytitle'"') ///
            paneltitle(`"`t'"') anchorif(`"& `panel'==`t' `anchorif'"') ///
            name(g_`t') nodraw(nodraw) ///
            extraplot(`"`anc'"')

        local names `names' g_`t'
        local first = 0
    }

    local rows = 1
    if `cols'>0 {
        local np : word count `plevs'
        local rows = ceil(`np'/`cols')
    }

    local nt
    if `"`note'"'!="" local nt note("`note'", size(vsmall))
    local ttl
    if `"`title'"'!="" local ttl title("`title'", size(medium))

    grc1leg2 `names', rows(`rows') legendfrom(g_`lasttime') position(6) ///
        `ttl' `nt' imargin(small) graphregion(color(white)) name(`name', replace)
end
