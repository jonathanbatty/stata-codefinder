version 17
set matastrict on
mata:

// Function to load text file into an associative array
void cf_load(string scalar codefile, 
             string scalar varname,
		     transmorphic scalar codedef)
{	
	// Declare variables
	string colvector codevector
	string rowvector newvalue
	string scalar oldvalue
	real scalar i
	
	// Load codes from file
	codevector = cat(codefile)
	codevector = strtrim(codevector)
	
	// Populate codedefinitions asarray with keys and values
	// Key: code, value: variable name(s) in rowvector
	for (i = 1; i <= rows(codevector); i++) {
		
		// Check if key already exists in the asarray
		if (asarray(codedef, codevector[i]) == "") {
			
			// If key does not exist, add a new key-value pair to the asarray
			asarray(codedef, codevector[i], varname)
		}
		else {
			// If key exists, append new variable name to the value rowvector
			oldvalue = asarray(codedef, codevector[i])
			newvalue = (oldvalue, varname)
			asarray(codedef, codevector[i], newvalue)
		}
	}
}

// Function to search view of dataset for codes in text files and replace 
// placeholder variables accordingly.
void cf_find(string scalar varname,
             string scalar touse,
		     string scalar resultvars, 
		     transmorphic scalar codedef)
{
	// Declare variables
	string colvector tosearch
	real colvector searchresults
	string rowvector vars, result
	real scalar i, j
	transmorphic scalar resindex
	
	// Tokenize result variables (to hold outputs of search)
	vars = tokens(resultvars)

	// Create a view of each of the result columns (bytes)
	st_view(searchresults = J(0, 0, .), ., vars, touse)
	
	// Map each variable name to the view column id
	resindex = asarray_create()
	for (i = 1; i <= cols(vars); i++) {
		asarray(resindex, vars[i], i)
	}
	
	// DEBUG: show key-value pairs of resindex
	// e.g. key = "MI", value = "1" (index of view column)
	//cols = asarray_keys(resindex)
	//for (i = 1; i <= rows(cols); i++) {
	//	cols[i]
	//	asarray(resindex, cols[i])
	//}
	
	// Create a view of the vector to be searched (strings)
	st_sview(tosearch = J(0, 0, .), ., varname, touse)
	
	// DEBUG: print name of variable and number of items to search
	// varname
	// rows(tosearch)
	
	// Search over the search vector using the associative array; replace value
	// in relevant result column if a match is found.
	// Use of a for loop enables assignment of multiple conditions for a single 
	// code.
	
	for (i = 1; i <= rows(tosearch); i++) { 
		result = asarray(codedef, tosearch[i])
		if (result != "") {
			for (j = 1; j <= rows(result); j++) {
				searchresults[i, asarray(resindex, result[j])] = 1
			}
		}
	}
}
end