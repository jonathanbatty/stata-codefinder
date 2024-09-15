capture program drop codefinder
program define codefinder
	syntax anything(name = searchvars),   /// Variables to search for codes present in .txt files
		   dataset(string)                /// Specifies the path to the dataset to be searched
	       codefiles(string)              /// Specifies the path to the .txt files containing codes to search for
		   id(string)                     /// Specifies the unique identifier in the dataset
	       [                              ///
		      n_cores(integer 1)          /// Specify number of cores with which to run the finding algorithm
			  summary                     /// Provides a summary of the totals of each codelist searched for
		   ] 
	
	// Set niceness = 10 to free up memory immediately
	quietly set niceness 10
	
	// Set mata properties to favour speed
	mata: mata set matafavor speed
	mata: mata set matamofirst on
	
	// Check no data is presently loaded into Stata
	capture assert _N == 0
	if _rc != 0 {
		noisily display as error "Please {stata clear all:clear all} data from Stata before running codefinder."
		error 498
	}
		
	// Check n_cores < number of available processors (regardless of Stata license)
	if (`n_cores' > `c(processors)') {
		noisily display as error "Warning: number of cores is set to more than those available on this machine."
		noisily display as error "Recommended maximum number of cores = number available - 1."
		noisily display as error "In this case, this will be: " `c(processors)' " - 1 = " `= c(processors) - 1' " cores."
		error 498
	}
	
	// Import mata functions and compile these to a local .mo file (which the 
	// workers can then directly access)
	quietly findfile "codefinder.mata"
	run "`r(fn)'"
	quietly mata: mata mosave cf_load(), replace
	quietly mata: mata mosave cf_find(), replace
	
	if (`n_cores' > 1) {
		
		// Get path to Stata
		local executable : dir "`c(sysdir_stata)'" files "Stata*-*.exe", respect
		foreach exe in `executable' {
			if strpos("`exe'", "old") == 0 {
				local currentstata_exe `exe'
			} 
		}	
		if (`"`statadir'"' == "") {
			local statadir `"`c(sysdir_stata)'`currentstata_exe'"'
		}
		capture confirm file `"`c(sysdir_stata)'`currentstata_exe'"'
		if (_rc != 0) {
			noisily display as error "Automated method to detect Stata directory failed."
			error 498
		}
		
		// Create temporary storage to hold result files
		capture mkdir temp
		capture mkdir logs
		
		// Create local variables for calulcations below
		quietly describe using "`dataset'"
		local numrows = `r(N)'
		local chunksize = ceil(`numrows' / `n_cores')
		
		// Generate local values for first and last row
		forvalues i = 1 / `n_cores' {
			
			// Calculate first and last rows to be included in each chunk
			local first_row_`i' = (`i' - 1) * `chunksize' + 1
			local final_row_`i' = min(`first_row_`i'' + `chunksize' - 1, `numrows')
		}
		
		// Divide input file into n temporary subfiles based on number of rows and 
		// number of cores to use.
		noisily display "Running codefinder using " `n_cores' " cores..."
		
		// Evaluate which OS is present and assign appropriate parameters for winexec
		// /e or -e - set background (batch) mode and log in plain text without prompting when Stata command has completed
		// /q or -q - suppress logo and initialization messages
		// /i - suppress Stata application icon in the Windows taskbar
	
		if "`c(os)'" == "Windows" {
			local winexec_opts "/e /q /i"
		}
		else if "`c(os)'" == "MacOSX" {
			local winexec_opts "-e -q"
		}
		else if "`c(os)'" == "Unix" {
			local winexec_opts "-q"
		}
		
		// Create a new stata process for each chunk; pass necessary arguments
		quietly findfile "cf_worker.ado"
		local worker = "`r(fn)'"
		forvalues i = 1 / `n_cores' {		
			winexec `statadir' `winexec_opts' do "`worker'" "`i'" "`dataset'" `first_row_`i'' `final_row_`i'' "`searchvars'" "`id'" "`codefiles'" `n_cores'
		}
		
		// Initialise local to store job completion status
		local jobscomplete = 0
		
		// Poll file completion log for full job completion every n seconds
		while (`jobscomplete' != 1) {
			
			// Poll for completion
			sleep 250
					
			// When all jobs are finished, exit loop (pausing to allow residual file writing)
			capture confirm file "temp/run_complete.dta"
			if (_rc == 0) {
				local jobscomplete = 1
			}
		}
				
		// Append results files together
		if (`n_cores' == 1) {
			use "temp\chunk_1_results.dta", clear
		}
		else {
			local chunks : dir temp files "chunk_*_results.dta"
			quietly cd temp
			append using `chunks'
			quietly cd ../
		}

		// Delete temporary directory at completion of code (using OS-agnostic method)

		// First, ./temp and ./logs folders must both be emptied
		// Get contents of each folder and erase file-by-file
		local tempfiles : dir temp files "*"
		foreach file of local tempfiles {
        	erase "temp\\`file'"
		}

		local logfiles : dir logs files "*"
		foreach file of local logfiles {
			erase "logs\\`file'"
		}

		// Delete empty directories
		rmdir temp
		rmdir logs
				
	} // End of multiprocessing
	else {
		
		// Display message to the screen
		noisily display "Running codefinder in single core mode..."
		
		// Load data chunk
		use `id' `searchvars' using `dataset'

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
		
		// Loop over each variable
		foreach var of varlist `searchvars' {
			findcodes `var' "`resultvars'" codedef
		}

		// Keep only ID and result variables; save dataset
		keep `id' `resultvars'
		
	} // End of single core processing
	
	// Delete compiled mata code files
	erase "cf_load.mo"
	erase "cf_find.mo"
	
	// Print summary of codefinding if user specifies this
	if "`summary'" == "summary" {
		
		noisily display as result _newline "Summary of code searching:" _newline
		noisily display as result "{lalign 14:File name}{lalign 20: Variable name}{lalign 35:Number (%) of rows with ≥ 1 code}"
		noisily display as result "{hline 70}"
		
		local resultvars = subinstr("`codefiles'", ".txt", "", .)
		local n : word count `resultvars'
		
		forvalues i = 1 / `n' {
			
			// Get relevant variable name / text file
			local filename : word `i' of `codefiles'
			local resultvar : word `i' of `resultvars'
			
			// Label result variables with the name of the text file
			label variable `resultvar' "`filename'"
			
			// Calculate and display summary statistics
			quietly count if `resultvar' == 1
			local countpresent = `r(N)'
			local percentagepresent = (`countpresent' / `numrows') * 100
			
			noisily display as result "{lalign 14:`filename'}{lalign 14: `resultvar'}      " %12.0fc `countpresent' " (" %2.1f `percentagepresent' "%)" 
		}
	}
	
	// Reset niceness to default
	quietly set niceness 5
	
end


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
