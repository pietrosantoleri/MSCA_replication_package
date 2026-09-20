*=============================================================================*
* Manuscript item: Table 2, columns 1-4.
* Purpose: five-year scientific effects.
* Inputs: data/pseudo/msca_analysis_pseudo.dta and
*         output/source_data/table_estimates.dta (from script 03).
* Outputs: output/source_data/table_estimates.dta and .csv (both tables).
* Table layout is exported by script 06.
*=============================================================================*

version 19
use "data/pseudo/msca_analysis_pseudo.dta", clear
local x margin2
est clear

capture program drop add_estimates
program define add_estimates
    matrix s = e(pv_rb)
    mat colnames s = "RD Estimate"
    estadd matrix s
    local h = `e(h_l)'
    quietly summarize `e(depvar)' if e(sample) & ///
        inrange(margin2, -`h', `h') & treat == 0
    estadd scalar Mean = r(mean)
end

* Store the estimates displayed in the manuscript table.
tempname results
tempfile research_estimates
postfile `results' byte table str32 outcome double (tau tau_bc se_cl se_rb p_rb Mean h_l h_r N N_l N_r) ///
    using `research_estimates', replace



* Table 2, column 1: Publications
* Table 2, column 2: Average JIF
* Table 2, column 3: FWCI
* Table 2, column 4: Coauthors
*=============================================================================*
foreach var in main main_jif fwci coauths_count {
    eststo est`var'2: xi: rdrobust `var'_post `x', ///
        fuzzy(treat) vce(cluster comp) covs(`var'_pre i.comp)
    add_estimates
    post `results' (2) ("`var'_post") ///
        (e(tau_cl)) (e(tau_bc)) (e(se_tau_cl)) (e(se_tau_rb)) ///
        (e(pv_rb)) (e(Mean)) (e(h_l)) (e(h_r)) (e(N)) ///
        (e(N_h_l)) (e(N_h_r))
}

* Close the estimate file; script 06 applies the manuscript table layout.
postclose `results'

use "output/source_data/table_estimates.dta", clear
keep if table == 1
append using `research_estimates'
sort table outcome
assert _N == 8
isid table outcome
assert !missing(tau, tau_bc, se_cl, se_rb, p_rb, Mean, h_l, h_r)
assert N_l > 0 & N_r > 0 & N_l + N_r <= N
save "output/source_data/table_estimates.dta", replace
export delimited using "output/source_data/table_estimates.csv", replace
