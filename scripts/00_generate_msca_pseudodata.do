*=============================================================================*
* Manuscript scope: synthetic inputs for Figures 1-3 and Tables 1-2.
* Input: none; all records are artificial random draws.
* Output: data/pseudo/msca_pseudo.dta.
*=============================================================================*

version 18.0
clear all
set more off
set linesize 255
set seed 20260911

capture mkdir "data"
capture mkdir "data/pseudo"
capture mkdir "logs"


capture log close pseudodata
log using "logs/generate_pseudodata.log", replace text name(pseudodata)


********************************************************************************
* 0. PUBLIC CALIBRATION TARGETS AND DGP PARAMETERS
********************************************************************************

* Dataset architecture
global N               41024
global NCOMP             236
global TARGET_MAIN      0.21
global TARGET_FUNDED    0.22
global TARGET_FS        0.25

* Selected descriptive targets
global TARGET_FEMALE    0.38
global TARGET_AGE      34.35
global TARGET_DOCTOR    0.84
global TARGET_REPEAT    0.20
global TARGET_PUBPRE   11.06
global TARGET_JIFPRE   20.04
global TARGET_COAPRE   27.26

* Main public effect targets (used as broad reference points, not exact goals)
global TARGET_MOB_MEAN  0.63
global TARGET_MOB_RD    0.327
global TARGET_HOST_MEAN 0.50
global TARGET_HOST_RD   0.405

global TARGET_PUB_RD    2.509
global TARGET_JIF_RD    4.637
global TARGET_FWCI_RD   0.921
global TARGET_COA_RD    3.040

* Treatment-take-up shape around cutoff.
* The intercepts are calibrated below while preserving an approximately 0.25
* probability jump at x = 0.
global FUND_SLOPE_L     0.45
global FUND_SLOPE_R     0.25

* Structural outcome parameters. These are intentionally rounded / approximate.
global TAU_MOB          0.33
global TAU_HOST         0.41
global TAU_PUB          2.00
global TAU_JIF          3.00
global TAU_FWCI         0.50
global TAU_COA         -0.60


********************************************************************************
* 1. GENERATE 236 COMPLETELY ARTIFICIAL COMPETITIONS
********************************************************************************

set obs $NCOMP

gen int comp_id = _n
label variable comp_id "Artificial competition identifier"

* Right-skewed competition weights; no real competition counts are used.
gen double _w = exp(rnormal(0, 0.90))
egen double _sumw = total(_w)

* Give every competition at least one applicant, then allocate the remainder
* proportionally to artificial weights.
gen double _raw_alloc = _w / _sumw * ($N - $NCOMP)
gen int n_app = 1 + floor(_raw_alloc)
gen double _frac = _raw_alloc - floor(_raw_alloc)

quietly summarize n_app, meanonly
local residual = $N - r(sum)

gsort -_frac
if `residual' > 0 {
    replace n_app = n_app + 1 in 1/`residual'
}
sort comp_id

quietly summarize n_app, meanonly
assert r(sum) == $N

* Competition year: FP7 years.
gen int year = 2007 + floor(7 * runiform())
label variable year "Artificial application/call year"

* Fellowship family.
* Labels are genuine public programme categories; assignments are synthetic.
gen double _u_action = runiform()
gen byte action = .
replace action = 1 if _u_action < 0.50
replace action = 2 if _u_action >= 0.50 & _u_action < 0.70
replace action = 3 if _u_action >= 0.70 & _u_action < 0.82
replace action = 4 if _u_action >= 0.82

label define action_lbl ///
    1 "IEF" ///
    2 "IIF" ///
    3 "IOF" ///
    4 "Reintegration"
label values action action_lbl
label variable action "Artificial fellowship family"

* Scientific panel. Approximate broad public composition only.
gen double _u_panel = runiform()
gen byte panel = .
replace panel = 1 if _u_panel < 0.32
replace panel = 2 if _u_panel >= 0.32 & _u_panel < 0.47
replace panel = 3 if _u_panel >= 0.47 & _u_panel < 0.59
replace panel = 4 if _u_panel >= 0.59 & _u_panel < 0.70
replace panel = 5 if _u_panel >= 0.70 & _u_panel < 0.80
replace panel = 6 if _u_panel >= 0.80 & _u_panel < 0.90
replace panel = 7 if _u_panel >= 0.90 & _u_panel < 0.96
replace panel = 8 if _u_panel >= 0.96

label define panel_lbl ///
    1 "LIF" ///
    2 "SOC" ///
    3 "PHY" ///
    4 "ENV" ///
    5 "ENG" ///
    6 "CHE" ///
    7 "MAT" ///
    8 "ECO"
label values panel panel_lbl
label variable panel "Artificial scientific panel"

* Artificial fraction initially offered funding.
* Competition-level variation is smooth and unrelated to applicant potential outcomes.
gen double main_share_c = invlogit(ln($TARGET_MAIN/(1-$TARGET_MAIN)) + rnormal(0,0.35))
replace main_share_c = max(0.08, min(0.40, main_share_c))

gen int main_slots = max(1, round(main_share_c * n_app))
replace main_slots = min(main_slots, n_app - 1) if n_app > 1

* Competition-level latent environment effect used later to induce realistic clustering.
gen double comp_re = rnormal(0, 0.12)


********************************************************************************
* 2. EXPAND TO 41,024 APPLICATIONS
********************************************************************************

expand n_app
bysort comp_id: gen int app_within_comp = _n

sort comp_id app_within_comp
gen long application_id = _n

label variable application_id "Artificial application identifier"
isid application_id
assert _N == $N

drop _w _sumw _raw_alloc _frac _u_action _u_panel


********************************************************************************
* 3. CREATE ARTIFICIAL REPEATED APPLICANTS
********************************************************************************

* Construct pairs so that exactly ~20% of application rows are later applications.
* No identifier corresponds to a real researcher.

gen double _pair_sort = runiform()
sort _pair_sort

local R = round($TARGET_REPEAT * $N)

gen long _pos = _n
gen long researcher_id = .

* First member of each repeated pair
replace researcher_id = _pos if _pos <= `R'

* Unique researchers in the middle
replace researcher_id = _pos if _pos > `R' & _pos <= ($N - `R')

* Second member of repeated pairs
replace researcher_id = _pos - ($N - `R') if _pos > ($N - `R')

drop _pair_sort _pos

sort researcher_id year application_id
by researcher_id: gen byte applied_before = (_n > 1)

label variable researcher_id "Artificial researcher identifier"
label variable applied_before "Artificial indicator: researcher appeared previously"

quietly summarize applied_before, meanonly
display as text "Repeated-application share = " %6.3f r(mean)


********************************************************************************
* 4. RESEARCHER-LEVEL LATENT FACTORS AND DEMOGRAPHICS
********************************************************************************

sort researcher_id year application_id

* Latent factors are generated once per artificial researcher.
by researcher_id: gen double ability = rnormal() if _n == 1
by researcher_id: replace ability = ability[1]

by researcher_id: gen double international_orientation = rnormal() if _n == 1
by researcher_id: replace international_orientation = international_orientation[1]

by researcher_id: gen double network_orientation = rnormal() if _n == 1
by researcher_id: replace network_orientation = network_orientation[1]

* Gender: approximately 38%.
by researcher_id: gen double _u_female = runiform() if _n == 1
by researcher_id: replace _u_female = _u_female[1]

gen byte female = (_u_female < invlogit(ln($TARGET_FEMALE/(1-$TARGET_FEMALE)) ///
                                        - 0.05*ability))
label variable female "Artificial female indicator"

* Nationality: generated at researcher level and held fixed across repeated applications.
by researcher_id: gen double _u_nat = runiform() if _n == 1
by researcher_id: replace _u_nat = _u_nat[1]

gen byte european_national = (_u_nat < invlogit(ln(0.66/0.34) + 0.05*ability))
label variable european_national "Artificial European nationality indicator"

by researcher_id: gen double _u_eu27 = runiform() if _n == 1
by researcher_id: replace _u_eu27 = _u_eu27[1]

gen byte eu27_national = european_national & (_u_eu27 < 0.92)
label variable eu27_national "Artificial EU27 nationality indicator"

* Age: base age is researcher-level; age increases across repeated applications.
bysort researcher_id: egen int first_year = min(year)

by researcher_id: gen double base_age = 33.80 + 0.25*ability + rnormal(0,4.4) if _n == 1
by researcher_id: replace base_age = base_age[1]

gen double age = base_age + (year - first_year)
replace age = max(24, min(60, age))
label variable age "Artificial age at application"

* Doctor / professor status.
gen byte doctor = (runiform() < invlogit(ln(0.84/0.16) + 0.12*ability + 0.03*(age-34)))
gen byte professor = (runiform() < invlogit(-3.00 + 0.20*ability + 0.07*(age-34)))

label variable doctor "Artificial doctorate indicator"
label variable professor "Artificial professor indicator"

drop _u_female _u_nat _u_eu27 base_age first_year


********************************************************************************
* 5. ARTIFICIAL MOBILITY TYPE, ORIGIN, DESTINATION AND HOST CHARACTERISTICS
********************************************************************************

* Direction is strongly associated with fellowship family, but all records are synthetic.
gen byte mobility_direction = .

* IEF: within Europe
replace mobility_direction = 1 if action == 1

* IIF: Third country -> Europe
replace mobility_direction = 3 if action == 2

* IOF: Europe -> Third country
replace mobility_direction = 2 if action == 3

* Reintegration: mixed direction
gen double _u_dir = runiform() if action == 4
replace mobility_direction = 1 if action == 4 & _u_dir < 0.55
replace mobility_direction = 2 if action == 4 & _u_dir >= 0.55 & _u_dir < 0.75
replace mobility_direction = 3 if action == 4 & _u_dir >= 0.75 & _u_dir < 0.95
replace mobility_direction = 4 if action == 4 & _u_dir >= 0.95

label define dir_lbl ///
    1 "Europe-Europe" ///
    2 "Europe-Third" ///
    3 "Third-Europe" ///
    4 "Third-Third"
label values mobility_direction dir_lbl

gen byte extra_eu = inlist(mobility_direction,2,3)
gen byte same_side = !extra_eu

gen byte origin_eu = inlist(mobility_direction,1,2)
gen byte host_eu   = inlist(mobility_direction,1,3)

label variable extra_eu "Artificial cross-European-boundary mobility"
label variable same_side "Artificial same-side mobility"

* Completely artificial country categories.
* IDs 1-15 denote synthetic European locations; 16-30 synthetic non-European.
gen int origin_ctry = cond(origin_eu, ceil(15*runiform()), 15 + ceil(15*runiform()))
gen int host_ctry   = cond(host_eu,   ceil(15*runiform()), 15 + ceil(15*runiform()))

* Avoid origin = destination when both are on the same side.
replace host_ctry = mod(host_ctry,15) + 1 ///
    if origin_eu == 1 & host_eu == 1 & host_ctry == origin_ctry

replace host_ctry = 16 + mod(host_ctry-15,15) ///
    if origin_eu == 0 & host_eu == 0 & host_ctry == origin_ctry

label variable origin_ctry "Artificial origin-country category"
label variable host_ctry   "Artificial host-country category"

* Residence indicators: kept separate from the artificial mobility-direction construct.
gen byte european_resident = (runiform() < invlogit(ln(0.65/0.35) + 0.70*(origin_eu-0.75)))
gen byte eu27_resident     = european_resident & (runiform() < 0.88)

* Host organization type: approximately 74% HEI, 22% research organization, 4% other.
gen double _u_hosttype = runiform()
gen byte host_type = .
replace host_type = 1 if _u_hosttype < 0.74
replace host_type = 2 if _u_hosttype >= 0.74 & _u_hosttype < 0.96
replace host_type = 3 if _u_hosttype >= 0.96

label define hosttype_lbl 1 "Higher education" 2 "Research organization" 3 "Other"
label values host_type hosttype_lbl

gen byte host_hei      = (host_type == 1)
gen byte host_research = (host_type == 2)
gen byte host_other    = (host_type == 3)

* Proposal duration calibrated to public action-level means.
gen double proposal_duration = .
replace proposal_duration = rnormal(23.3,2.5) if action == 1
replace proposal_duration = rnormal(24.1,3.0) if action == 2
replace proposal_duration = rnormal(33.6,3.5) if action == 3
replace proposal_duration = rnormal(43.5,3.5) if action == 4
replace proposal_duration = max(12, min(48, proposal_duration))
replace proposal_duration = round(proposal_duration,0.1)

* Latent top-host indicator. This is NOT derived from a real institution.
gen double _p_top = invlogit(-2.45 + 0.32*ability + 0.10*(host_type==1))
gen byte _top_host_true = (runiform() < _p_top)

* Artificial host ranking.
gen double host_rank = .
replace host_rank = 1 + floor(50*runiform()) if _top_host_true == 1
replace host_rank = 51 + rgamma(2,330)       if _top_host_true == 0
replace host_rank = min(host_rank,2000)

gen byte top_host = (host_rank <= 50)

* Synthetic host-country GDP per capita.
gen double host_gdppc = 30000 + 8500*host_eu + 3500*_top_host_true + rnormal(0,8500)
replace host_gdppc = max(5000,min(100000,host_gdppc))

* Distance: substantially higher for extra-European mobility.
gen double distance_km = .
replace distance_km = exp(ln(1350) - 0.5*0.55^2 + 0.55*rnormal()) ///
    if mobility_direction == 1
replace distance_km = exp(ln(6900) - 0.5*0.45^2 + 0.45*rnormal()) ///
    if inlist(mobility_direction,2,3)
replace distance_km = exp(ln(2500) - 0.5*0.55^2 + 0.55*rnormal()) ///
    if mobility_direction == 4
replace distance_km = min(distance_km,20000)

* Same nationality as host: action-specific public-style rates.
gen double _p_same_nat = .
replace _p_same_nat = 0.09 if action == 1
replace _p_same_nat = 0.10 if action == 2
replace _p_same_nat = 0.01 if action == 3
replace _p_same_nat = 0.63 if action == 4

gen byte same_nat_host = (runiform() < _p_same_nat)

drop _u_dir _u_hosttype _p_top _p_same_nat


********************************************************************************
* 6. GENERATE CORRELATED PRE-TREATMENT BIBLIOMETRIC CHARACTERISTICS
********************************************************************************

* Panel components.
gen double field_pub = 0
replace field_pub =  0.23 if panel == 1
replace field_pub = -0.24 if panel == 2
replace field_pub =  0.10 if panel == 3
replace field_pub =  0.08 if panel == 4
replace field_pub =  0.05 if panel == 5
replace field_pub =  0.03 if panel == 6
replace field_pub = -0.10 if panel == 7
replace field_pub = -0.18 if panel == 8

gen double field_jif = 0
replace field_jif =  0.18 if panel == 1
replace field_jif = -0.22 if panel == 2
replace field_jif =  0.08 if panel == 3
replace field_jif =  0.04 if panel == 4
replace field_jif = -0.02 if panel == 5
replace field_jif =  0.07 if panel == 6
replace field_jif = -0.12 if panel == 7
replace field_jif = -0.16 if panel == 8

gen double field_net = 0
replace field_net =  0.10 if inlist(panel,1,3,4)
replace field_net = -0.10 if inlist(panel,2,7,8)

* Pre-competition articles/conference papers.
gen double mu_pub_pre = exp(2.29 + 0.40*ability + field_pub + 0.012*(age-34))
gen double _lambda_pub_pre = mu_pub_pre * rgamma(2.5,1/2.5)
gen int pubs_pre = rpoisson(_lambda_pub_pre)

* Broader publication count.
gen int pubs_all_pre = pubs_pre + rpoisson(0.75 + 0.05*pubs_pre)

* Authorship positions.
gen int pubs_first_pre = rbinomial(pubs_pre,0.42)
gen int pubs_last_pre  = rbinomial(pubs_pre,0.16)

* Average journal impact measure.
gen double jif_pre = exp(2.78 + 0.28*ability + field_jif + rnormal(0,0.60))
replace jif_pre = min(jif_pre,150)
replace jif_pre = 0 if pubs_pre == 0

* Coauthor network.
gen double mu_coa_pre = exp(2.67 + 0.24*ln(1+pubs_pre) + ///
                            0.20*ability + 0.10*network_orientation + field_net)
gen double _lambda_coa_pre = mu_coa_pre * rgamma(2.0,1/2.0)
gen int coauthors_pre = rpoisson(_lambda_coa_pre)

* Pre-treatment article-level impact proxies.
gen double fwci_pre = exp(1.70 + 0.22*ability + 0.45*field_jif + rnormal(0,0.70))
replace fwci_pre = min(fwci_pre,80)
replace fwci_pre = 0 if pubs_pre == 0

gen double mu_cites_pre = 3 + 5*pubs_pre + 0.9*pubs_pre*jif_pre
replace mu_cites_pre = min(mu_cites_pre,2500)
gen int citations_pre = rpoisson(mu_cites_pre)

* Pre-competition affiliation with proposed country / institution.
gen double p_mob_pre = invlogit(-1.10 + 0.28*international_orientation + ///
                                0.08*ability + 0.12*extra_eu)
gen byte mobility_pre = (runiform() < p_mob_pre)

gen double p_host_pre = invlogit(-1.48 + 0.18*international_orientation + ///
                                 0.20*_top_host_true + 0.05*ability)
gen byte host_aff_pre = (runiform() < p_host_pre)

drop mu_pub_pre _lambda_pub_pre mu_coa_pre _lambda_coa_pre ///
     mu_cites_pre p_mob_pre p_host_pre


********************************************************************************
* 7. GENERATE EVALUATION SCORE AND TRUE COMPETITION-SPECIFIC RD ASSIGNMENT
********************************************************************************

* Evaluation score is related smoothly to latent quality and pre-treatment record.
* It is not copied from any real applicant.
gen double evaluation_score = 79.9 ///
    + 4.20*ability ///
    + 0.80*(ln(1+pubs_pre)-2.30) ///
    + 1.20*_top_host_true ///
    + rnormal(0,9.80)

replace evaluation_score = max(0.001,min(99.999,evaluation_score))
format evaluation_score %6.1f
label variable evaluation_score "Artificial evaluation score"

* Rank within artificial competition.
gsort comp_id -evaluation_score application_id
by comp_id: gen int rank_comp = _n

gen byte mainlist = (rank_comp <= main_slots)
label variable mainlist "Artificial initial funding assignment"

* The cutoff is the score of the final initial awardee.
bysort comp_id: egen double cutoff_score = ///
    max(cond(rank_comp==main_slots,evaluation_score,.))

gen double centered_score = evaluation_score - cutoff_score
label variable centered_score "Artificial competition-centered running variable"

* With continuous artificial scores, initial assignment is exactly equivalent to x >= 0.
assert mainlist == (centered_score >= 0)

* There is mechanically at least one x=0 observation in each competition.
gen byte _at_zero = (abs(centered_score) < 1e-12)
bysort comp_id: egen byte _zero_comp = max(_at_zero)
assert _zero_comp == 1
drop _at_zero _zero_comp


********************************************************************************
* 8. GENERATE TWO-SIDED NONCOMPLIANCE / EVENTUAL FELLOWSHIP RECEIPT
********************************************************************************

* Fix one latent uniform draw. We tune probability parameters, never the random seed.
gen double u_fund = runiform()
gen double p_fund = .
gen byte treated = .

* Tune the baseline probability so the overall realized funded share is ~22% while
* imposing a TARGET_FS difference between the left and right probabilities at x=0.
local lo = 0.10
local hi = 0.69

forvalues iter = 1/30 {

    local p0 = (`lo' + `hi')/2
    local p1 = `p0' + $TARGET_FS

    local a0 = ln(`p0'/(1-`p0'))
    local a1 = ln(`p1'/(1-`p1'))

    replace p_fund = invlogit(`a0' + $FUND_SLOPE_L*centered_score) ///
        if mainlist == 0

    replace p_fund = invlogit(`a1' + $FUND_SLOPE_R*centered_score) ///
        if mainlist == 1

    replace treated = (u_fund < p_fund)

    quietly summarize treated, meanonly

    if r(mean) > $TARGET_FUNDED {
        local hi = `p0'
    }
    else {
        local lo = `p0'
    }
}

quietly summarize treated, meanonly
display as text "Synthetic funded share = " %6.4f r(mean)
display as text "Left-limit funding probability parameter  = " %6.4f `p0'
display as text "Right-limit funding probability parameter = " %6.4f `p1'
display as text "Structural probability jump at x=0 = " %6.4f (`p1'-`p0')

label variable treated "Artificial eventual fellowship receipt"


********************************************************************************
* 9. GENERATE FIVE-YEAR MOBILITY POTENTIAL OUTCOMES
********************************************************************************

* Sample means used only to center heterogeneity terms.
quietly summarize extra_eu, meanonly
scalar M_EXTRA = r(mean)

quietly summarize _top_host_true, meanonly
scalar M_TOP = r(mean)

gen byte _extra_top = extra_eu * _top_host_true
quietly summarize _extra_top, meanonly
scalar M_EXTRATOP = r(mean)

* Baseline intended-country affiliation.
gen double p_mob0 = invlogit( ///
      0.35 ///
    + 0.70*mobility_pre ///
    + 0.10*international_orientation ///
    - 0.07*extra_eu ///
    + 0.06*ability ///
    + 0.08*comp_re ///
    + 0.004*centered_score )

* Heterogeneous causal probability shift, centered so average stays near TAU_MOB.
gen double tau_mob_i = $TAU_MOB ///
    + 0.07*(extra_eu - scalar(M_EXTRA)) ///
    + 0.03*(_top_host_true - scalar(M_TOP))

gen double p_mob1 = min(0.985, max(0.001, p_mob0 + tau_mob_i))

* Common-uniform construction creates coherent binary potential outcomes.
gen double u_mob = runiform()
gen byte mobility5_0 = (u_mob < p_mob0)
gen byte mobility5_1 = (u_mob < p_mob1)
gen byte mobility5 = cond(treated==1,mobility5_1,mobility5_0)

label variable mobility5 "Artificial intended-country affiliation within 5 years"

* CV-adjusted proxy: independently correct a small share of apparent false negatives.
gen byte mobility5_adj = mobility5
replace mobility5_adj = 1 if mobility5 == 0 & runiform() < 0.07
label variable mobility5_adj "Artificial CV-adjusted intended-country affiliation"

* Intended host institution.
gen double p_host0 = invlogit( ///
     -0.18 ///
    + 0.95*host_aff_pre ///
    + 0.12*_top_host_true ///
    + 0.07*ability ///
    + 0.05*comp_re ///
    + 0.003*centered_score )

gen double tau_host_i = $TAU_HOST ///
    + 0.05*(extra_eu - scalar(M_EXTRA)) ///
    + 0.04*(_top_host_true - scalar(M_TOP))

gen double p_host1 = min(0.985,max(0.001,p_host0 + tau_host_i))

gen double u_host = runiform()
gen byte host_aff5_0 = (u_host < p_host0)
gen byte host_aff5_1 = (u_host < p_host1)
gen byte host_aff5 = cond(treated==1,host_aff5_1,host_aff5_0)

label variable host_aff5 "Artificial intended-host affiliation within 5 years"

* Mobility to a third/alternative country: deliberately no causal treatment effect.
gen double p_third0 = invlogit(-0.78 + 0.16*international_orientation + ///
                               0.05*ability + 0.04*comp_re)
gen byte third_country5 = (runiform() < p_third0)
label variable third_country5 "Artificial mobility to other country within 5 years"

* Any new affiliation: large baseline probability, essentially no treatment effect.
gen double p_newaff0 = invlogit(1.05 + 0.10*ability + 0.08*network_orientation)
gen byte new_aff5 = (runiform() < p_newaff0)

drop p_mob0 p_mob1 p_host0 p_host1 p_third0 p_newaff0 ///
     u_mob u_host mobility5_0 mobility5_1 host_aff5_0 host_aff5_1


********************************************************************************
* 10. GENERATE FIVE-YEAR SCIENTIFIC POTENTIAL OUTCOMES
********************************************************************************

* ----------------------------------------------------------------------
* Publications
* ----------------------------------------------------------------------

gen double mu_pub5_0 = exp( ///
      0.95 ///
    + 0.58*ln(1+pubs_pre) ///
    + 0.15*ability ///
    + 0.35*field_pub ///
    + 0.10*comp_re )

gen double _lambda_pub5 = mu_pub5_0 * rgamma(2.0,1/2.0)
gen int pubs5_0 = rpoisson(_lambda_pub5)

* Heterogeneity is intentionally centered: small average effect, more positive
* effects for extra-European and top-host moves, largest when both occur.
gen double tau_pub_i = $TAU_PUB ///
    + 4.0*(extra_eu - scalar(M_EXTRA)) ///
    + 4.0*(_top_host_true - scalar(M_TOP)) ///
    + 5.0*(_extra_top - scalar(M_EXTRATOP))

gen double pubs5_raw = pubs5_0 + treated*tau_pub_i
replace pubs5_raw = max(0,pubs5_raw)
gen int pubs5 = round(pubs5_raw)

* Winsorize at the synthetic 99th percentile as in the paper.
quietly summarize pubs5, detail
scalar P99_PUB5 = r(p99)
replace pubs5 = min(pubs5,scalar(P99_PUB5))

gen double ln_pubs5 = ln(1+pubs5)

* ----------------------------------------------------------------------
* Journal impact
* ----------------------------------------------------------------------

gen double jif5_0 = 3.0 + 0.72*jif_pre + 1.2*ability + ///
                    3.0*field_jif + 0.8*comp_re + rnormal(0,15)
replace jif5_0 = max(0,jif5_0)

gen double tau_jif_i = $TAU_JIF ///
    + 8.0*(extra_eu - scalar(M_EXTRA)) ///
    + 10.0*(_top_host_true - scalar(M_TOP)) ///
    + 12.0*(_extra_top - scalar(M_EXTRATOP))

gen double jif5 = jif5_0 + treated*tau_jif_i
replace jif5 = max(0,jif5)
replace jif5 = min(jif5,180)
gen double ln_jif5 = ln(1+jif5)

* ----------------------------------------------------------------------
* Field-weighted impact
* ----------------------------------------------------------------------

gen double fwci5_0 = 2.2 + 0.80*fwci_pre + 0.45*ability + ///
                     1.0*field_jif + rnormal(0,9)
replace fwci5_0 = max(0,fwci5_0)

gen double tau_fwci_i = $TAU_FWCI ///
    + 2.0*(extra_eu - scalar(M_EXTRA)) ///
    + 2.5*(_top_host_true - scalar(M_TOP)) ///
    + 3.0*(_extra_top - scalar(M_EXTRATOP))

gen double fwci5 = fwci5_0 + treated*tau_fwci_i
replace fwci5 = max(0,fwci5)
replace fwci5 = min(fwci5,120)
gen double ln_fwci5 = ln(1+fwci5)

* ----------------------------------------------------------------------
* New coauthors
* ----------------------------------------------------------------------

gen double mu_coa5_0 = exp( ///
      1.00 ///
    + 0.75*ln(1+coauthors_pre) ///
    + 0.12*ability ///
    + 0.25*field_net ///
    + 0.08*comp_re )

* Preserve the legacy RNG path for every outcome generated below this block.
* First consume the original coauthor draws and record the resulting state.
local rng_before_coauthors "`c(rngstate)'"
gen double _lambda_coa5_legacy = mu_coa5_0 * rgamma(1.5,1/1.5)
gen int coauthors5_0_legacy = rpoisson(_lambda_coa5_legacy)
local rng_after_coauthors "`c(rngstate)'"

* Generate revised coauthor counts from an isolated, reproducible stream.
set rngstate `rng_before_coauthors'
gen double _lambda_coa5 = mu_coa5_0 * rgamma(0.50,1/0.50)
gen int coauthors5_0 = rpoisson(_lambda_coa5)

* Resume the legacy stream before citations, ten-year outcomes, certification,
* and missingness are generated.
set rngstate `rng_after_coauthors'
drop _lambda_coa5_legacy coauthors5_0_legacy

gen double tau_coa_i = $TAU_COA ///
    + 12.0*(extra_eu - scalar(M_EXTRA)) ///
    + 15.0*(_top_host_true - scalar(M_TOP)) ///
    + 20.0*(_extra_top - scalar(M_EXTRATOP))

gen double coauthors5_raw = coauthors5_0 + treated*tau_coa_i
replace coauthors5_raw = max(0,coauthors5_raw)
gen int coauthors5 = round(coauthors5_raw)

quietly summarize coauthors5, detail
scalar P99_COA5 = r(p99)
replace coauthors5 = min(coauthors5,scalar(P99_COA5))
gen double ln_coauthors5 = ln(1+coauthors5)

* Additional publication outcomes used by robustness code.
gen int pubs_first5 = rbinomial(pubs5,0.40)
gen int pubs_all5   = pubs5 + rpoisson(0.9 + 0.05*pubs5)

* Citations: noisy article-level impact measure.
gen double mu_cites5 = 10 + 11*pubs5 + 3.8*jif5
replace mu_cites5 = max(0,min(mu_cites5,5000))
gen int citations5 = rpoisson(mu_cites5)

quietly summarize citations5, detail
scalar P99_CITES5 = r(p99)
replace citations5 = min(citations5,scalar(P99_CITES5))
gen double ln_citations5 = ln(1+citations5)

drop mu_pub5_0 _lambda_pub5 pubs5_0 pubs5_raw ///
     jif5_0 fwci5_0 mu_coa5_0 _lambda_coa5 coauthors5_0 coauthors5_raw ///
     mu_cites5


********************************************************************************
* 11. GENERATE TEN-YEAR OUTCOMES JOINTLY WITH FIVE-YEAR OUTCOMES
********************************************************************************

* Mobility indicators defined as "ever within T years" must weakly increase.
gen byte mobility10 = mobility5
replace mobility10 = 1 if mobility5 == 0 & runiform() < ///
    invlogit(-1.2 + 0.20*international_orientation + 0.05*treated)

gen byte mobility10_adj = mobility10
replace mobility10_adj = 1 if mobility10 == 0 & runiform() < 0.06

gen byte host_aff10 = host_aff5
replace host_aff10 = 1 if host_aff5 == 0 & runiform() < ///
    invlogit(-1.5 + 0.10*ability + 0.05*treated)

gen byte third_country10 = third_country5
replace third_country10 = 1 if third_country5 == 0 & runiform() < ///
    invlogit(-1.3 + 0.15*international_orientation)

* Publications and coauthors are cumulative counts.
gen double mu_pub_inc = 7.5 + 0.32*pubs_pre + 0.8*max(ability,0)
gen int pubs10 = pubs5 + rpoisson(mu_pub_inc)
gen double ln_pubs10 = ln(1+pubs10)

gen double mu_coa_inc = 34 + 0.48*coauthors_pre + 2*max(network_orientation,0)
gen int coauthors10 = coauthors5 + rpoisson(mu_coa_inc)
gen double ln_coauthors10 = ln(1+coauthors10)

* Average JIF/FWCI need not be monotonic because they are averages over a longer window.
gen double jif10 = max(0,0.65*jif5 + 0.35*jif_pre + rnormal(4,9))
gen double ln_jif10 = ln(1+jif10)

gen double fwci10 = max(0,0.65*fwci5 + 0.35*fwci_pre + rnormal(1,5))
gen double ln_fwci10 = ln(1+fwci10)

* Cumulative citations.
gen double mu_cites_inc = 40 + 8*pubs10 + 2*jif10
replace mu_cites_inc = min(mu_cites_inc,7000)
gen int citations10 = citations5 + rpoisson(mu_cites_inc)
gen double ln_citations10 = ln(1+citations10)

gen int pubs_first10 = pubs_first5 + rbinomial(pubs10-pubs5,0.40)
gen int pubs_all10   = pubs10 + rpoisson(1.4 + 0.05*pubs10)

assert pubs10 >= pubs5
assert coauthors10 >= coauthors5
assert citations10 >= citations5
assert mobility10 >= mobility5
assert host_aff10 >= host_aff5

drop mu_pub_inc mu_coa_inc mu_cites_inc


********************************************************************************
* 12. OPTIONAL CERTIFICATION-STYLE OUTCOME
********************************************************************************

* Citations received after the competition by already-existing work.
* Average grant effect is small; extra-EU x top-host is more positive.
gen double cert_cites5_0 = max(0, ///
    15 + 2.0*citations_pre + 2.5*jif_pre + 15*ability + rnormal(0,120))

gen double tau_cert_i = ///
      0 ///
    + 15*(extra_eu - scalar(M_EXTRA)) ///
    + 20*(_top_host_true - scalar(M_TOP)) ///
    + 60*(_extra_top - scalar(M_EXTRATOP))

gen double cert_cites5 = max(0, cert_cites5_0 + treated*tau_cert_i)

gen double cert_cites10 = max(cert_cites5, ///
    cert_cites5 + 0.8*cert_cites5_0 + rnormal(20,120))

drop cert_cites5_0


********************************************************************************
* 13. ARTIFICIAL MISSINGNESS NEEDED BY THE REPLICATION CODE
********************************************************************************

* 39 observations are removed from many matched bibliometric outcomes in the paper's
* preferred sample. Reproduce the aggregate count only; identities are random.

gen double _miss_bib_u = runiform()
sort _miss_bib_u
gen byte bibliometric_missing = (_n <= 39)
sort application_id

foreach v in mobility_pre host_aff_pre pubs_pre pubs_all_pre pubs_first_pre pubs_last_pre ///
             jif_pre fwci_pre citations_pre coauthors_pre ///
             mobility5 mobility5_adj host_aff5 third_country5 new_aff5 ///
             pubs5 ln_pubs5 jif5 ln_jif5 fwci5 ln_fwci5 coauthors5 ln_coauthors5 ///
             pubs_first5 pubs_all5 citations5 ln_citations5 ///
             mobility10 mobility10_adj host_aff10 third_country10 ///
             pubs10 ln_pubs10 jif10 ln_jif10 fwci10 ln_fwci10 ///
             coauthors10 ln_coauthors10 citations10 ln_citations10 ///
             pubs_first10 pubs_all10 cert_cites5 cert_cites10 {
    replace `v' = . if bibliometric_missing
}

* Ranking missingness: create approximately the same aggregate availability as the
* public descriptive table, but randomize which synthetic records are missing.
gen double _miss_rank_u = runiform()
sort _miss_rank_u
gen byte rank_missing = (_n <= ($N - 30009))
replace host_rank = . if rank_missing
replace top_host  = . if rank_missing
sort application_id

* GDP/distance aggregate missingness.
gen double _miss_geo_u = runiform()
sort _miss_geo_u
gen byte geo_missing = (_n <= ($N - 40836))
replace host_gdppc = . if geo_missing
replace distance_km = . if geo_missing
sort application_id

* Doctor/professor aggregate missingness.
gen double _miss_status_u = runiform()
sort _miss_status_u
gen byte status_missing = (_n <= ($N - 41002))
replace doctor = . if status_missing
replace professor = . if status_missing
sort application_id

* Same-nationality/host aggregate missingness.
gen double _miss_same_u = runiform()
sort _miss_same_u
gen byte samenat_missing = (_n <= ($N - 40853))
replace same_nat_host = . if samenat_missing
sort application_id

drop _miss_bib_u _miss_rank_u _miss_geo_u _miss_status_u _miss_same_u


********************************************************************************
* 14. CLEAN INTERNAL VARIABLES AND ADD ANALYSIS ALIASES
********************************************************************************

* Keep the latent researcher factors if useful for transparency; drop variables that expose
* potential outcomes / internal simulation mechanics.
drop u_fund p_fund ///
     tau_mob_i tau_host_i ///
     tau_pub_i tau_jif_i tau_fwci_i tau_coa_i tau_cert_i ///
     _extra_top _top_host_true ///
     field_pub field_jif field_net ///
     ability international_orientation network_orientation ///
     comp_re main_share_c main_slots n_app app_within_comp ///
     rank_missing geo_missing status_missing samenat_missing ///
     bibliometric_missing

* Optional aliases: change these names to match the actual replication code.
clonevar score_centered       = centered_score
clonevar grant_received       = treated
clonevar initial_offer        = mainlist
clonevar aff_host_country_5y  = mobility5
clonevar aff_host_inst_5y     = host_aff5
clonevar publications_5y      = pubs5
clonevar average_jif_5y       = jif5
clonevar coauthors_5y         = coauthors5

* Human-readable labels.
label variable mobility_direction "Artificial mobility direction category"
label variable origin_eu          "Artificial origin in EU28"
label variable host_eu            "Artificial host in EU28"
label variable european_resident  "Artificial European residence indicator"
label variable eu27_resident      "Artificial EU27 residence indicator"
label variable host_type          "Artificial host organization type"
label variable host_hei           "Artificial higher-education host indicator"
label variable host_research      "Artificial research-organization host indicator"
label variable host_other         "Artificial other-host indicator"
label variable proposal_duration  "Artificial proposal duration (months)"
label variable host_rank          "Artificial host Scimago ranking"
label variable top_host           "Artificial top-50 host indicator"
label variable host_gdppc         "Artificial host-country GDP per capita"
label variable distance_km        "Artificial origin-host distance (km)"
label variable same_nat_host      "Artificial same-nationality-as-host indicator"
label variable pubs_pre           "Artificial publication count before competition"
label variable pubs_all_pre       "Artificial broad publication count before competition"
label variable pubs_first_pre     "Artificial first-authored publications before competition"
label variable pubs_last_pre      "Artificial last-authored publications before competition"
label variable jif_pre            "Artificial average JIF before competition"
label variable coauthors_pre      "Artificial coauthor count before competition"
label variable fwci_pre           "Artificial FWCI before competition"
label variable citations_pre      "Artificial citations before competition"
label variable mobility_pre       "Artificial intended-country affiliation before competition"
label variable host_aff_pre       "Artificial intended-host affiliation before competition"
label variable rank_comp          "Artificial rank within competition"
label variable cutoff_score       "Artificial competition funding cutoff"
label variable new_aff5           "Artificial new-affiliation indicator within 5 years"
label variable pubs5              "Artificial publication count within 5 years"
label variable ln_pubs5           "Log(1 + artificial publications within 5 years)"
label variable jif5               "Artificial average JIF within 5 years"
label variable ln_jif5            "Log(1 + artificial average JIF within 5 years)"
label variable fwci5              "Artificial FWCI within 5 years"
label variable ln_fwci5           "Log(1 + artificial FWCI within 5 years)"
label variable coauthors5         "Artificial coauthor count within 5 years"
label variable ln_coauthors5      "Log(1 + artificial coauthors within 5 years)"
label variable pubs_first5        "Artificial first-authored publications within 5 years"
label variable pubs_all5          "Artificial broad publication count within 5 years"
label variable citations5         "Artificial citations within 5 years"
label variable ln_citations5      "Log(1 + artificial citations within 5 years)"
label variable mobility10         "Artificial intended-country affiliation within 10 years"
label variable mobility10_adj     "Artificial CV-adjusted affiliation within 10 years"
label variable host_aff10         "Artificial intended-host affiliation within 10 years"
label variable third_country10    "Artificial other-country affiliation within 10 years"
label variable pubs10             "Artificial publication count within 10 years"
label variable ln_pubs10          "Log(1 + artificial publications within 10 years)"
label variable coauthors10        "Artificial coauthor count within 10 years"
label variable ln_coauthors10     "Log(1 + artificial coauthors within 10 years)"
label variable jif10              "Artificial average JIF within 10 years"
label variable ln_jif10           "Log(1 + artificial average JIF within 10 years)"
label variable fwci10             "Artificial FWCI within 10 years"
label variable ln_fwci10          "Log(1 + artificial FWCI within 10 years)"
label variable citations10        "Artificial citations within 10 years"
label variable ln_citations10     "Log(1 + artificial citations within 10 years)"
label variable pubs_first10       "Artificial first-authored publications within 10 years"
label variable pubs_all10         "Artificial broad publication count within 10 years"
label variable cert_cites5        "Artificial citations to pre-existing work within 5 years"
label variable cert_cites10       "Artificial citations to pre-existing work within 10 years"
label variable grant_received      "Synthetic fellowship receipt"
label variable initial_offer       "Synthetic initial main-list placement"
label variable aff_host_country_5y "Synthetic intended-country affiliation, 5 years"
label variable aff_host_inst_5y    "Synthetic intended-host affiliation, 5 years"
label variable publications_5y     "Synthetic publication count, 5 years"
label variable average_jif_5y      "Synthetic average JIF, 5 years"
label variable coauthors_5y        "Synthetic new coauthor count, 5 years"

* Basic integrity checks.
assert _N == $N
isid application_id
assert inrange(treated,0,1)
assert inrange(mainlist,0,1)
assert mainlist == (centered_score >= 0)
assert inrange(female,0,1)
assert age >= 24 & age <= 60

egen byte _tag_comp = tag(comp_id)
quietly count if _tag_comp
assert r(N) == $NCOMP
drop _tag_comp

* Organize the comprehensive pseudo-data by concept and time horizon.
order application_id researcher_id comp_id year action panel applied_before ///
    female age doctor professor european_national eu27_national ///
    european_resident eu27_resident ///
    mobility_direction extra_eu same_side origin_eu host_eu origin_ctry host_ctry ///
    host_type host_hei host_research host_other proposal_duration host_rank top_host ///
    host_gdppc distance_km same_nat_host ///
    pubs_pre pubs_all_pre pubs_first_pre pubs_last_pre jif_pre fwci_pre ///
    citations_pre coauthors_pre mobility_pre host_aff_pre ///
    evaluation_score rank_comp cutoff_score centered_score mainlist treated ///
    mobility5 mobility5_adj host_aff5 third_country5 new_aff5 ///
    pubs5 ln_pubs5 pubs_first5 pubs_all5 jif5 ln_jif5 fwci5 ln_fwci5 ///
    citations5 ln_citations5 coauthors5 ln_coauthors5 ///
    mobility10 mobility10_adj host_aff10 third_country10 ///
    pubs10 ln_pubs10 pubs_first10 pubs_all10 jif10 ln_jif10 fwci10 ln_fwci10 ///
    citations10 ln_citations10 coauthors10 ln_coauthors10 ///
    cert_cites5 cert_cites10 ///
    score_centered grant_received initial_offer aff_host_country_5y ///
    aff_host_inst_5y publications_5y average_jif_5y coauthors_5y

compress
sort comp_id centered_score application_id

* Fail if a future edit introduces an unlabeled release variable.
foreach var of varlist _all {
    local varlabel : variable label `var'
    if `"`varlabel'"' == "" {
        display as error "Variable `var' has no label."
        exit 459
    }
}
label data "SYNTHETIC MSCA pseudo-data; not observed applicants"
save "data/pseudo/msca_pseudo.dta", replace

assert pubs10 >= pubs5 if !missing(pubs10,pubs5)
assert coauthors10 >= coauthors5 if !missing(coauthors10,coauthors5)
assert citations10 >= citations5 if !missing(citations10,citations5)
assert mobility10 >= mobility5 if !missing(mobility10,mobility5)
assert host_aff10 >= host_aff5 if !missing(host_aff10,host_aff5)
log close pseudodata
