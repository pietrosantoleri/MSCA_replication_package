*=============================================================================*
* Manuscript item: Figure 1, panels a-c.
* Purpose: treatment compliance, grant probability and covariate balance.
* Input: data/pseudo/msca_analysis_pseudo.dta.
* Outputs: output/figures/figure1_compliance, figure1_probability,
*          figure1_balance (PDF).
*=============================================================================*

version 19
local out "output/figures"
use "data/pseudo/msca_analysis_pseudo.dta", clear
set scheme stcolor
sort comp
* Variable labels for the balance plots.
label var globalrank "Host Scimago Ranking"
replace gdppc = gdppc / 1000
label var gdppc "Host country GDP per capita (thousands)"
label var main_pre "Pubs (pre)"
label var d_pubs_dest_pre "Aff. in host country (pre)"
local score margin2
local cutoff 0
* Vendored rdplot builds e(eq_l)/e(eq_r) using the global cutoff.
global c 0
local balance_vars sex age prof nat_eu27 globalrank gdppc d_pubs_dest_pre main_pre main_jif_pre
count
summarize treat margin2 `balance_vars'

*=============================================================================*
* Figure 1, panel a: Treatment compliance
*=============================================================================*
set seed 3455  // Fixed competition-sampling seed.
preserve
bysort comp: keep if _n == 1  // One observation per competition.
sample 15, count
gen byte insample = 1  // Mark selected competitions.
keep comp insample
tempfile temp
save `temp'
restore
preserve
cap drop _merge 
merge m:1 comp using `temp'
keep if insample ==1
scatter treat margin2 if inrange(margin2, -10,10), ///
    jitter(24) jitterseed(123) xline(0) ///
    yscale(r(-0.75 1.50) lstyle(none)) ylabel(1 "Granted" 0 "Not Granted") ///
    ytitle("") xtitle("Centered score") xlabel(-10(5)10,format(%9.0fc)) ///
    legend(off) graphregion(margin(zero))
graph export "`out'/figure1_compliance.pdf", replace
restore


*=============================================================================*
* Figure 1, panel b: Probability of receiving the grant
*=============================================================================* 
binscatter treat margin2 if inrange(margin2,-10,10), ///
    rd(0) nq(100) line(none) ytitle("Probability of receiving treatment") ///
    xtitle("Centered score") mcolors(stblue) graphregion(margin(zero))
graph export "`out'/figure1_probability.pdf", replace

*=============================================================================*
* Figure 1, panel c: Covariate balance around the funding threshold
*=============================================================================*
foreach var of varlist `balance_vars'  {
    preserve
    drop if `var' == . 
    rdrobust `var' `score'
    local bandwidth = e(h_l)
    local fmtbndwdt : display %4.3f `bandwidth'
    display `fmtbndwdt'
    rdplot `var' `score' if -`fmtbndwdt' <= `score' & `score' <= `fmtbndwdt', ///
        h(`fmtbndwdt') p(1) hide genvars ci(95)
	
    * GDP is displayed in thousands; the running variable stays in score units.
    local plot_title `"`: variable label `var''"'

twoway ///
    (rarea   rdplot_ci_l rdplot_ci_r rdplot_mean_bin if rdplot_id<0, sort color(gs15)) ///
    (rarea   rdplot_ci_l rdplot_ci_r rdplot_mean_bin if rdplot_id>0, sort color(gs15)) ///
    (scatter rdplot_mean_y rdplot_mean_bin, sort msize(small) mcolor(stblue)) ///
    (function `e(eq_l)', range(-`fmtbndwdt' `cutoff') lcolor(black) lwidth(medthin) lpattern(solid)) ///
    (function `e(eq_r)', range(`cutoff' `fmtbndwdt') lcolor(black) lwidth(medthin) lpattern(solid)), ///
    xline(`cutoff', lcolor(black) lwidth(medthin)) ///
    xscale(range(-`fmtbndwdt' `fmtbndwdt')) ///
    xlabel(-`fmtbndwdt' `fmtbndwdt' 0 , format(%9.1fc)) ///
    legend(off) title(`plot_title', size(medsmall) color(gs0)) ///
    name(`var', replace) graphregion(margin(zero))
    restore
}


graph combine sex age prof ///
nat_eu27 globalrank gdppc  ///
d_pubs_dest_pre main_pre main_jif_pre, col(3) iscale(*.8)
graph export "`out'/figure1_balance.pdf", replace

