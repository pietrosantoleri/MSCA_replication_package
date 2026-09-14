# Third-party commands

Files in `stata_packages/` are unmodified copies of the versions used in the original workflow. Their authorship, help files and embedded notices are retained. They are excluded from the project MIT licence.

| Command family | Attribution | Local notice / information |
| --- | --- | --- |
| rdrobust, rdplot, rdbwselect and Mata support | Sebastian Calonico, Matias D. Cattaneo, Max H. Farrell and Rocío Titiunik, as credited by individual files | GPL-3.0; [upstream notice](third_party_licenses/rdrobust.txt), [full licence](third_party_licenses/GPL-3.0.txt) |
| binscatter, including fastxtile | Michael Stepner | CC0 1.0 notice embedded in `stata_packages/b/binscatter.ado` |
| coefplot | Ben Jann | MIT; [licence](third_party_licenses/coefplot.txt) |
| estout family (eststo, estadd and support) | Ben Jann | MIT; [licence](third_party_licenses/estout.txt) |

Licence texts were retrieved from the authors’ official repositories on 14 September 2026: [rdrobust](https://github.com/rdpackages/rdrobust/blob/main/LICENSE.md), [coefplot](https://github.com/benjann/coefplot/blob/master/LICENSE), [estout](https://github.com/benjann/estout/blob/master/LICENSE). The full GPL-3.0 text comes from the Free Software Foundation. Original command files are supplied as source, with compiled Mata support where required. Licence retrieval did not update any command version.

The full supplied families are retained to avoid removing support commands called indirectly.

Bundled command versions are recorded in the individual ado-file headers. Stata itself is proprietary and is not distributed here.
