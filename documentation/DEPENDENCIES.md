# Dependency inventory

Validated on 14 September 2026 with StataNow/SE 19.5 (Revision 15 April 2026), macOS Intel 64-bit. The clean-directory run took 524 seconds (8 minutes 44 seconds). Peak memory was not measured. Other operating systems remain untested.

The following files are exact copies from the existing project's `stata_packages/`, identified through its installation tracking records. This preserves the original estimator defaults rather than downloading newer releases. All accompanying help files and original notices are retained.

| File | Original header |
| --- | --- |
| `r/rdrobust.ado` | *!version 9.1.0  2022-10-28 |
| `r/rdplot.ado` | *!version 9.1.0  2022-10-28 |
| `r/rdbwselect.ado` | *!version 9.1.0  2022-10-28 |
| `b/binscatter.ado` | *! version 7.02  24nov2013  Michael Stepner, stepner@mit.edu |
| `c/coefplot.ado` | *! version 1.8.6  22feb2023  Ben Jann |
| `e/estout.ado` | *! version 3.31  26apr2022  Ben Jann |
| `e/eststo.ado` | *! version 1.1.0  05nov2008  Ben Jann |
| `e/estadd.ado` | *! version 2.3.5  05feb2016  Ben Jann; *  1. estadd and helpers |
| `e/esttab.ado` | *! version 2.1.1  10jun2022  Ben Jann; *! wrapper for estout |

`rdrobust`'s compiled Mata helper files are included with `rdbwselect` and `rdplot`. `binscatter` includes its own `fastxtile` routine. `estout` includes `eststo`, `estadd`, `esttab`, and its installed support files. The master explicitly adds the supplied package folders and reports `which` results. Third-party files are unmodified; their authors retain the rights and notices stated in those files. The package does not include Stata itself.

The default workflow does not install packages or call Python, R, Swift, a shell, or a network service. Optional `preview.tex` requires a LaTeX distribution with `fontenc` (T1), `inputenc`, `geometry`, `graphicx`, `booktabs`, `caption`, `microtype` and `hyperref`; it merely assembles the generated main-text components.

The optional local preview is excluded from the public release. Compile it from the package root using `pdflatex -output-directory=output preview.tex` twice to resolve references. It is a visual check, not a replication dependency.
