*------------------------------------------------------------------*
* bubble_panel_example.do — cross-period small multiples
*
* One bubble panel per year, combined with a single shared legend, so you can
* watch entities drift across the plane over time. Axes are fixed identical
* across panels and an invisible anchor point keeps bubble sizes comparable
* between panels.
*
* Demo data: 16 countries x 3 years (2000/2010/2020), ILLUSTRATIVE SYNTHETIC.
*------------------------------------------------------------------*

use "https://raw.githubusercontent.com/ganma0517/stata_bubble/main/bubble_panel_demo.dta", clear
* local copy:  use bubble_panel_demo.dta, clear

* panel(year) makes the small multiples; sharey shows the Y axis on the first
* panel only; labelpanel(last) labels only the final period.
bubble hours gdp [aw=pop], by(region) panel(year) sharey                ///
    mlabel(country) labelif(labelme) labelpanel(last)                   ///
    xlog xlabels(2 5 10 20 50 100 180) ylabels(15(5)40) yrange(15 40)    ///
    trend(qfit) gridcolor(gs9) opacity(35) legcols(4)                   ///
    title("Work and wealth over time")                                 ///
    xtitle("GDP per adult (\$000s, synthetic)") ytitle("Weekly hours worked") ///
    note("Illustrative synthetic data. Bubble area proportional to population.")
