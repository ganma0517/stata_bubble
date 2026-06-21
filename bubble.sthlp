{smcl}
{* *! version 1.0  21jun2026}{...}
{vieweralsosee "twoway scatter" "help twoway scatter"}{...}
{vieweralsosee "twoway qfit" "help twoway qfit"}{...}
{viewerjumpto "Syntax" "bubble##syntax"}{...}
{viewerjumpto "Description" "bubble##description"}{...}
{viewerjumpto "Options" "bubble##options"}{...}
{viewerjumpto "Examples" "bubble##examples"}{...}
{viewerjumpto "Author" "bubble##author"}{...}
{title:Title}

{phang}
{bf:bubble} {hline 2} Weighted bubble / scatter plot in the IMF "Work and wealth" style


{marker syntax}{...}
{title:Syntax}

{p 8 17 2}
{cmd:bubble}
{it:yvar} {it:xvar}
{ifin}
{weight}
[{cmd:,} {it:options}]

{p 4 6 2}
{cmd:aweight}s are allowed and set the bubble AREA (e.g. {cmd:[aw=population]}).{p_end}

{synoptset 26 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Size, grouping & colour}
{synopt:{opth by(varname)}}colour bubbles by this group and add a legend; a string variable is auto-encoded{p_end}
{synopt:{opt pal:ette(string)}}any {helpb colorpalette} name for the group colours; default {cmd:tableau}{p_end}
{synopt:{opt op:acity(#)}}bubble fill opacity 0-100; default {cmd:50} (lower = softer overlap){p_end}
{synopt:{opt bub:ble(#)}}overall bubble-size multiplier; default {cmd:1.3}{p_end}

{syntab:Point labels}
{synopt:{opth mlabel(varname)}}text label variable{p_end}
{synopt:{opth labelif(varname)}}only label points where this 0/1 indicator equals 1{p_end}

{syntab:Faceting / cross-period}
{synopt:{opth panel(varname)}}draw one bubble panel per level and combine them (small multiples){p_end}
{synopt:{opt sharey}}show the Y axis (line, ticks, title) only on the first panel{p_end}
{synopt:{opt labelp:anel(string)}}which panel is labelled: {cmd:first}, {cmd:last} or {cmd:all}; default {cmd:last}{p_end}
{synopt:{opt cols(#)}}number of columns when faceting; default one row{p_end}

{syntab:Axes}
{synopt:{opt xlog}}log-scale the x axis{p_end}
{synopt:{opt ylog}}log-scale the y axis{p_end}
{synopt:{opt xlab:els(numlist)}}custom x tick positions in data units, e.g. {cmd:2 5 10 20 50 100}{p_end}
{synopt:{opt ylab:els(numlist)}}custom y tick positions{p_end}
{synopt:{opt xrange(# #)} {opt yrange(# #)}}fixed axis ranges (shared across panels){p_end}

{syntab:Styling}
{synopt:{opt sch:eme(string)}}{helpb schemepack} scheme; default {cmd:white_tableau}{p_end}
{synopt:{opt gridc:olor(string)}}X & Y gridline colour; default {cmd:gs9} (lower gs = stronger){p_end}
{synopt:{opt tr:end(string)}}trend line: {cmd:qfit}, {cmd:lfit} or {cmd:none}; default {cmd:none}{p_end}
{synopt:{opt legc:ols(#)}}legend columns; default 2 (or 4 in panel mode){p_end}

{syntab:Titles & output}
{synopt:{opt title(string)} {opt sub:title(string)}}overall title / subtitle{p_end}
{synopt:{opt xtit:le(string)} {opt ytit:le(string)} {opt note(string)}}axis titles and a footnote{p_end}
{synopt:{opt saving(filename)} {opt name(string)} {opt nodraw}}standard graph output options{p_end}
{synopt:{opt export(filename)}}export the finished graph (PNG etc.) at high resolution{p_end}
{synoptline}


{marker description}{...}
{title:Description}

{pstd}
{cmd:bubble} draws a weighted bubble scatter in the editorial style of the IMF
{it:Finance & Development} "Work and wealth" chart: each observation is a bubble
whose {bf:area} is proportional to an {cmd:aweight} (population, GDP, sales, ...),
coloured by a categorical {opt by()} group with a clean legend. It supports log
axes with custom ticks, a dashed quadratic or linear {opt trend()} line, and
labelling only a chosen subset of points via {opt mlabel()} + {opt labelif()}.

{pstd}
With {opt panel()} it produces {bf:small multiples} — one bubble panel per period
combined into a single figure with one shared legend — for watching entities move
over time. Across panels the axes are fixed identical and an invisible anchor
point carrying the global-maximum size is added to each panel, so {cmd:[aw=]}
scales bubble area the same way in every panel and sizes are genuinely comparable
between periods.

{pstd}
{cmd:bubble} builds on the community packages {helpb schemepack}, {helpb grstyle},
{helpb colorpalette} ({cmd:palettes}/{cmd:colrspace}) and, for panel mode,
{cmd:grc1leg2}; it installs any that are missing from SSC on first use.


{marker options}{...}
{title:Options}

{dlgtab:Size, grouping & colour}

{phang}
{cmd:aweight} — supplying {cmd:[aw=}{it:sizevar}{cmd:]} makes each bubble's AREA
proportional to {it:sizevar} (the perceptually correct mapping). Without a weight,
markers are drawn at a fixed size.

{phang}
{opth by(varname)} colours bubbles by group and adds a legend. A string variable
is encoded automatically so the legend shows its text values.

{phang}
{opt opacity(#)} sets the bubble fill transparency. Lower values give a softer
gradient where bubbles overlap (try 30-45 for dense data, 60-70 for sparse).

{dlgtab:Point labels}

{phang}
{opth mlabel(varname)} prints a text label next to bubbles. By default every
point is labelled; combine with {opth labelif(varname)} to label only the points
where the indicator is 1 (e.g. the largest or most notable entities).

{dlgtab:Faceting / cross-period}

{phang}
{opth panel(varname)} draws one panel per level of the variable (e.g. {cmd:year})
and combines them with one shared legend. {opt sharey} keeps the Y axis on the
first panel only; {opt labelpanel()} chooses which panel carries the text labels;
{opt yrange()} / {opt ylabels()} should be set so the fixed axes match across
panels.


{marker examples}{...}
{title:Examples}

{pstd}Load the bundled synthetic demo:{p_end}
{phang2}{cmd:. use bubble_demo.dta, clear}{p_end}

{pstd}Minimal bubble chart — size by population, colour by region, log x-axis:{p_end}
{phang2}{cmd:. bubble hours gdp [aw=pop], by(region) xlog}{p_end}

{pstd}Full IMF-style chart with custom ticks, selective labels and a trend line:{p_end}
{phang2}{cmd:. bubble hours gdp [aw=pop], by(region) mlabel(country) labelif(labelme) xlog xlabels(2 5 10 20 50 100 180) trend(qfit) title("Work and wealth")}{p_end}

{pstd}Cross-year small multiples (one panel per year):{p_end}
{phang2}{cmd:. use bubble_panel_demo.dta, clear}{p_end}
{phang2}{cmd:. bubble hours gdp [aw=pop], by(region) panel(year) sharey mlabel(country) labelif(labelme) xlog xlabels(2 5 10 20 50 100 180) ylabels(15(5)40) yrange(15 40) trend(qfit) legcols(4)}{p_end}


{marker author}{...}
{title:Author}

{pstd}
Wen-Cheng Lin, Institute of Sociology, Academia Sinica.{break}
Source and issues: {browse "https://github.com/ganma0517/stata_bubble"}

{pstd}
The bundled datasets are illustrative synthetic data, not real statistics and not
copied from any IMF/F&D publication; only the chart type and theme are shared.
