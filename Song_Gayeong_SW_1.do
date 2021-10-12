*----------------------------------------------------------
* Impact of Violence on Infant Immunizations in Afghanistan
* Econ 64 Paper Do File.do

* This program replicates the empirical analysis of my
* 	paper studying the relationship between Taliban violence
* 	and infant immunization at week 0 and week 6 after birth
* 	in Afghanistan using DHS (Demographic and Health Surveys)
* 	and GTD (Global Terrorism Database).

* This code sample demonstrates:
* 	1) My ability to produce replication code
* 	2) My ability perform all aspects of a research project

* 3/14/2021
* Gayeong Song, Dartmouth College
*----------------------------------------------------------

* Program Setup
*----------------------------------------------------------
clear
set more off
cap log close
cap clear matrix
log using Afghanistan, text replace

ssc install reghdfe
*----------------------------------------------------------


/// 0. Store Working Directory ///
global dir "/Users/gayeongsong/Desktop/Econ 64 Paper"
cd "$dir"


/// 1. Clean Vaccination Data ///
* "vaccine_at_birth.dta" is the dataset extract from IPUMS DHS
* 	containing information on household characteristics, child characteristics, 
* 	and child vaccination status. 
use "vaccine_at_birth.dta", clear

* Rename some variables
rename geo_af2015 province
rename year sampleyear
rename kidbirthmo_af month
rename kidbirthyr_af year

* Generate dummy variables for vaccination record
gen bcg=.
gen polio0=.
gen dpt1=.
gen polio1=.

replace polio0=0 if vacopv0==10 | vacopv0==97 | vacopv0==98 | vacopv0==99
replace polio0=1 if vacopv0==20 | vacopv0==21 | vacopv0==22 | vacopv0==23 | vacopv0==24 
replace polio1=0 if vacopv1==10 | vacopv1==97 | vacopv1==98 | vacopv1==99
replace polio1=1 if vacopv1==20 | vacopv1==21 | vacopv1==22 | vacopv1==23 | vacopv1==24 
replace dpt1=0 if vacdptpen1==10 | vacdptpen1==97 | vacdptpen1==98 | vacdptpen1==99
replace dpt1=1 if vacdptpen1==20 | vacdptpen1==21 | vacdptpen1==22 | vacdptpen1==23 | vacdptpen1==24 
replace bcg=0 if vacbcg==10 | vacbcg==97 | vacbcg==98 | vacbcg==99
replace bcg=1 if vacbcg==20 | vacbcg==21 | vacbcg==22 | vacbcg==23 | vacbcg==24 

* Generate dummy variable for no vaccination record
gen zerodose =.

replace zerodose=0 if polio0==1 | polio1==1 | dpt1==1 | bcg==1
replace zerodose=1 if zerodose==.

save "dummy_vaccine_at_birth.dta", replace


/// 2. Clean Violence Data ///
* "comprehensive_attacks.dta" is a dataset extract from Global Terrorism Database
* 	containing information on year, month, province, success, attack type,
* 	target type, weapon type, number killed, and number wounded. 
* 	In addition, I converted the Gregorian years to Hijri years using a
* 	Python loop because raw GTD excel file was too big to open in Stata.

* "afg_geography.dta" is a dataset containing population, area, 
* 	and population density at the province level.

// 2.1 Egen-Collapse operations //
* I am creating separate datasets after generating and collapsing variables of
* 	interest for the main empirical design.

* Total number of violent events 
use "comprehensive_attacks.dta", clear
keep if group=="Taliban"

gen event_happened=1

egen totalevent = total(event_happened)
collapse(sum) event_happened, by (year month province)

save "egen_event_count.dta", replace

* Total number of successful violent events
use "comprehensive_attacks.dta", clear
keep if group=="Taliban"

egen successevent = total(success)
collapse(sum) success, by (year month province)

save "egen_success_count.dta", replace

* Success rate & create one file that contains all the "count" data
use "egen_event_count.dta", clear
merge m:1 province year month using "egen_success_count.dta", nogenerate

gen successrate = success/event_happened
gen successful=.
replace successful=0 if success==0
replace successful=1 if successful==.

save "egen_counts.dta", replace

* Total killed 
use "comprehensive_attacks.dta", clear
keep if group=="Taliban"

egen totalkilled = total(nkill)
collapse(sum) nkill, by (year month province)

save "egen_total_killed.dta", replace

* Total wounded
use "comprehensive_attacks.dta", clear
keep if group=="Taliban"

egen totalwounded = total(nwound)
collapse(sum) nwound, by (year month province)

save "egen_total_wounded.dta", replace

* Target type
use "comprehensive_attacks.dta", clear
keep if group=="Taliban"

gen civiliantarg =.
replace civiliantarg=1 if targettype=="Private Citizens & Property"
replace civiliantarg=0 if civiliantarg==.

egen totalciviliantarg = total(civiliantarg)
collapse(sum) civiliantarg, by (year month province)

save "egen_civilian_target.dta", replace

* Bombing
use "comprehensive_attacks.dta", clear
keep if group=="Taliban"

gen bombing=.
replace bombing=1 if attacktype=="Bombing/Explosion"
replace bombing=0 if bombing==.
keep if bombing==1

egen bombcount = count(bombing), by(year month province)
collapse bombcount, by(year month province)

merge m:1 province using "afg_geography.dta"
gen bombdensity = (bombcount / population)
drop _merge

save "egen_bombing.dta", replace

* Standard Deviation 
use "comprehensive_attacks.dta", clear
keep if group=="Taliban"

gen event_happened=1

egen totalevent = total(event_happened)
collapse(sum) event_happened, by (year province month)

egen pmean= mean(event_happened), by (province)
egen pz= sd(event_happened), by (province)
replace pz = (event_happened-pmean)/pz

drop event_happened

save "egen_std.dta", replace


// 2.2 Create Violence and Vaccine Dataset //
use "dummy_vaccine_at_birth.dta", clear

decode province, generate(province_str)
drop province
rename province_str province

merge m:1 province year month using "egen_counts.dta", nogenerate
merge m:1 province year month using "egen_total_killed.dta", nogenerate
merge m:1 province year month using "egen_total_wounded.dta", nogenerate
merge m:1 province year month using "egen_civilian_target.dta", nogenerate
merge m:1 province year month using "egen_bombing.dta", nogenerate
merge m:1 province year month using "egen_std.dta", nogenerate

save "violence_vaccine.dta", replace



/// 3. Empirical Method ///
use "violence_vaccine.dta", clear

// 3.1. Regressions for Zero Dose Children //

// 3.1.1. Generate Variables for Regression //
tab wealthq, gen(wealthdum)
tab educlvl, gen(educlvldum)
tab ethnicityaf, gen(ethnicitydum)

gen lnsuccessrate = ln(successrate)
gen lneventcount = ln(event_happened)
gen lntotalcasualties = ln(totalcasualties)
gen lnbombdensity = ln(bombdensity)

gen conflictdum=.
replace conflictdum=0 if event_happened==.
replace conflictdum=1 if conflictdum==.
replace conflictdum=. if wealthq==.

gen civiliandum=.
replace civiliandum=0 if civiliantarg==0
replace civiliandum=1 if civiliandum==.
replace civiliandum=. if wealthq==.

gen unusualvio =.
replace unusualvio=1 if pz>0.842
replace unusualvio=-1 if pz<-0.842
replace unusualvio=0 if unusualvio==.


// 3.1.2. Regressions //

* Extensive Margin: Violent Event Presence
reg zerodose conflictdum, cluster(clusterno)
outreg2 using paperreg1.doc, replace ctitle(ZeroDose) addtext (Household Control, No, Province FE, No, Year FE, No, Month FE, No)

reg zerodose conflictdum wealthdum2 wealthdum3 wealthdum4 wealthdum5 educlvldum2 educlvldum3 educlvldum4 ethnicitydum1 ethnicitydum2 ethnicitydum3 ethnicitydum4 ethnicitydum5 urban cheb currwork kidsex, cluster(clusterno)
outreg2 using paperreg1.doc, append ctitle(ZeroDose) addtext (Household Control, Yes, Province FE, No, Year FE, No, Month FE, No) 

reghdfe zerodose conflictdum wealthdum2 wealthdum3 wealthdum4 wealthdum5 educlvldum2 educlvldum3 educlvldum4 ethnicitydum1 ethnicitydum2 ethnicitydum3 ethnicitydum4 ethnicitydum5 urban cheb currwork kidsex, absorb(province year month) vce(cluster clusterno strata)
outreg2 using paperreg1.doc, append ctitle(ZeroDose) addtext (Household Control, Yes, Province FE, Yes, Year FE, Yes, Month FE, Yes)

* Intensive Margin: Violent Event Count
reghdfe zerodose lneventcount wealthdum* educlvldum* ethnicitydum* urban cheb currwork kidsex, absorb(province year month) vce(cluster clusterno strata)
outreg2 using paperreg2.doc, replace ctitle(ZeroDose) keep(lneventcount) addtext (Household Control, Yes, Province FE, Yes, Year FE, Yes, Month FE, Yes) 

* Intensive Margin: Unusual Level of Violence
reghdfe zerodose unusualvio wealthdum* educlvldum* ethnicitydum* urban cheb currwork kidsex, absorb(province year month) vce(cluster clusterno strata)
outreg2 using paperreg2.doc, append ctitle(ZeroDose) keep (unusualvio) addtext (Household Control, Yes, Province FE, Yes, Year FE, Yes, Month FE, Yes)

* Violent Event Casualties
reghdfe zerodose totalcasualties wealthdum* educlvldum* ethnicitydum* urban cheb currwork kidsex, absorb(province year month) 
outreg2 using paperreg3.doc, replace ctitle(ZeroDose) keep (totalcasualties) addtext (Household Control, Yes, Province FE, Yes, Year FE, No, Month FE, Yes)

* Civilian Target
reghdfe zerodose civiliandum wealthdum* educlvldum* urban cheb currwork kidsex, absorb(province year month) vce(cluster clusterno strata)
outreg2 using paperreg3.doc, append ctitle(Zero Dose) keep (civiliandum) addtext (Household Control, Yes, Province FE, Yes, Year FE, Yes, Month FE, Yes)

* Objective Success
reghdfe zerodose successful wealthdum* educlvldum*  urban cheb currwork kidsex, absorb(province year month) vce(robust)
outreg2 using paperreg3.doc, append ctitle(Zero Dose) keep (successful) addtext (Household Control, Yes, Province FE, Yes, Year FE, Yes, Month FE, Yes)

* Bombing
reghdfe zerodose bombcount wealthdum* educlvldum* urban cheb currwork kidsex, absorb(year month province) vce(robust) 
outreg2 using paperreg3.doc, append ctitle(ZeroDose) keep (bombcount) addtext (Household Control, Yes, Province FE, Yes, Year FE, Yes, Month FE, Yes)


// 3.2. Regressions for Week 6 Vaccine Returners //

// 3.2.1. Generate Variables for Regression //
use "violence_vaccine.dta", clear

* Following is same from section 3.1.1
tab wealthq, gen(wealthdum)
tab educlvl, gen(educlvldum)
tab ethnicityaf, gen(ethnicitydum)

gen lnsuccessrate = ln(successrate)
gen lneventcount = ln(event_happened)
gen lntotalcasualties = ln(totalcasualties)
gen lnbombdensity = ln(bombdensity)

gen conflictdum=.
replace conflictdum=0 if event_happened==.
replace conflictdum=1 if conflictdum==.
replace conflictdum=. if wealthq==.

gen civiliandum=.
replace civiliandum=0 if civiliantarg==0
replace civiliandum=1 if civiliandum==.
replace civiliandum=. if wealthq==.

gen unusualvio =.
replace unusualvio=1 if pz>0.842
replace unusualvio=-1 if pz<-0.842
replace unusualvio=0 if unusualvio==.

* New variables generated for Week 6 Vaccine Returners
gen bothweek0=.
replace bothweek0=1 if polio0==1 & bcg==1
replace bothweek0=0 if bothweek0==.

gen bothweek6=.
replace bothweek6=1 if polio1==1 & dpt1==1
replace bothweek6=0 if bothweek6==.

gen week0and6=.
replace week0and6=1 if bothweek0==1 & bothweek6==1
replace week0and6=0 if week0and6==.

gen week6month=.
replace week6month=month+1 if month<12
replace week6month=1 if month==12

gen week6year=.
replace week6year=year+1 if week6month==1
replace week6year=year if week6month>1

rename month week0month
rename year week0year
rename week6month month
rename week6year year


// 3.2.2. Regressions //
* Extensive Margin: Violent Event Presence
reghdfe zerodose conflictdum wealthdum* educlvldum* ethnicitydum* urban cheb currwork kidsex, absorb(province year month) vce(cluster clusterno strata)
outreg2 using paperreg4.doc, append ctitle(ZeroDose) addtext (Household Control, Yes, Province FE, Yes, Year FE, Yes, Month FE, Yes) label

* Intensive Margin: Violent Event Count
reghdfe week0and6 lneventcount wealthdum* educlvldum* ethnicitydum* urban cheb currwork kidsex, absorb(province year month) vce(cluster clusterno strata)
outreg2 using paperreg4.doc, append ctitle(Week0and6) keep (lneventcount) addtext (Household Control, Yes, Province FE, Yes, Year FE, Yes, Month FE, Yes)

* Intensive Margin: Unusual Level of Violence
reghdfe week0and6 unusualvio wealthdum* educlvldum* ethnicitydum* urban cheb currwork kidsex, absorb(province year month) vce(cluster clusterno strata)
outreg2 using paperreg4.doc, append ctitle(Week0and6) keep (unusualvio) addtext (Household Control, Yes, Province FE, Yes, Year FE, Yes, Month FE, Yes)

log close
