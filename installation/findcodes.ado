capture program drop findcodes
program define findcodes
	args variable resultvars codedef
	
	// Mark observations that are nonmissing
	marksample touse, strok
	markout `touse' `variable', strok
	
	// Find conditions
	mata: cf_find("`variable'", "`touse'", "`resultvars'", codedef)
end