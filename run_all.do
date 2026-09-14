*=============================================================================*
* Project: MSCA -- Nature Communications main-text replication
* Purpose: Master file; run from this package directory: do run_all.do
* Inputs and results are fully synthetic. Requires licensed Stata 19.
*=============================================================================*

// Clear memory and set options
*=============================================================================*
version 19
clear all
set more off
set linesize 255
set seed 20260911
set sortseed 20260911
set scheme stcolor

// Use included packages
*=============================================================================*
cap adopath - PERSONAL
cap adopath - PLUS
cap adopath - SITE
cap adopath - OLDPLACE
adopath ++ "stata_packages"
foreach dir in b c e r _ {
    adopath ++ "stata_packages/`dir'"
}

// Create folders for generated files
*=============================================================================*
foreach dir in data data/pseudo output output/figures output/tables ///
    output/source_data logs documentation {
    cap mkdir "`dir'"
}

// Initialize log and record system parameters (no licence metadata)
*=============================================================================*
cap log close _all
log using "logs/run_all.log", text replace name(master)
di "Begin date and time: $S_DATE $S_TIME"
di "Stata version: `c(stata_version)'"
di "Updated as of: `c(born_date)'"
di "Variant: `c(flavor)'"
di "OS: `c(os)'"
di "Machine type: `c(machine_type)'"
foreach command in rdrobust rdplot binscatter coefplot eststo estadd {
    which `command'
}

// Build synthetic analysis data
*=============================================================================*
do scripts/00_generate_msca_pseudodata.do
do scripts/01_prepare_analysis_inputs.do

// Main-text analysis
*=============================================================================*
do scripts/02_figure1_design.do
do scripts/03_table1_mobility.do
do scripts/04_table2_research.do
do scripts/05_figures2_3_heterogeneity.do

// Export tables with the submitted titles, headings and notes
*=============================================================================*
do scripts/06_export_submitted_tables.do

// Check that all main-text outputs were produced
*=============================================================================*
foreach file in figure1_compliance figure1_probability figure1_balance ///
    heterogeneity_combined certification_heterogeneity {
    confirm file "output/figures/`file'.pdf"
}
foreach file in mobility_second_specifications research_second_specifications {
    confirm file "output/tables/`file'.tex"
}
di "End date and time: $S_DATE $S_TIME"
di as result "MAIN-TEXT PACKAGE COMPLETE: 3 figures, 2 tables; SYNTHETIC DATA."
log close master
