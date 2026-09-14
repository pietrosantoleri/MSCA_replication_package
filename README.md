# Mobility grants induce international moves with uneven effects on scientific performance

Main-text Stata replication package for the Nature Communications submission by **Stefano Baruffaldi, Pietro Santoleri and Yevgeniya Shevtsova**.

**All included data and numerical outputs are fully synthetic.** This package demonstrates the analysis workflow for the three main figures and two main tables. It does not reproduce or verify the paper’s confidential-data findings. Submitted titles, labels, captions and notes are retained; descriptions of empirical measurements in those notes refer to the paper, while this package uses artificial substitutes.

Contact: [Pietro Santoleri](mailto:pietro.santoleri@ec.europa.eu).

## Run the package

1. Download or clone this repository.
2. Open licensed Stata 19 and set its working directory to the repository folder.
3. Run:

```stata
do run_all.do
```

The tested environment is StataNow/SE 19.5 on macOS. Allow approximately nine minutes; runtime depends on the machine. Other operating systems have not been tested. No internet connection, original research data, R or Python is required. The original versions of user-written Stata commands are bundled in `stata_packages/`.

The master generates artificial inputs, runs the main-text analysis and exports the results. It overwrites generated files inside this package. A successful run ends with `MAIN-TEXT PACKAGE COMPLETE` in `logs/run_all.log`. Logs and generated input datasets are local files excluded from the public release. The generator and adapter write `msca_pseudo.dta`, `msca_analysis_pseudo.dta` and `citations_pseudo.dta` under `data/pseudo/`.

## Main-text outputs

All numerical results in the linked files are **synthetic examples**.

| Paper item | Analysis script | Output |
| --- | --- | --- |
| Figure 1: design and covariate balance | [02](scripts/02_figure1_design.do) | [Compliance](output/figures/figure1_compliance.pdf), [probability](output/figures/figure1_probability.pdf), [balance](output/figures/figure1_balance.pdf) |
| Table 1: mobility | [03](scripts/03_table1_mobility.do) | [Table 1](output/tables/mobility_second_specifications.tex) |
| Table 2: scientific outcomes | [04](scripts/04_table2_research.do) | [Table 2](output/tables/research_second_specifications.tex) |
| Figure 2: outcome heterogeneity | [05](scripts/05_figures2_3_heterogeneity.do) | [Figure 2](output/figures/heterogeneity_combined.pdf) |
| Figure 3: certification | [05](scripts/05_figures2_3_heterogeneity.do) | [Figure 3](output/figures/certification_heterogeneity.pdf) |

Script [06](scripts/06_export_submitted_tables.do) formats the estimates from scripts 03 and 04 using the submitted table templates. Full-precision [table](output/source_data/table_estimates.csv) and [figure](output/source_data/figure_estimates.csv) estimates are also included. `templates/figure*.tex` retain the submitted captions and figure layouts. Supplementary analyses are outside this package’s scope.

## Data and methods

Script 01 prepares synthetic analysis variables, CV-adjusted affiliation proxies, country codes and citation inputs. These artificial substitutes demonstrate the analysis and do not reconstruct the original measurement pipeline.

The analysis begins at artificial application-level inputs. Administrative-data ingestion, author matching and bibliometric linkage are not reconstructed. The original empirical data are confidential. Independent access requires authorization from European Commission DG RTD Unit G.2, [RTD-G2-SUPPORT@ec.europa.eu](mailto:RTD-G2-SUPPORT@ec.europa.eu); access is at DG RTD’s discretion and is not controlled by the authors.

## Citation and licence

Use [CITATION.cff](CITATION.cff) to cite this software package; the manuscript is an unpublished submission. Project code, synthetic data and generated synthetic outputs are supplied under the [MIT licence](LICENSE). Third-party commands retain their own terms and notices: see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).

This folder is intended to be the repository root. The original research project and confidential datasets must remain outside the public repository.
