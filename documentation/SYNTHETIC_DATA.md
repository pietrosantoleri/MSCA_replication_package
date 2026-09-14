# Synthetic-data definitions

The supplied generator creates artificial records entirely through explicit random draws. No observed applicant data are read, sampled, or merged. Its target parameters are inherited as supplied; their public provenance is not independently certified by this package. Simulation parameter choices describe a demonstration DGP, not estimates recovered from the paper.

## Direct mappings

Script 01 creates the source-to-analysis aliases. Important mappings include:

| Original analysis variable | Generator variable | Interpretation |
| --- | --- | --- |
| `prop_id`, `comp`, `margin2`, `treat` | `application_id`, `comp_id`, `centered_score`, `treated` | Artificial application/competition IDs, score margin, actual funding |
| `sex`, `prof`, `nat_eu27` | `female`, `professor`, `eu27_national` | Female indicator (matching original sex coding), professor status, EU27 nationality |
| `main_pre`, `main_post` | `pubs_pre`, `pubs5` | Pre/five-year synthetic publications |
| `main_jif_pre`, `main_jif_post` | `jif_pre`, `jif5` | Synthetic journal impact |
| `fwci_pre`, `fwci_post` | `fwci_pre`, `fwci5` | Synthetic field-weighted impact |
| `coauths_count_pre`, `coauths_count_post` | `coauthors_pre`, `coauthors5` | Synthetic coauthor counts |
| `d_pubs_dest_pre`, `d_pubs_dest_post` | `mobility_pre`, `mobility5` | Intended-country affiliation |
| `mob_linkedin_post` | `mobility5_adj` | Synthetic CV-adjusted affiliation proxy |
| `d_pubs_in_dest_aff_pre`, `d_pubs_in_dest_aff_post_5` | `host_aff_pre`, `host_aff5` | Intended-host affiliation |
| `d_pubs_outside_both_5` | `third_country5` | Synthetic post-period third-country indicator |
| `globalrank`, `gdppc` | `host_rank`, `host_gdppc` | Artificial host rank and GDP per capita |

## Compatibility additions

The adapter sorts by application ID and uses a separate fixed seed, 20260913, without changing the template’s draws.

- **CV-adjusted pre-outcome:** draw an artificial `was_in_destination` Bernoulli indicator with probability .07 for nonmissing pre-affiliation records. Follow the original code by starting from publication-based affiliation and changing zero to one when this artificial CV indicator is one. The post-outcome remains the template’s adjusted proxy. This is not a reconstruction of real CV corrections or their near-cutoff sampling.
- **Third-country pre-outcome:** a Bernoulli draw with probability `invlogit(-1.2 + .25*extra_eu + .15*ln(1+pubs_pre))`, missing when pre-publications are missing. It contains no treatment term. The post-outcome remains the template’s third-country proxy, without an annual publication-file reconstruction.
- **Country strings:** the template’s 15 artificial European country categories map to AT, BE, BG, HR, CY, CZ, DK, EE, FI, FR, DE, EL, HU, IE, IT; its 15 non-European categories map to US, CA, AU, CN, IN, JP, BR, MX, NZ, ZA, KR, SG, CL, AR, CH. These are compatibility labels, not actual country observations or a calibrated geographical distribution. Membership matches the original EU28 loop. Using CH in the non-EU28 set illustrates that this is the analysis’s EU28 boundary, not a geographical definition of Europe.
- **Certification:** synthetic `citations_pre`, `cert_cites5`, and `cert_cites10` become `main_citrec_pre`, `main_citrec_post`, and `main_citrec_post_10` in a separate artificial file. The pre-control is a synthetic citation proxy. The post variables model citations to pre-existing work; there is no paper-level citation reconstruction or independently identifiable self-citation process. Each window is winsorized at its full synthetic-sample p99, using the original analysis code.

## Integrity and limitations

The generator asserts 41,024 applications, 236 competitions, unique application IDs, binary treatment and offer indicators, and coherent cumulative horizons. It randomly assigns 39 missing bibliometric records; the adapter checks 40,985 nonmissing publication outcomes. Rank and other missingness follow the supplied template. Analysis-ready records retain only main-text variables. They are not an anonymized copy of real data.

The supplied DGP is kept even where simplified proxies do not reproduce the full administrative/bibliometric definitions. Successful execution will test software behavior on this artificial input, not the measurement pipeline or empirical findings. Pseudo-data should not be interpreted as observed researchers or used to draw policy conclusions.

## Generated input files

All three inputs are generated under `data/pseudo/`: `msca_pseudo.dta` contains the initial artificial records, `msca_analysis_pseudo.dta` contains the analysis variables, and `citations_pseudo.dta` contains the artificial citation input. The master creates these files before estimating the main-text outputs.
