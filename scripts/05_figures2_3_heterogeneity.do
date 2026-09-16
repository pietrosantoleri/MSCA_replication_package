*=============================================================================*
* Manuscript items: Figure 2, panels a-c; Figure 3, four unlettered plots.
* Purpose: outcome heterogeneity and certification effects.
* Inputs: data/pseudo/msca_analysis_pseudo.dta and
*         data/pseudo/citations_pseudo.dta.
* Outputs: output/figures/heterogeneity_combined and
*          certification_heterogeneity (PDF);
*          output/source_data/figure_estimates.dta and .csv.
*=============================================================================*

version 19

*=============================================================================*
* 1. Estimation and recording routines
*=============================================================================*
capture program drop revision_fit
program define revision_fit, eclass
    syntax varname [if], COVS(string)
    marksample touse
    quietly xi: rdrobust `varlist' margin2 if `touse', ///
        fuzzy(treat) vce(cluster comp) covs(`covs') level(90)
    local hl = e(h_l)
    local hr = e(h_r)
    quietly summarize `varlist' if e(sample) & `touse' & treat == 0 ///
        & inrange(margin2, -`hl', `hr')
    ereturn scalar Mean = r(mean)
end

capture program drop revision_record
program define revision_record
    args handle outcome scale split cell horizon spec
    post `handle' ("`outcome'") ("`scale'") ("`split'") (`cell') (`horizon') (`spec') ///
        (e(tau_cl)) (e(tau_bc)) (e(se_tau_cl)) (e(se_tau_rb)) (e(pv_rb)) ///
        (e(ci_l_rb)) (e(ci_r_rb)) (e(Mean)) (e(N)) (e(N_h_l)) (e(N_h_r)) ///
        (e(h_l)) (e(h_r)) (e(b_l)) (e(b_r))
end


*=========================================================================*
* 2. Main analysis input and original subgroup definitions
*=========================================================================*

use "data/pseudo/msca_analysis_pseudo.dta", clear
isid prop_id
capture drop rev_quality rev_origin rev_host rev_geography
gen byte rev_quality = globalrank <= 50 if !missing(globalrank)
gen byte rev_origin = 0 if !missing(researchercountryorigin)
gen byte rev_host = 0 if !missing(organisationnutscountry)
local eu28 "AT BE BG HR CY CZ DK EE FI FR DE EL HU IE IT LV LT LU MT NL PL PT RO SK SI ES SE UK"
foreach country of local eu28 {
    replace rev_origin = 1 if researchercountryorigin == "`country'"
    replace rev_host = 1 if organisationnutscountry == "`country'"
}
* Keep the inherited grouping used by the manuscript estimates: zero includes
* both-EU28 AND both-non-EU28. The revised figures display this group as Intra-EU.
gen byte rev_geography = rev_origin != rev_host if !missing(rev_origin, rev_host)
tabulate rev_origin rev_host, missing

tempname results
postfile `results' str20 outcome str8 scale str16 split byte cell horizon spec ///
    double (tau tau_bc se_cl se_rb p_rb ci_l_rb ci_r_rb Mean N N_l N_r h_l h_r b_l b_r) ///
    using "output/source_data/figure_estimates.dta", replace every(1)

*=============================================================================*
* Figure 2, panels a-c: Estimate outcome heterogeneity
*=============================================================================*
* geography = panel a: Direction of mobility.
* quality   = panel b: Host-institution ranking.
* joint     = panel c: Direction of mobility and host-institution ranking.
* Each split estimates publications, Average JIF, mobility and coauthors.
foreach split in geography quality joint {
    local cells 2
    if "`split'" == "joint" local cells 4
    forvalues cell = 1/`cells' {
        local group = `cell' - 1
        if "`split'" == "geography" local condition "rev_geography == `group'"
        if "`split'" == "quality" local condition "rev_quality == 1 - `group'"
        if "`split'" == "joint" {
            local quality = 1 - mod(`cell' - 1, 2)
            local subgroup = floor((`cell' - 1) / 2)
            if "`split'" == "joint" local condition "rev_quality == `quality' & rev_geography == `subgroup'"
        }
        foreach stem in main main_jif d_pubs_dest coauths_count {
            display as text "MAIN: `stem', `split', cell `cell'"
            revision_fit `stem'_post if `condition', covs(`stem'_pre i.comp)
            revision_record `results' `stem' level `split' `cell' 5 2
        }
    }
}

*=========================================================================*
* Figure 3: Estimate certification effects
*=========================================================================*

* Original citation merge and full-sample p99 winsorization.
merge 1:1 prop_id using "data/pseudo/citations_pseudo.dta", ///
    keep(master match) keepusing(main_citrec_pre main_citrec_post main_citrec_post_10) gen(merge_cert)
assert merge_cert == 3
foreach window in pre post post_10 {
    quietly summarize main_citrec_`window', detail
    replace main_citrec_`window' = r(p99) ///
        if main_citrec_`window' > r(p99) & !missing(main_citrec_`window')
}
* Figure 3 plots, left to right:
* average: Average effects at five and ten years.
* geography: Direction of mobility; quality: Host quality; joint: Quality by direction of mobility.
foreach horizon in 5 10 {
    local window post
    if `horizon' == 10 local window post_10
    display as text "CERT AVERAGE: level, `horizon' years, spec 2"
    revision_fit main_citrec_`window', covs(main_citrec_pre i.comp)
    revision_record `results' main_citrec level average 1 `horizon' 2
    if `horizon' == 5 {
        foreach split in geography quality joint {
            local cells 2
            if "`split'" == "joint" local cells 4
            forvalues cell = 1/`cells' {
                local group = `cell' - 1
                if "`split'" == "geography" local condition "rev_geography == `group'"
                if "`split'" == "quality" local condition "rev_quality == 1 - `group'"
                if "`split'" == "joint" {
                    local quality = 1 - mod(`cell' - 1, 2)
                    local geography = floor((`cell' - 1) / 2)
                    local condition "rev_quality == `quality' & rev_geography == `geography'"
                }
                display as text "CERT HETEROGENEITY: level, 5 years, `split', cell `cell'"
                revision_fit main_citrec_post if `condition', covs(main_citrec_pre i.comp)
                revision_record `results' main_citrec level `split' `cell' 5 2
            }
        }
    }
}
postclose `results'

*=============================================================================*
* 4. Full-precision estimates and inference checks
*=============================================================================*

use "output/source_data/figure_estimates.dta", clear
assert _N == 42
isid outcome scale split cell horizon spec
assert !missing(tau, tau_bc, se_cl, se_rb, p_rb, ci_l_rb, ci_r_rb)
assert abs(p_rb - 2 * normal(-abs(tau_bc / se_rb))) < 1e-10
assert abs(ci_l_rb - (tau_bc - invnormal(.95) * se_rb)) < 1e-8
assert abs(ci_r_rb - (tau_bc + invnormal(.95) * se_rb)) < 1e-8
assert N_l > 0 & N_r > 0 & N_l + N_r <= N
export delimited using "output/source_data/figure_estimates.csv", replace

*=============================================================================*
* Figure 2, panels a-c: Plot outcome heterogeneity
*=============================================================================*

* Shared coefficient-plot styling.
local plot_design `"vertical yline(0) aspectratio(.95) msize(3.42009828730828125) ciopts(lwidth(1.083) lcolor(*.4)) plotregion(lstyle(none)) addplot((scatter @b @at, msymbol(i) yaxis(1 2)) (scatteri 0 1, msymbol(i) yaxis(1 2))) yscale(alt axis(1)) yscale(alt axis(2) line lcolor(black) lwidth(thin)) ylabel(none, axis(2)) ytitle("", axis(2)) scale(1.05)"'

foreach split in geography quality joint {
    local row1 "Top-ranked"
    local row2 "Other ranked"
    if "`split'" == "geography" {
        local row1 "Intra-EU"
        local row2 "Extra-EU"
    }
    local plots
    foreach stem in main main_jif d_pubs_dest coauths_count {
        local title "Publications"
        if "`stem'" == "main_jif" local title "Average JIF"
        if "`stem'" == "d_pubs_dest" local title "Mobility"
        if "`stem'" == "coauths_count" local title "Co-authors"
        matrix B_`stem' = J(3, 2, .)
        matrix R_`stem' = J(3, 2, .)
        forvalues row = 1/2 {
            foreach stat in tau ci_l_rb ci_r_rb {
                local k = cond("`stat'" == "tau", 1, cond("`stat'" == "ci_l_rb", 2, 3))
                quietly summarize `stat' if outcome == "`stem'" & split == "`split'" & cell == `row'
                matrix B_`stem'[`k', `row'] = r(mean)
                if "`split'" == "joint" {
                    quietly summarize `stat' if outcome == "`stem'" & split == "`split'" & cell == `row' + 2
                    matrix R_`stem'[`k', `row'] = r(mean)
                }
            }
        }
        if "`split'" != "joint" {
            local plots `plots' matrix(B_`stem'[1,]), ci((B_`stem'[2,] B_`stem'[3,])) bylabel(`title') ||
        }
        else {
            local plots `plots' (matrix(B_`stem'[1,]), ci((B_`stem'[2,] B_`stem'[3,])) mcolor(stblue) ciopts(lcolor(stblue*.45) lwidth(1.083)) offset(.12)) (matrix(R_`stem'[1,]), ci((R_`stem'[2,] R_`stem'[3,])) mcolor(red) ciopts(lcolor(red*.45) lwidth(1.083)) offset(-.12)), bylabel(`title') ||
        }
    }
    local legend "legend(off)"
    if "`split'" == "joint" local legend `"legend(order(2 "Intra-EU" 4 "Extra-EU") position(6) rows(1) size(4.88573408754703125))"'
    * Figure 2 panel titles: a = geography, b = quality, c = joint.
    if inlist("`split'", "geography", "quality", "joint") {
        local panel "a  Direction of mobility"
        if "`split'" == "quality" local panel "b  Host-institution ranking"
        if "`split'" == "joint" local panel "c  Direction of mobility and host-institution ranking"
        * Reverse only Panel A's display order, keeping labels and estimates paired.
        local panel_order
        if "`split'" == "geography" local panel_order "xscale(reverse)"
        * Reserve identical legend space in all rows. Invisible addplot keys
        * keep Panels A/B blank while matching Panel C's two-entry legend.
        local panel_legend `"`legend'"'
        if "`split'" != "joint" local panel_legend `"legend(order(3 "Intra-EU" 4 "Extra-EU") color(white) position(6) rows(1) size(4.88573408754703125))"'
        coefplot `plots', `plot_design' ///
            byopts(yrescale rows(1) legend(position(6)) title("`panel'", size(5.862965331081796875) margin(b=2))) ///
            subtitle(, size(*1.6181654860546875)) ylabel(, axis(1) labsize(*1.15)) ///
            xlabel(1 "`row1'" 2 "`row2'", labsize(4.88573408754703125)) ///
            `panel_legend' `panel_order' xsize(12) ysize(3.5) name(panel_`split', replace)
    }
}

*=============================================================================*
* Figure 2: Combine and export panels a-c
*=============================================================================*
graph combine panel_geography panel_quality panel_joint, cols(1) altshrink ///
    xsize(12) ysize(10.5) imargin(0) graphregion(color(white))
graph export "output/figures/heterogeneity_combined.pdf", replace

*=============================================================================*
* Figure 3: Plot certification effects
*=============================================================================*

foreach split in average geography quality joint {
    * graph combine scales a single-box canvas differently from by().
    * Compensate so exported category/header/marker sizes match Figure 2.
    local cert_design : subinstr local plot_design "scale(1.05)" "scale(.96)"
    * Reserve the extra numeric-label width of the joint panel in all boxes.
    local labelgap 2.38
    if "`split'" == "joint" local labelgap 1
    preserve
    if "`split'" == "average" {
        keep if outcome == "main_citrec" & split == "average" & scale == "level" & spec == 2
    }
    else {
        keep if outcome == "main_citrec" & split == "`split'" & horizon == 5
    }
    * Scale each panel independently, retaining the zero reference.
    quietly summarize ci_l_rb
    local lo = min(r(min), 0)
    quietly summarize ci_r_rb
    local hi = max(r(max), 0)
    local step = 10^floor(log10((`hi' - `lo') / 3))
    local lo = floor(`lo' / `step') * `step'
    local hi = ceil(`hi' / `step') * `step'
    local mid = (`lo' + `hi') / 2
    local row1 "Higher quality"
    local row2 "Lower quality"
    local title "Host quality"
    local cert_order
    local legend `"legend(order(3 "Intra-EU" 4 "Extra-EU") color(white) rows(1) size(5.7562942993605) position(6))"'
    if "`split'" == "average" {
        local row1 "5 years"
        local row2 "10 years"
        local title "Average effects"
    }
    if "`split'" == "geography" {
        local row1 "Intra-EU"
        local row2 "Extra-EU"
        local title "Direction of mobility"
        local cert_order "xscale(reverse)"
    }
    if "`split'" == "joint" {
        local title "Quality by direction of mobility"
        local legend `"legend(order(2 "Intra-EU" 4 "Extra-EU") rows(1) size(5.7562942993605) position(6))"'
    }
    matrix B_cert = J(3, 2, .)
    matrix R_cert = J(3, 2, .)
    forvalues row = 1/2 {
        foreach stat in tau ci_l_rb ci_r_rb {
            local k = cond("`stat'" == "tau", 1, cond("`stat'" == "ci_l_rb", 2, 3))
            if "`split'" == "average" quietly summarize `stat' if horizon == 5 * `row'
            else quietly summarize `stat' if cell == `row'
            matrix B_cert[`k', `row'] = r(mean)
            if "`split'" == "joint" {
                quietly summarize `stat' if cell == `row' + 2
                matrix R_cert[`k', `row'] = r(mean)
            }
        }
    }
    local plots matrix(B_cert[1,]), ci((B_cert[2,] B_cert[3,])) bylabel(`title') ||
    if "`split'" == "joint" {
        local plots (matrix(B_cert[1,]), ci((B_cert[2,] B_cert[3,])) mcolor(stblue) ciopts(lcolor(stblue*.45) lwidth(1.083)) offset(.12)) (matrix(R_cert[1,]), ci((R_cert[2,] R_cert[3,])) mcolor(red) ciopts(lcolor(red*.45) lwidth(1.083)) offset(-.12)), bylabel(`title') ||
    }
    local cert_title_size "*1.6181654860546875"
    if "`split'" == "joint" local cert_title_size "*1.50"
    coefplot `plots', `cert_design' ///
        byopts(yrescale rows(1) legend(position(6))) ///
        subtitle("`title'", size(`cert_title_size') box bcolor(gs15) lcolor(gs15) bexpand) ///
        ylabel(`lo' `mid' `hi', axis(1) format(%9.0fc) labsize(*1.15) labgap(`labelgap')) ///
        xlabel(1 "`row1'" 2 "`row2'", labsize(4.88573408754703125)) ///
        `legend' `cert_order' xsize(3) ysize(3.5) name(cert_`split', replace)
    restore
}
*=============================================================================*
* Figure 3: Combine and export the four plots
*=============================================================================*
* Order: Average effects, Direction of mobility, Host quality, Quality by direction of mobility.
* Match Figure 2's box dimensions without scaling text, markers or CI lines.
graph combine cert_average cert_geography cert_quality cert_joint, cols(4) altshrink ///
    xsize(12) ysize(3.5) imargin(l=5.28 r=5.28 t=0 b=0) graphregion(color(white))
graph export "output/figures/certification_heterogeneity.pdf", replace
