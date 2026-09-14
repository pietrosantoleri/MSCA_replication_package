*=============================================================================*
* Manuscript item: Table 1, columns 1-4.
* Purpose: five-year mobility effects.
* Input: data/pseudo/msca_analysis_pseudo.dta.
* Output: output/source_data/table_estimates.dta (Table 1 rows).
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

* Store the estimates displayed in the submitted table.
tempname results
postfile `results' byte table str32 outcome double (tau tau_bc se_cl se_rb p_rb Mean h_l h_r N N_l N_r) ///
    using "output/source_data/table_estimates.dta", replace



* Table 1, column 1: Intended country
* Table 1, column 2: Intended country (CV-adjusted)
*=============================================================================*
foreach var in d_pubs_dest mob_linkedin {
    eststo est`var'2: xi: rdrobust `var'_post `x', ///
        fuzzy(treat) vce(cluster comp) covs(`var'_pre i.comp)
    add_estimates
    post `results' (1) ("`var'_post") ///
        (e(tau_cl)) (e(tau_bc)) (e(se_tau_cl)) (e(se_tau_rb)) ///
        (e(pv_rb)) (e(Mean)) (e(h_l)) (e(h_r)) (e(N)) ///
        (e(N_h_l)) (e(N_h_r))
}

* Table 1, column 3: Intended host institution
*=============================================================================*
local var d_pubs_in_dest_aff
eststo est`var'2: xi: rdrobust `var'_post_5 `x', ///
    fuzzy(treat) vce(cluster comp) covs(`var'_pre i.comp)
add_estimates
post `results' (1) ("`var'_post_5") ///
        (e(tau_cl)) (e(tau_bc)) (e(se_tau_cl)) (e(se_tau_rb)) ///
        (e(pv_rb)) (e(Mean)) (e(h_l)) (e(h_r)) (e(N)) ///
        (e(N_h_l)) (e(N_h_r))

* Table 1, column 4: Third countries
*=============================================================================*
eststo estd_pubs_outside_both2: xi: rdrobust d_pubs_outside_both_5 `x', ///
    fuzzy(treat) vce(cluster comp) covs(d_pubs_outside_both_pre i.comp)
add_estimates
post `results' (1) ("d_pubs_outside_both_5") ///
        (e(tau_cl)) (e(tau_bc)) (e(se_tau_cl)) (e(se_tau_rb)) ///
        (e(pv_rb)) (e(Mean)) (e(h_l)) (e(h_r)) (e(N)) ///
        (e(N_h_l)) (e(N_h_r))

* Close the estimate file; script 06 applies the submitted table layout.
postclose `results'
