# Release validation

**PASS — 14 September 2026, before the PDF-only export change.** The package completed from a clean temporary copy without generated inputs or outputs, using StataNow/SE 19.5 (Revision 15 April 2026), macOS Intel 64-bit. The master run took 524 seconds (8 minutes 44 seconds). The current version differs in executable commands only by removal of PNG exports and their master checks; it has not received a further full run. Other operating systems and peak memory have not been tested/measured.

- Generator and adapter integrity assertions passed: 41,024 artificial applications and 236 competitions; all artificial citation records matched.
- Eight main-table estimates and 42 coefficient-figure estimates matched the previous validated synthetic CSV outputs exactly.
- Data, inference, sample-count, interval and uniqueness assertions passed.
- The validated run exported five figure components to PDF and PNG and two tables to LaTeX. The master completion marker was verified. The current package retains and exports only the figure PDFs.
- Script 04 was rerun after the completed master: the combined table file retained eight records and every estimate remained unchanged.
- Both tables match the submitted templates apart from numerical cells. All three figure wrappers and captions match the submission.

The local five-page preview was visually inspected during the previous validation. The subsequent PDF-only change removes PNG exports and their master checks; estimation, graph construction, PDF exports and templates are unchanged. The full master was not rerun for this export-only change, and no new preview rendering was performed. The preview, generated datasets and local logs are excluded from the public release. Synthetic reference figures, tables and CSV files are included.

To recheck, run `do run_all.do` from the package root. No separate validation utility is required.

These checks establish execution with artificial data. They do not verify the paper's empirical findings or the confidential-data linkage pipeline.
