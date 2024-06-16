// Get arguments
args chunk filename first_row final_row varlist id codefiles n_cores

// Start log
log using "logs\worker_`chunk'_log.txt", text

// Set each worker to only use a single CPU core
set processors 1

// Set mata properties to favour speed
mata: mata set matafavor speed
mata: mata set matamofirst on

// Load data chunk
use `id' `varlist' in `first_row' / `final_row' using `filename'

// Create empty mata associative array to populate with codes and declare
// what is returned when the queried key does not exist
mata: codedef = asarray_create()
mata: asarray_notfound(codedef, "")

// Strip .txt suffix from file names and use the remainder as the variable name
local resultvars = ""
foreach codefile of local codefiles {
	
	// Strip .txt suffix of each file name to specify variable name
	local varname : subinstr local codefile ".txt" ""
	if (strrpos("`varname'", "\") > 0) {
		local varname = substr("`varname'", strrpos("`varname'", "\") + 1, .)
	}
	
	// Load the code-variable relationships from each text file into the associative array
	mata: cf_load("`codefile'", "`varname'", codedef)
	
	// Generate placeholder variables for each code file
	generate byte `varname' = 0
	
	// Append varname to resultvars
	local resultvars = "`resultvars' `varname'"
}

// Program to execute search function on nonmissing rows of data for each variable
capture program drop findcodes
program define findcodes
	args variable resultvars codedef
	
	// Mark observations that are nonmissing
	marksample touse, strok
	markout `touse' `variable', strok
	
	// Find conditions
	mata: cf_find("`variable'", "`touse'", "`resultvars'", codedef)
end

// Loop over each variable
foreach var of varlist `varlist' {
	findcodes `var' "`resultvars'" codedef
}

// Keep only ID and result variables; save dataset
keep `id' `resultvars'
save "temp\chunk_`chunk'_results.dta", replace
clear

// Creata a new file to flag completion of this chunk
set obs 1
gen byte COMPLETE_FLAG = 1
save "temp\worker_`chunk'_complete.dta", replace

// Check whether all cores are complete (i.e. whether this is the last worker to finish)
local filelist : dir "temp" files "*_complete.dta"
local chunk_count : word count `filelist'

// If this was the last worker to complete, create a new file to flag to the main
// script that execution has completed.
if (`chunk_count' == `n_cores') {
	save "temp\run_complete.dta", replace
}

// Close log
log close
