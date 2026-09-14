# Main-text source map

Author-confirmed manuscript: `submission_repackaged/Nature_Communications/manuscript/main.tex`, inspected 13 September 2026. Its three figures and two tables define the package scope. Original research scripts and data are not modified. Historical source paths identify the original estimation blocks.

## Find a specification in the replication scripts

Search for the exact section header below in the indicated script. Table columns sharing a loop have adjacent column headers; the loop is retained. Figure 2 panels sharing a loop are identified by `split`. Figure 3 uses four unlettered plots, listed from left to right.

| Manuscript item | Script under `scripts/` | Exact section header | Output under `output/` |
| --- | --- | --- | --- |
| Figure 1a | `02_figure1_design.do` | `Figure 1, panel a: Treatment compliance` | `figures/figure1_compliance.pdf` |
| Figure 1b | `02_figure1_design.do` | `Figure 1, panel b: Probability of receiving the grant` | `figures/figure1_probability.pdf` |
| Figure 1c | `02_figure1_design.do` | `Figure 1, panel c: Covariate balance around the funding threshold` | `figures/figure1_balance.pdf` |
| Table 1, column 1 | `03_table1_mobility.do` | `Table 1, column 1: Intended country` | `tables/mobility_second_specifications.tex` |
| Table 1, column 2 | `03_table1_mobility.do` | `Table 1, column 2: Intended country (CV-adjusted)` | same table |
| Table 1, column 3 | `03_table1_mobility.do` | `Table 1, column 3: Intended host institution` | same table |
| Table 1, column 4 | `03_table1_mobility.do` | `Table 1, column 4: Third countries` | same table |
| Table 2, column 1 | `04_table2_research.do` | `Table 2, column 1: Publications` | `tables/research_second_specifications.tex` |
| Table 2, column 2 | `04_table2_research.do` | `Table 2, column 2: Average JIF` | same table |
| Table 2, column 3 | `04_table2_research.do` | `Table 2, column 3: FWCI` | same table |
| Table 2, column 4 | `04_table2_research.do` | `Table 2, column 4: Coauthors` | same table |
| Figure 2a, mobility type | `05_figures2_3_heterogeneity.do` | `Figure 2, panels a-c: Estimate outcome heterogeneity`; `split = geography` | `figures/heterogeneity_combined.pdf` |
| Figure 2b, host ranking | same script | same section; `split = quality` | same figure |
| Figure 2c, combination | same script | same section; `split = joint` | same figure |
| Figure 2, drawing panels | same script | `Figure 2, panels a-c: Plot outcome heterogeneity` | same figure |
| Figure 3, all four plots | same script | `Figure 3: Estimate certification effects`; `average`, `geography`, `quality`, `joint` | `figures/certification_heterogeneity.pdf` |
| Figure 3, drawing plots | same script | `Figure 3: Plot certification effects` | same figure |
| Both tables, formatting | `06_export_submitted_tables.do` | `Tables 1 and 2: Export submitted layouts` | both table TeX files |

| Item | Original source within `MSCA_31_10_23/scripts/` | Selected content |
| --- | --- | --- |
| Figure 1a/b/c | `026_nc_figure1_balance.do`, lines 34–118 | 15-competition scatter, 100-bin receipt plot, nine covariate plots |
| Table 1, columns 1–2 | `009_fuzzy_rdd_mobility.do`, lines 192–194 | Second specification for `d_pubs_dest_post` and `mob_linkedin_post` |
| Table 1, column 3 | `009_fuzzy_rdd_mobility.do`, lines 282–283 | Second specification for `d_pubs_in_dest_aff_post_5` |
| Table 1, column 4 | `009_fuzzy_rdd_mobility.do`, lines 296–297 | Second specification for `d_pubs_outside_both_5` |
| Table 2, publications and JIF | `010_fuzzy_rdd_outcomes.do`, second-specification blocks (lines 126–128 and 234–236) | Levels at five years |
| Table 2, coauthors | `010_fuzzy_rdd_outcomes.do`, second-specification coauthor block | `coauths_count_post`, controlling for `coauths_count_pre i.comp` |
| Table 2, FWCI | `014_appendix_D.do`, five-year FWCI block, lines 507–508 | Levels, second specification; included because displayed in main-text Table 2 |
| Figures 2 and 3 | `024_revision_heterogeneity.do`, estimation and plotting sections 1–6 | 42 estimates, same geography/rank groups, same robust intervals |

All table specifications use local linear fuzzy RD, a triangular kernel, MSE-optimal bandwidths, the corresponding pre-outcome control and competition fixed effects, with competition-clustered inference. Those options that were implicit defaults remain implicit; the supplied `rdrobust` version is fixed.

## Figure 2 cell map

Four outcomes: `main`, `main_jif`, `d_pubs_dest`, `coauths_count`, each at five years.

- Geography cells 1/2: same-side / extra-EU.
- Quality cells 1/2: top 50 / other ranked institutions.
- Joint cells 1/2: same-side, top 50 / other ranked; cells 3/4: extra-EU, top 50 / other ranked.
- Missing ranks are excluded from quality and joint splits, as in the source.
- Same-side includes both EU28-to-EU28 and non-EU28-to-non-EU28 proposals. The original EU28 list, including the UK, is retained.

Figure 3 repeats these eight subgroup cells for five-year certification and adds average effects at five and ten years. Points are conventional estimates; endpoints are the original 90% robust bias-corrected intervals, which need not be centered on those points.

The old filenames and script comments sometimes use earlier figure/table numbers. The manuscript map above takes precedence for the package labels.

The submission and original script paths above are historical provenance references outside this public package; they are not run dependencies. Table and figure templates needed for replication are included in `templates/`.
