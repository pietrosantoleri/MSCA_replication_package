*=============================================================================*
* Manuscript scope: prepare synthetic inputs for Figures 1-3 and Tables 1-2.
* Input: data/pseudo/msca_pseudo.dta.
* Outputs: data/pseudo/msca_analysis_pseudo.dta,
*          data/pseudo/citations_pseudo.dta,
*          documentation/analysis_variables.tsv.
*=============================================================================*

*=============================================================================*
* Prepare synthetic inputs with the analysis variable names.
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

* Synthetic pre-period third-country affiliation.
* This supplies the application-level input to Table 1, column 4.
* Its probability is smooth, contains no treatment term, and is not calibrated
* to restricted-data moments. The post-period indicator is retained.
gen byte d_pubs_outside_both_pre = runiform() < ///
    invlogit(-1.2 + .25*extra_eu + .15*ln(1+pubs_pre)) if !missing(pubs_pre)

* Assign public country codes to artificial country categories.
* These codes support the EU28 subgroup definitions.
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
    label data "SYNTHETIC MSCA citation input; not observed applicants"
    label variable prop_id             "Artificial application identifier"
    label variable main_citrec_pre     "Artificial citations to pre-existing work before competition"
    label variable main_citrec_post    "Artificial citations to pre-existing work within 5 years"
    label variable main_citrec_post_10 "Artificial citations to pre-existing work within 10 years"
    order prop_id main_citrec_pre main_citrec_post main_citrec_post_10
    foreach var of varlist _all {
        local varlabel : variable label `var'
        if `"`varlabel'"' == "" {
            display as error "Variable `var' has no label."
            exit 459
        }
    }
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
label variable prop_id                    "Artificial application identifier"
label variable comp                       "Artificial competition identifier"
label variable year_comp                  "Artificial application/call year"
label variable margin2                    "Artificial centered evaluation score"
label variable treat                      "Artificial fellowship receipt"
label variable sex                        "Artificial female indicator"
label variable age                        "Artificial age at application"
label variable prof                       "Artificial professor indicator"
label variable nat_eu27                   "Artificial EU27 nationality indicator"
label variable researchercountryorigin    "Artificial researcher origin country"
label variable organisationnutscountry    "Artificial proposed-host country"
label variable globalrank                 "Artificial host Scimago ranking"
label variable gdppc                      "Artificial host-country GDP per capita"
label variable d_pubs_dest_pre            "Artificial intended-country affiliation before competition"
label variable d_pubs_dest_post           "Artificial intended-country affiliation within 5 years"
label variable mob_linkedin_pre           "Artificial CV-adjusted affiliation before competition"
label variable mob_linkedin_post          "Artificial CV-adjusted affiliation within 5 years"
label variable d_pubs_in_dest_aff_pre     "Artificial intended-host affiliation before competition"
label variable d_pubs_in_dest_aff_post_5  "Artificial intended-host affiliation within 5 years"
label variable d_pubs_outside_both_pre    "Artificial other-country affiliation before competition"
label variable d_pubs_outside_both_5      "Artificial other-country affiliation within 5 years"
label variable main_pre                   "Artificial publication count before competition"
label variable main_post                  "Artificial publication count within 5 years"
label variable main_jif_pre               "Artificial average JIF before competition"
label variable main_jif_post              "Artificial average JIF within 5 years"
label variable fwci_pre                   "Artificial FWCI before competition"
label variable fwci_post                  "Artificial FWCI within 5 years"
label variable coauths_count_pre          "Artificial coauthor count before competition"
label variable coauths_count_post         "Artificial coauthor count within 5 years"

* Organize the final analysis file by design, context, and paired outcomes.
order prop_id comp year_comp margin2 treat ///
    sex age prof nat_eu27 ///
    researchercountryorigin organisationnutscountry globalrank gdppc ///
    d_pubs_dest_pre d_pubs_dest_post mob_linkedin_pre mob_linkedin_post ///
    d_pubs_in_dest_aff_pre d_pubs_in_dest_aff_post_5 ///
    d_pubs_outside_both_pre d_pubs_outside_both_5 ///
    main_pre main_post main_jif_pre main_jif_post fwci_pre fwci_post ///
    coauths_count_pre coauths_count_post
foreach var of varlist _all {
    local varlabel : variable label `var'
    if `"`varlabel'"' == "" {
        display as error "Variable `var' has no label."
        exit 459
    }
}
isid prop_id
assert _N == 41024
count if !missing(main_post)
assert r(N) == 40985
assert inlist(treat,0,1)
assert !missing(margin2,comp)
sort prop_id
compress
save "data/pseudo/msca_analysis_pseudo.dta", replace

* Export a machine-readable data dictionary.
tempname dict
file open `dict' using "documentation/analysis_variables.tsv", write text replace
file write `dict' "variable" _tab "storage_type" _tab "label" _n
foreach var of varlist _all {
    local type : type `var'
    local label : variable label `var'
    file write `dict' "`var'" _tab "`type'" _tab "`label'" _n
}
file close `dict'
