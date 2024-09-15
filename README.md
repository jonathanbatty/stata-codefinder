![Codefinder](assets/package.png?raw=true "Codefinder")

![StataMin](https://img.shields.io/badge/stata-18-blue) ![issues](https://img.shields.io/github/issues/jonathanbatty/stata-codefinder) ![license](https://img.shields.io/badge/license-MIT-green) ![version](https://img.shields.io/github/v/release/jonathanbatty/stata-codefinder) ![release](https://img.shields.io/github/release-date/jonathanbatty/stata-codefinder) ![Stars](https://img.shields.io/github/stars/jonathanbatty/stata-codefinder) 

---

[Installation](#Installation) | [Syntax](#Syntax) | [Examples](#Examples) | [Feedback](#Feedback) | [Change log](#Change-log) | [Roadmap](#Roadmap)

---

# Codefinder for Stata
(v1.00, 14 Jun 2024)

This repository contains the code required to install and run `codefinder`, a package that uses multiprocessing, associative arrays and optimised Mata functions to speed up many-to-many string matching in Stata. This can be used to identify the presence of lists of codes (e.g. ICD, SNOMED-CT, Read/CTV3, Emis, etc) in variables containing data in string format. 

At present, `codefinder` is in a reasonably developnmental state and has only been tested on Windows (11). Over the coming weeks, it will be fully tested on Windows 10 and 11, MacOS and UNIX (including HPC) machines, prior to release via SSC.

## Installation
The package can be installed from GitHub using `net install`:

```
net install codefinder, from("https://raw.githubusercontent.com/jonathanbatty/stata-codefinder/main/installation/") replace

```

## Syntax
Codefinder should be used with no data open in Stata. The syntax for `codefinder` is as follows:

```
codefinder varstosearch, dataset() codefiles() id() [options]

[options] = n_cores() summary
```

See the help file using `help codefinder` for full details of each option.

The basic usage is as follows:

```
codefinder dx*, dataset(".\data\patient_data.dta") codefiles("hypertension.txt diabetes.txt") id(id_var) n_cores(16)
```

Whereby the variables `dx*` (e.g. dx1, dx2, dx3, ... , dx<sub>n</sub>) present in `patient_data.dta` will be searched for the diagnosis codes (strings) present in `hypertension.txt` and `diabetes.txt` (one code per line in each file). Each row of data should be identified using a unique identifier, id_var. `Codefinder` will run the string matching procedure using 16 CPU cores, in this example. It will return a dataset in memory that includes id_var and a variable to indicate the presence of one or more codes from each text file in each initial observation (i.e. `dx*` in this case).

## Feedback
Please [open an issue](https://github.com/jonathanbatty/stata-codefinder/issues) to report errors, suggest feature enhancements, and/or make any other requests. 

## Change Log
**v1.01 (16/06/24)**
 - Minor bug fixes: installation now works with a single command.

**v1.00 (14/06/24)**
 - Initial release.
   


## Roadmap
- Test on Unix / Mac machines.
- Improvements in error reporting functionality: workers to flag errors to main Stata instance, which should handle these appropriately.
- Further incremental improvements to speed and stability.

## Acknowledgements
JB received funding from the Wellcome Trust 4ward North Clinical Research Training Fellowship (227498/Z/23/Z; R127002). 

## Suggested Citation
Batty, J. A. (2024). Stata package ``codefinder'': efficient many-to-many string searching in Stata using multiprocessing (Version 1.0) [Computer software]. https://github.com/jonathanbatty/stata-codefinder
