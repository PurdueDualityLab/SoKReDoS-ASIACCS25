# SoKReDoS-ASIACCS25

[![DOI](https://zenodo.org/badge/doi/10.5281/zenodo.15515222.svg)](https://doi.org/10.5281/zenodo.15515222)

This repository bundles the data, scripts, and results used in our "SoK: A Literature and Engineering Review of Regular Expression Denial of Service (ReDoS)" paper in ASIA CCS'25.

## Directory layout

- `LICENSE`: The license file for this repository. The contents of this artifact are licensed under the GNU General Public License v3.0. The paper itself is licensed under the Creative Commons Attribution 4.0 International License (CC BY 4.0).
- `paper.pdf`: PDF our manuscript accepted at ASIA CCS'25.
- `cve-analysis/`: Data and helper scripts for the CVE study, which shows to prevelance of ReDoS vulnerabilities compared to other types of vulnerabilities (§2.3.2).
- `regex-engine-analysis/`: Contains the super-linear regex corpus with corresponding input strings, experiment setups, and results quantifying and verifiying the ReDoS defenses across nine programming languages (§4).
- `github-discussions/`: Raw issue/PR threads where developers discuss ReDoS vulnerabilities and GitHub crawler to collect them (Appendix E).

More detailed information can be found in the respective directories' `README.md` files.

## Citation

```bibtex
@inproceedings{10.1145/3708821.3733912,
    title={SoK: A Literature and Engineering Review of Regular Expression Denial of Service (ReDoS)}, 
    author={Masudul Hasan Masud Bhuiyan and Berk Çakar and Ethan H. Burmane and James C. Davis and Cristian-Alexandru Staicu},
    year = {2025},
    isbn = {9798400714108},
    publisher = {Association for Computing Machinery},
    address = {New York, NY, USA},
    url = {https://doi.org/10.1145/3708821.3733912},
    doi = {10.1145/3708821.3733912},
    booktitle = {Proceedings of the 20th ACM Asia Conference on Computer and Communications Security},
    numpages = {17},
    keywords = {Systematization of knowledge (SoK), regular expression denial of service (ReDoS), regex engines, ReDoS defenses},
    location = {Hanoi, Vietnam},
    series = {ASIA CCS '25}
}
```
