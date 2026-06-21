*------------------------------------------------------------------*
* bubble_example.do — single weighted bubble chart (IMF "F&D" style)
*
* Bundled demo data are ILLUSTRATIVE SYNTHETIC values (not real statistics):
* GDP per adult vs weekly hours for ~28 countries, bubbles sized by population
* and coloured by world region.
*------------------------------------------------------------------*

* load the bundled demo (or use your own long dataset, one row per entity)
use "https://raw.githubusercontent.com/ganma0517/stata_bubble/main/bubble_demo.dta", clear
* local copy:  use bubble_demo.dta, clear

* minimal call: bubbles sized by pop, coloured by region, log x-axis
bubble hours gdp [aw=pop], by(region) xlog

* full IMF-style chart: custom log ticks, selective labels, quadratic trend
bubble hours gdp [aw=pop], by(region) mlabel(country) labelif(labelme)  ///
    xlog xlabels(2 5 10 20 50 100 180) trend(qfit)                      ///
    opacity(50)                                                         ///
    title("Work and wealth")                                           ///
    subtitle("Income explains only a small fraction of working-hours variation") ///
    xtitle("GDP per adult (\$000s, synthetic)") ytitle("Weekly hours worked") ///
    note("Illustrative synthetic data. Bubble area proportional to population.")
