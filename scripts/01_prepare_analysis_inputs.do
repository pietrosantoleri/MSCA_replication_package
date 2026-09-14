*=============================================================================*
* Manuscript scope: prepare synthetic inputs for Figures 1-3 and Tables 1-2.
* Input: data/pseudo/msca_pseudo.dta.
* Outputs: data/pseudo/msca_analysis_pseudo.dta,
*          data/pseudo/citations_pseudo.dta,
*          documentation/analysis_variables.tsv.
*=============================================================================*

*=============================================================================*
* Prepare synthetic inputs with the original analysis variable names.
* All additions below are artificial and use a separate fixed random seed.
*=============================================================================*
version 19
use "data/pseudo/msca_pseudo.dta", clear
sort application_id
set seed 20260913

* Direct mappings: definitions and units follow the supplied generator.
clonevar prop_id                    = application_id
clonevar comp                       = comp_id
clonevar year_comp                  = year
clonevar margin2                    = centered_score
clonevar treat                      = treated
clonevar sex                        = female
clonevar prof                       = professor
clonevar nat_eu27                   = eu27_national
clonevar globalrank                 = host_rank
clonevar gdppc                      = host_gdppc
clonevar main_pre                   = pubs_pre
clonevar main_post                  = pubs5
clonevar main_jif_pre               = jif_pre
clonevar main_jif_post              = jif5
clonevar fwci_post                  = fwci5
clonevar coauths_count_pre          = coauthors_pre
clonevar coauths_count_post         = coauthors5
clonevar d_pubs_dest_pre            = mobility_pre
clonevar d_pubs_dest_post           = mobility5
clonevar mob_linkedin_post          = mobility5_adj
clonevar d_pubs_in_dest_aff_pre     = host_aff_pre
clonevar d_pubs_in_dest_aff_post_5  = host_aff5
clonevar d_pubs_outside_both_5      = third_country5

* Synthetic CV correction of pre-competition destination affiliation.
gen byte was_in_destination = runiform() < .07 if !missing(mobility_pre)
gen byte mob_linkedin_pre = d_pubs_dest_pre
replace mob_linkedin_pre = 1 if d_pubs_dest_pre == 0 & was_in_destination == 1

* Synthetic pre-period third-country affiliation (absent from the template).
* This supplies the application-level input to Table 1, column 4.
* Its probability is smooth, contains no treatment term, and is not calibrated
* to confidential moments. The template's post-period indicator is retained.
gen byte d_pubs_outside_both_pre = runiform() < ///
    invlogit(-1.2 + .25*extra_eu + .15*ln(1+pubs_pre)) if !missing(pubs_pre)

* Assign public country codes to wholly artificial country categories.
* These codes allow the original EU28 membership loop to run unchanged.
local eu_codes "AT BE BG HR CY CZ DK EE FI FR DE EL HU IE IT"
local other_codes "US CA AU CN IN JP BR MX NZ ZA KR SG CL AR CH"
gen str2 researchercountryorigin = ""
gen str2 organisationnutscountry = ""
forvalues j = 1/15 {
    local eu : word `j' of `eu_codes'
    local other : word `j' of `other_codes'
    replace researchercountryorigin = "`eu'" if origin_ctry == `j'
    replace researchercountryorigin = "`other'" if origin_ctry == `j'+15
    replace organisationnutscountry = "`eu'" if host_ctry == `j'
    replace organisationnutscountry = "`other'" if host_ctry == `j'+15
}
assert researchercountryorigin != organisationnutscountry
assert extra_eu == (origin_eu != host_eu)

* Prepare synthetic citations for merging and p99 winsorization.
* citations_pre supplies the pre-treatment control;
* post outcomes use cert_cites5/10.
preserve
    keep prop_id citations_pre cert_cites5 cert_cites10
    rename citations_pre main_citrec_pre
    rename cert_cites5 main_citrec_post
    rename cert_cites10 main_citrec_post_10
    isid prop_id
    assert main_citrec_post_10 >= main_citrec_post if !missing(main_citrec_post_10,main_citrec_post)
    save "data/pseudo/citations_pseudo.dta", replace
restore

* Retain only variables used by the main-text analyses.
keep prop_id comp year_comp margin2 treat sex age prof nat_eu27 globalrank gdppc ///
    main_pre main_post main_jif_pre main_jif_post fwci_pre fwci_post ///
    coauths_count_pre coauths_count_post d_pubs_dest_pre d_pubs_dest_post ///
    mob_linkedin_pre mob_linkedin_post d_pubs_in_dest_aff_pre ///
    d_pubs_in_dest_aff_post_5 d_pubs_outside_both_pre d_pubs_outside_both_5 ///
    researchercountryorigin organisationnutscountry
label data "SYNTHETIC MSCA main-text analysis input; not observed applicants"
label var sex "Female"
label var age "Age"
label var prof "Professor"
label var nat_eu27 "EU27 national"
label var globalrank "Host Scimago Ranking"
label var gdppc "Host country GDP per capita"
label var d_pubs_dest_pre "Intended-country affiliation (pre)"
label var main_pre "Pubs (pre)"
label var main_jif_pre "Average JIF (pre)"
isid prop_id
assert _N == 41024
count if !missing(main_post)
assert r(N) == 40985
assert inlist(treat,0,1)
assert !missing(margin2,comp)
sort prop_id
compress
save "data/pseudo/msca_analysis_pseudo.dta", replace

* Machine-readable data dictionary, generated without reading real microdata.
tempname dict
file open `dict' using "documentation/analysis_variables.tsv", write text replace
file write `dict' "variable" _tab "storage_type" _tab "label" _n
foreach var of varlist _all {
    local type : type `var'
    local label : variable label `var'
    file write `dict' "`var'" _tab "`type'" _tab "`label'" _n
}
file close `dict'
