*-----------------------------------------------------------------------
* Creating dataset of p-values and coefficients for independent variables
* 	of lagged and non-lagged, fixed effects and random effects 
* 	academic performance models
* Sample Code 1.do

* I created this program as part of my internship at the American
* 	Enterprise Institute. My PI, Dr. Eberstadt, was interested in 
* 	understanding which model and which covariate displayed the strongest
* 	the strongest correlation with gdp. 

* This code sample demonstates:
* 	1) my coding style in Stata
* 	2) my problem-solving ability
* 		(I discovered tempfile and tuples while doing this task)

* July 2021
* Gayeong Song, American Enterprise Institute
*-----------------------------------------------------------------------

* Program Setup
*----------------------------------------------------------
clear
set more off
cap log close
cap clear matrix

* Install tuples
ssc install tuples
*----------------------------------------------------------


/// Store working directory ///
global dir "/Users/gayeongsong/Documents/GitHub/ONA-Project/"
cd "$dir"

use "Merged Data/Data_Merge.dta", clear


/// Set directory ///
cd "$dir/Regressions"

/// Prepare dataset for regression ///
* Set id and year variables
xtset iso3 year

/// Generate variables for regression (PPP) ///
gen lngdp = ln(wdi_gdpcappppcon2017)
label var lngdp "Log GDP per Capita (PPP, 2017 USD)"

/// Standardize data for p-value and coefficient collection ///
foreach var of varlist pirls_* pisa_* timss_* hlo_* NIQ_* lngdp bl_yr_sch2564 ///
	witt_mys_2564 bl_yr_sch_15_1950 wdi_lifexp wdi_popurb hf_efiscore ///
	latcarib eastasia ussr {
	bysort year: egen `var'_2 = std(`var')
	replace `var' = `var'_2
	drop `var'_2
}

/// Create lagged variables for regressions ///
foreach var of varlist lngdp bl_yr_sch2564 witt_mys_2564 bl_yr_sch_15_1950 ///
	wdi_lifexp wdi_popurb hf_efiscore latcarib eastasia ussr {
	bysort iso3 (year): gen `var'_L10 = `var'[_n-10]
}

/// Generate a temporary file to store p-values ///
tempfile p_file
tempname p_hold
postfile `p_hold' str32 varname str32 y str32 model_type float model float coef float pvalue float ar2 float rmse using `p_file', replace

/// Academic Performance Models ///
local p_i=0

foreach dep of varlist pisa_* pirls_* timss_* hlo_* NIQ_* {
	
	* OLS Pooled Regression, no lag
	tuples lngdp bl_yr_sch2564 witt_mys_2564 bl_yr_sch_15_1950 ///
	wdi_lifexp wdi_popurb hf_efiscore latcarib eastasia ussr, varlist ncr
	forvalues i = 1/`ntuples' {
		quietly regress `dep' `tuple`i''
		local ++p_i
		foreach var of varlist `tuple`i'' {
			quietly test `var'
			local v_p=r(p)
			local v_c=_b[`var']
			local ar2 = e(r2_a)
			local rmse = e(rmse)
			post `p_hold' ("`var'") ("`dep'") ("Pooled, 0-Year Lag") (`p_i') ///
			(`v_c') (`v_p') (`ar2') (`rmse')
		}
	}
	* OLS Pooled Regression, 10-year lag
	tuples lngdp_L10 bl_yr_sch2564_L10 witt_mys_2564_L10 bl_yr_sch_15_1950_L10 ///
	wdi_lifexp_L10 wdi_popurb_L10 hf_efiscore_L10 latcarib_L10 eastasia_L10 ///
	ussr_L10, varlist ncr
	forvalues i = 1/`ntuples' {
		quietly regress `dep' `tuple`i''
		local ++p_i
		foreach var of varlist `tuple`i'' {
			quietly test `var'
			local v_p=r(p)
			local v_c=_b[`var']
			local ar2 = e(r2_a)
			local rmse = e(rmse)
			post `p_hold' ("`var'") ("`dep'") ("Pooled, 10-Year Lag") (`p_i') ///
			(`v_c') (`v_p') (`ar2') (`rmse')
		}
	}
	* Fixed Effects, no lag
	tuples lngdp bl_yr_sch2564 witt_mys_2564 bl_yr_sch_15_1950 ///
	wdi_lifexp wdi_popurb hf_efiscore latcarib eastasia ussr, varlist ncr
	forvalues i = 1/`ntuples' {
		quietly xtreg `dep' `tuple`i'', fe vce(cluster iso3)
		local ++p_i
		foreach var of varlist `tuple`i'' {
			quietly test `var'
			local v_p=r(p)
			local v_c=_b[`var']
			local ar2 = e(r2_o)
			local rmse = e(rmse)
			post `p_hold' ("`var'") ("`dep'") ("Fixed Effects, 0-Year Lag") ///
			(`p_i') (`v_c') (`v_p') (`ar2') (`rmse')
		}
	}
	* Fixed Effects, 10-year lag
	tuples lngdp_L10 bl_yr_sch2564_L10 witt_mys_2564_L10 bl_yr_sch_15_1950_L10 ///
	wdi_lifexp_L10 wdi_popurb_L10 hf_efiscore_L10 latcarib_L10 eastasia_L10 ///
	ussr_L10, varlist ncr
	forvalues i = 1/`ntuples' {
		quietly xtreg `dep' `tuple`i'', fe vce(cluster iso3)
		local ++p_i
		foreach var of varlist `tuple`i'' {
			quietly test `var'
			local v_p=r(p)
			local v_c=_b[`var']
			local ar2 = e(r2_o)
			local rmse = e(rmse)
			post `p_hold' ("`var'") ("`dep'") ("Fixed Effects, 10-Year Lag") ///
			(`p_i') (`v_c') (`v_p') (`ar2') (`rmse')
		}
	}
	* Random effects, no lag
	tuples lngdp bl_yr_sch2564 witt_mys_2564 bl_yr_sch_15_1950 ///
	wdi_lifexp wdi_popurb hf_efiscore latcarib eastasia ussr, varlist ncr
	forvalues i = 1/`ntuples' {
		quietly xtreg `dep' `tuple`i'', re vce(cluster iso3)
		local ++p_i
		foreach var of varlist `tuple`i'' {
			quietly test `var'
			local v_p=r(p)
			local v_c=_b[`var']
			local ar2 = e(r2_o)
			local rmse = e(rmse)
			post `p_hold' ("`var'") ("`dep'") ("Random Effects, 0-Year Lag") ///
			(`p_i') (`v_c') (`v_p') (`ar2') (`rmse')
		}
	}
	* Random effects, 10-year lag
	tuples lngdp_L10 bl_yr_sch2564_L10 witt_mys_2564_L10 bl_yr_sch_15_1950_L10 ///
	wdi_lifexp_L10 wdi_popurb_L10 hf_efiscore_L10 latcarib_L10 eastasia_L10 ///
	ussr_L10, varlist ncr
	forvalues i = 1/`ntuples' {
		quietly xtreg `dep' `tuple`i'', re vce(cluster iso3)
		local ++p_i
		foreach var of varlist `tuple`i'' {
			quietly test `var'
			local v_p=r(p)
			local v_c=_b[`var']
			local ar2 = e(r2_o)
			local rmse = e(rmse)
			post `p_hold' ("`var'") ("`dep'") ("Random Effects, 10-Year Lag") ///
			(`p_i') (`v_c') (`v_p') (`ar2') (`rmse')
		}
	}
}
postclose `p_hold'

/// Generate dta files using the temporary files ///
use `p_file', clear
save "pvalues.dta", replace
