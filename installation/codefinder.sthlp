{smcl}
{* *! version 1.0  16sep2022}{...}
{viewerjumpto "Syntax" "codefinder##syntax"}{...}
{viewerjumpto "Description" "codefinder##description"}{...}
{viewerjumpto "Options" "codefinder##options"}{...}
{viewerjumpto "Remarks" "codefinder##remarks"}{...}
{viewerjumpto "Examples" "codefinder##examples"}{...}
{viewerjumpto "Acknowledgements" "codefinder##acknowledgements"}{...}
{viewerjumpto "Citation" "codefinder##citation"}{...}
{title:Title}

{phang}
{bf:codefinder} {hline 2} efficient matching of strings to one of more of those contained within text file(s).


{marker syntax}{...}
{title:Syntax}

Perform many-to-many (code) matching using strings stored in .txt files.

{p 8 17 2}
{cmdab:codefinder}
[{varlist}]
{cmd:,} {bf: dataset(string) codefiles(string) id(string)} [{it:options}]

{synoptset 20 tabbed}{...}
{synopthdr}
{synoptline}
{syntab:Main}
{p2coldent:* {opt dataset(string)}}specifes the path to the dataset on which to perform code searching.{p_end}
{p2coldent:* {opt codefiles(string)}}specifies the path(s) to one or more text files containing codes.{p_end}
{p2coldent:* {opt id(string)}}specifies a variable that contains a unique string identifier.{p_end}
{synopt:{opt n_cores(#)}}declares the number of CPU cores with which to perform code searching.{p_end}
{synopt:{opt summary}}prints a summary of the variables created during the codefinding procedure.{p_end}
{synoptline}
{p2colreset}{...}
{p 4 6 2}
* {opt dataset()}, {opt codefiles()} and {opt id()} are required. It is strongly recommended to specify {opt n_cores()}.

{p 4 6 2}
{cmd:if}, {cmd:in}, {cmd:by} and {cmd:fweight}s are not allowed.

{p 4 6 2}
{bf: Note: codefinder} should be used with no data loaded into Stata memory.

{marker description}{...}
{title:Description}

{pstd}
The increasing availability of population-scale, routinely collected healthcare data creates 
significant opportunities to better understand how to improve the delivery of healthcare, but 
also poses major analytic challenges. Frequently, medical diagnoses, medications and procedures
are encoded in these datasets using one or more coding systems, such as: (i) ICD (version 8, 9, 10 
or 11; international or country-specific implementations), (ii) SNOMED-CT, (iii) Read, (iv) DM&D;
(v) gemscript, (vi) BNF codes, etc. These datasets may include such codes in a number of different 
structures, including both long (one code per row) and wide (multiple codes per row; e.g. dx_1, dx_2, 
... , dx_n) format. The long format is more common when handling hospitalisation data (where each
row represents an admission or hospital episode, in which multiple diagnoses may be made, and during 
which multiple procedures may occur).

{pstd}
While some of these encoding systems are hierarchical, extensive string matching is often required 
to translate these coding systems into meaningful clinical concepts. For example, in the ICD-10 
system, a myocardial infarction (MI; heart attack) can be represented by the following codes: I21.0,
I21.1, I21.2, I21.3, I22.4, I21.9, I22.0, I22.1, I22.8, I22.9 and I25.2. In other code systems, MI
is represented by several dozen codes with no clear hierarchy. Including long lists of such codes
in .do files is cumbersome and can make updating the analysis problematic if codelists change.

{pstd}
{bf:codefinder} allows the user to provide a list of codes in a text file (e.g. myocardial_infarction.txt)
that are loaded into Stata. The presence of one or more of these codes in one or more variable (e.g. dx_1, 
dx_2, ... , dx_n) is used to assign a new variable, myocardial_infarction, either 0 or 1. {bf:codefinder} 
returns a Stata dataset containing the original row ID and each new variable. These can be merged with the
original dataset (using: merge 1:1 {it:id} using "filename.dta") if required.

{pstd}
{bf:codefinder} uses optimised Mata functionality (associative arrays) and multiprocessing to search
for codes as efficiently as possible. The use of multiple CPU cores will produce meaningful
improvements in runtime as: (i) the datset size (number of rows), (ii) the number of code-containing 
variables (dx_n), (iii) the number of text files, and (iv) the number of codes in each text files 
increases. Some experimentation may be required to identify the optimum number of CPU cores for a given
use case (also see below). 


{marker options}{...}
{title:Options}

{dlgtab:Main}

{phang}
{opt dataset(string)} is required and specifies path to the dataset on which to perform code searching. Any
data must be cleared from stata prior to running {bf:codefinder} (e.g. using {stata clear:clear}).

{phang}
{opt codefiles(string)} is required and specifies the path to each text file containing codes. The name of 
each text file will form the variable name that stores the results of searching for the codes contained in 
that file.

{phang}
{opt id(string)} is required and specifies a unique identifier for each row of the data. This will be 
required when merging the results of the codefinding procedure with the original data.

{dlgtab:Options}

{marker n_cores()}{...}
{phang}
{opt n_cores(#)}
indicates how many CPU cores should be used for finding codes. It is recommended that n_cores should be set 
to be lower than the number of available CPU cores available to the machine that you are using. 
The number of available CPU cores available can be checked by running: 

{phang3}
{stata display c(processors): display c(processors)}

{phang2}
The maximum number of CPU cores is not limited by the license of the version of Stata being used (e.g. IC/MP etc.).

{marker summary}{...}
{phang}
{opt summary}
indicates that codefinder should print a summary of how many observations contained one or more of the codes contained
within each text file, on completion of codefinding.

{marker remarks}{...}
{title:Remarks}

{pstd}
A summary of benchmarks for {bf:codefinder} are available at: https://github.com/jonathanbatty/stata-codefinder

{marker examples}{...}
{title:Examples}

{pstd}
{it: Example 1:}{break}
codefinder dx_*, dataset("..\data\dataset.dta") codefiles("MI.txt HTN.txt DM.txt") id(unique_id) n_cores(4) summary

{pstd}
{it: Example 2:}{break}
local code_files MI.txt HTN.txt DM.txt OBS.txt DYS.txt ETH.txt{break}
local data "..\data\dataset.dta"
codefinder dx_*, dataset("`data'") codefiles("`code_files'") id(unique_id) n_cores(16)

{marker acknowledgements}{...}
{title:Acknowledgements}

{pstd}
Jonathan Batty received funding from the Wellcome Trust 4ward North Clinical Research Training Fellowship (227498/Z/23/Z; R127002).

{marker citation}{...}
{title:Suggested citation}

{pstd}
Batty, JA. (2024). Stata package ``codefinder'': an implementation of efficient many-to-many string matching in 
Stata (Version 1.0) [Computer software]. https://github.com/jonathanbatty/stata-codefinder


{pstd}
 