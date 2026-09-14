*=============================================================================*
* Manuscript items: Tables 1 and 2.
* Purpose: insert estimates into submitted table layouts and notes.
* Inputs: output/source_data/table_estimates.dta and
*         scripts/mobility_table.tex, scripts/research_table.tex.
* Outputs: output/tables/mobility_second_specifications.tex and
*          output/tables/research_second_specifications.tex.
*=============================================================================*

version 19
use "output/source_data/table_estimates.dta", clear
*=============================================================================*
* Tables 1 and 2: Export submitted layouts
*=============================================================================*
* table 1 = mobility; table 2 = scientific outcomes.
foreach table in 1 2 {
    local stem mobility
    local outcomes d_pubs_dest_post mob_linkedin_post d_pubs_in_dest_aff_post_5 d_pubs_outside_both_5
    if `table' == 2 {
        local stem research
        local outcomes main_post main_jif_post fwci_post coauths_count_post
    }
    tempname input output
    file open `input' using "scripts/`stem'_table.tex", read text
    file open `output' using "output/tables/`stem'_second_specifications.tex", write text replace
    file read `input' line
    while r(eof) == 0 {
        forvalues col = 1/4 {
            local outcome : word `col' of `outcomes'
            foreach stat in tau se_cl p_rb Mean h_r N_l N_r N {
                quietly summarize `stat' if table == `table' & outcome == "`outcome'", meanonly
                assert r(N) == 1
                local fmt %9.3f
                if "`stat'" == "Mean" local fmt %9.2f
                if "`stat'" == "h_r" local fmt %9.1f
                if inlist("`stat'", "N_l", "N_r", "N") local fmt %12.0fc
                local value : display `fmt' r(mean)
                local value = strtrim("`value'")
                if "`stat'" == "se_cl" local value "(`value')"
                if "`stat'" == "p_rb" & r(mean) < .001 local value "$<0.001$"
                local line = subinstr(`"`macval(line)'"', "@@`stat'`col'@@", `"`value'"', .)
            }
        }
        file write `output' `"`macval(line)'"' _n
        file read `input' line
    }
    file close `input'
    file close `output'
}
