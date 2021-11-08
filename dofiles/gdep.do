clear all
global ipums "E:\Dropbox\Research\Ding's Proposal\WorkingFile\empirical_v2"
global tempdata "E:\Dropbox\Research\Ding's Proposal\WorkingFile\empirical_v2\temp_data"
global cw_ipums "E:\Dropbox\Research\Ding's Proposal\WorkingFile\empirical_v2\cw_ipums"
global dofiles "E:\Dropbox\Research\Ding's Proposal\WorkingFile\empirical_v2\dofiles"
global datafiles "E:\Dropbox\Research\Ding's Proposal\WorkingFile\empirical_v2\datafiles"
cd "$datafiles"

**********generate controls in 2006**********
use imputed_acs06,clear
replace occsoc="999920" if occsoc=="     0"
g emp_temp=0
replace emp_temp=1 if empstat==1
egen emp_total=total(emp_temp*perwt)
bys occsoc czone2000: egen emp_lm06=total(emp_temp*perwt)
bys occsoc czone2000: egen lm_pop=total(perwt)
*** since some individuals report their occupations even though they are unemployed or not in LF
*** therefore lm_pop is larger than emp_lm06 for most of the markets
*** my controls are built on properties of each market rather than properties of employed in each market
bys czone2000: egen cz_pop=total(perwt)
g ln_lm_pop=ln(lm_pop)
g ln_cz_pop=ln(cz_pop)
*sex
replace sex=0 if sex==2
bys occsoc czone2000: egen lm_male=total(sex*perwt)
g share_male=lm_male/lm_pop
*age
g elder=(age>65)
bys occsoc czone2000: egen lm_elder=total(elder*perwt)
g share_elder=lm_elder/lm_pop
*education
tab educd
tab race
g nocoll=(educd<=62)
bys occsoc czone2000: egen lm_nocoll=total(nocoll*perwt)
g share_nocoll=lm_nocoll/lm_pop
g somecoll=(educd==65)
bys occsoc czone2000: egen lm_somecoll=total(somecoll*perwt)
g share_somecoll=lm_somecoll/lm_pop
g collprof=0
replace collprof=1 if educd==101 | educd==115
bys occsoc czone2000: egen lm_collprof=total(collprof*perwt)
g share_collprof=lm_collprof/lm_pop
g mastdoc=0
replace mastdoc=1 if educd==114 | educd==116
bys occsoc czone2000: egen lm_mastdoc=total(mastdoc*perwt)
g share_mastdoc=lm_mastdoc/lm_pop
*race
g race_new=0 if race==1
replace race_new=1 if race!=1
bys occsoc czone2000: egen lm_nonwhite=total(race_new*perwt)
g share_nonwhite=lm_nonwhite/lm_pop
*industry structure
g manuf=0
replace manuf=1 if substr(indnaics,1,1)=="3"
bys occsoc czone2000: egen lm_manuf=total(emp_temp*manuf*perwt)
g share_emp_manuf=lm_manuf/emp_lm06
bys occsoc czone2000:keep if _n==1
keep occsoc czone2000 ln_lm_pop lm_pop ln_cz_pop cz_pop share_male share_elder share_nocoll share_somecoll share_collprof share_mastdoc share_nonwhite share_emp_manuf
drop if occsoc=="999920" | occsoc=="559830"
save lm_demographic,replace
	*** make it a balanced panel
	use "$cw_ipums\cw_cty_cz2000",clear
	drop FIPS
	bys czone2000: keep if _n==1
	expand 446
	bys czone2000: g row=_n
	merge m:1 row using "$tempdata\marinew_soclist"
	drop _merge row
	merge 1:1 czone2000 occsoc using lm_demographic
	*** 108738 missing markets
	*foreach x of varlist share_*{
	*replace `x'=0 if missing(`x')
	*}
	drop _merge
save lm_demographic,replace



************************************************
**********generate dependent variables**********
************************************************

use imputed_acs14,clear
replace occsoc="999920" if occsoc=="     0"
g emp_temp=0
replace emp_temp=1 if empstat==1
egen emp_total=total(emp_temp*perwt)
bys occsoc czone2000: egen emp_lm14=total(emp_temp*perwt)
bys czone2000: egen cz_pop=total(perwt)
*bys occsoc czone2000: egen lm_pop14=total(perwt)
   ***** in order to check the size of non-merged LM
g emp_lm14_ratio=emp_lm14/cz_pop
	*** there are certain employed reporting their wages being 0
	count if emp_temp==1 & incwage==0
	*** 191,677
	*** I have to make sure they are not counted in the denominator when calculating average wage wage_lmxx
	g dummy_emp_0wage=!(emp_temp==1 & incwage==0)
bys occsoc czone2000: egen wage_tot=total(incwage*perwt*emp_temp)
bys occsoc czone2000: egen emp_lm14_forwage=total(emp_temp*perwt*dummy_emp_0wage)

g wage_lm14=wage_tot/emp_lm14_forwage
g lnwage_lm14=ln(wage_lm14)
keep occsoc czone2000 emp_lm14 emp_lm14_ratio wage_lm14 lnwage_lm14
bys occsoc czone2000: keep if _n==1
drop if occsoc=="999920" | occsoc=="559830"
	*** why are there missing average wages?
		count if missing(wage_lm14)
		*15,120
		count if emp_lm14==0
		*15,120
		*** there are 15120 markets that have 0 emp
save dep14,replace
	*** 203164 obs(occ-by-cz markets)
	
	*** make it a balanced panel
	use "$cw_ipums\cw_cty_cz2000",clear
	drop FIPS
	bys czone2000: keep if _n==1
	expand 446
	bys czone2000: g row=_n
	merge m:1 row using "$tempdata\marinew_soclist"
	drop _merge row
	merge 1:1 czone2000 occsoc using dep14
	*** 113050 missing markets
	*replace emp_lm14=0 if missing(emp_lm14)
	*replace emp_lm14_ratio=0 if missing(emp_lm14_ratio)
	*replace wage_lm14=0 if missing(wage_lm14)
	drop _merge
save dep14,replace


use imputed_acs06,clear
replace occsoc="999920" if occsoc=="     0"
g emp_temp=0
replace emp_temp=1 if empstat==1
egen emp_total=total(emp_temp*perwt)
bys occsoc czone2000: egen emp_lm06=total(emp_temp*perwt)
bys czone2000: egen cz_pop=total(perwt)
		*** generate working age population
g workage_dummy=0
replace workage_dummy=1 if age>=18 & age<=64
bys czone2000: egen cz_workpop=total(perwt*workage_dummy)
		*** end
*bys occsoc czone2000: egen lm_pop=total(perwt)
   ***** in order to check the size of non-merged LM
g emp_lm06_ratio=emp_lm06/cz_pop
	*** there are certain employed reporting their wages being 0
	count if emp_temp==1 & incwage==0
	*** 191,677
	*** I have to make sure they are not counted in the denominator when calculating average wage wage_lmxx
	g dummy_emp_0wage=!(emp_temp==1 & incwage==0)
bys occsoc czone2000: egen wage_tot=total(incwage*perwt*emp_temp)
bys occsoc czone2000: egen emp_lm06_forwage=total(emp_temp*perwt*dummy_emp_0wage)

g wage_lm06=wage_tot/emp_lm06_forwage

g lnwage_lm06=ln(wage_lm06)
keep occsoc czone2000 emp_lm06 emp_lm06_ratio wage_lm06 lnwage_lm06 cz_pop cz_workpop
bys occsoc czone2000: keep if _n==1
drop if occsoc=="999920" | occsoc=="559830"
	*** why are there missing average wages?
		count if missing(wage_lm06)
		*14018
		count if emp_lm06==0
		*14018
		*** there are 14018 markets that have 0 emp
save dep06,replace
	
	*** 207476 obs *******important number
	
	*** make it a balanced panel
	use "$cw_ipums\cw_cty_cz2000",clear
	drop FIPS
	bys czone2000: keep if _n==1
	expand 446
	bys czone2000: g row=_n
	merge m:1 row using "$tempdata\marinew_soclist"
	drop _merge row
	merge 1:1 czone2000 occsoc using dep06
	*** 108738 missing markets
	*replace emp_lm06=0 if missing(emp_lm06)
	*replace emp_lm06_ratio=0 if missing(emp_lm06_ratio)
	*replace wage_lm06=0 if missing(wage_lm06)
	drop _merge
save dep06,replace



**********************************************************
********************merge all the data********************
**********************************************************
use dep06,clear
merge 1:1 occsoc czone2000 using dep14
	*** all merged
	drop _merge

sum emp_lm06 if !missing(emp_lm06) & missing(emp_lm14)
/*
    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
    emp_lm06 |     39,344    56.30921    92.76831          0   1543.792
*/
sum emp_lm14 if missing(emp_lm06) & !missing(emp_lm14)
/*
    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
    emp_lm14 |     35,032    54.28861     95.3407          0   1905.923
*/
sum emp_lm06 if !missing(emp_lm06) & !missing(emp_lm14)
/*
    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
    emp_lm06 |    168,132    831.7918    3462.302          0     215686
*/
sum emp_lm14 if !missing(emp_lm06) & !missing(emp_lm14)
/*
    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
    emp_lm14 |    168,132    871.1947    3768.284          0     254073
*/
	*** clearly the non-merged market are the ones with relatively small labor size
	
*drop if missing(emp_lm06)
	*** trim all jobs that were not there in 2006, since market level characteristics (controls) are built from 2006
replace emp_lm14=0 if missing(emp_lm14) & !missing(emp_lm06)
	*** assume these 39344 markets that were present in 2006 but absent in 2014 are totally replaced by machine (or just gone)
replace emp_lm14_ratio=0 if missing(emp_lm14_ratio) & !missing(emp_lm06_ratio)

mmerge czone2000 occsoc using lm_demographic,type(1:1)
	count if missing(share_male)
	*** 108738 obs with missing controls (who neither have no emp_lm14)
	drop _merge
mmerge czone2000 occsoc using hhi_2016new,type(1:1)
	count if missing(hhi_new)
	*** 129652 obs with missing hhi; 186562 obs with non-missing hhi
	*** As I build my main sample based on 2006 ACS, so check the following
	count if !missing(hhi_new) & !missing(emp_lm06)
	*** 149546 obs with both hhi and emp_lm06 (therefore employment gap)
	sum emp_lm06 if missing(hhi_new)
	/*
		Variable |        Obs        Mean    Std. Dev.       Min        Max
	-------------+---------------------------------------------------------
		emp_lm06 |     57,930    59.67432    139.4648          0   7615.417
	*/
	sum emp_lm06 if !missing(hhi_new) & !missing(emp_lm06)
	/*
		Variable |        Obs        Mean    Std. Dev.       Min        Max
	-------------+---------------------------------------------------------
		emp_lm06 |    149,546    926.8674    3659.283          0     215686
	*/

	sum emp_lm14 if missing(hhi_new) & !missing(emp_lm06)
	/*
		Variable |        Obs        Mean    Std. Dev.       Min        Max
	-------------+---------------------------------------------------------
		emp_lm14 |     57,930    42.56833      126.11          0       4958
	*/
	sum emp_lm14 if !missing(hhi_new) & !missing(emp_lm06)
	/*
		Variable |        Obs        Mean    Std. Dev.       Min        Max
	-------------+---------------------------------------------------------
		emp_lm14 |    149,546    962.9795    3985.462          0     254073
	*/
	sum hhi_new if !missing(hhi_new) & !missing(emp_lm06)
	/*
		Variable |        Obs        Mean    Std. Dev.       Min        Max
	-------------+---------------------------------------------------------
		 hhi_new |    149,546    5264.327    3371.551   3.550837      10000
	*/
	sum hhi_new if !missing(hhi_new) & missing(emp_lm06)
	/*
		Variable |        Obs        Mean    Std. Dev.       Min        Max
	-------------+---------------------------------------------------------
		 hhi_new |     37,016    7655.468    2679.165   94.04444      10000
	*/
	drop _merge
	
*** now generate employment-to-working-age-population ratio
	g d_emp_0614=emp_lm14-emp_lm06
	*** 108738 missing obs, same to the number of missing emp_lm14 after 
	*** assuming 39344 markets changed from presence(1) in 2006 to absence(0) in 2014
	g d_emp_ratio_0614=emp_lm14_ratio-emp_lm06_ratio
	*** 108738 missing obs
	g emp06_workpop06_ratio=emp_lm06/cz_workpop
	*** 108738 missing obs
	g emp14_workpop06_ratio=emp_lm14/cz_workpop
	*** 108738 missing obs
	g d_emp_workpop06_ratio=(emp14_workpop06_ratio-emp06_workpop06_ratio)*1000
	*** 108738 missing obs
	
	*** generate CZ level change for figures
	bys czone2000: egen emp06_workpop06_ratio_cz=total(emp06_workpop06_ratio)
	bys czone2000: egen emp14_workpop06_ratio_cz=total(emp14_workpop06_ratio)
	g d_emp_workpop06_ratio_cz=emp14_workpop06_ratio_cz-emp06_workpop06_ratio_cz
	
*** then merge robot exposure to the main data
	mmerge czone2000 occsoc using er_us_emp06, type(1:1)
	drop _merge
	mmerge czone2000 occsoc using er_eu, type(1:1)
	drop _merge
	mmerge occsoc using rti_soc,type(n:1)
	*** rti not reported for all the millitary jobs 551010, 552010, 553010
	drop _merge
***last, keep the markets with nonmissing d_emp* (or d_wage*) and hhi
	preserve
		keep if !missing(d_emp_0614) & !missing(hhi_new)
		*** 149546 obs left
		drop if emp_lm06==0
		*** drop 6766 obs who had fake markets in 2006
		*** 142780 obs left
		count if er_us_emp06==0
		*** 0 
		count if er_eu==0
		*** 2,165
		drop if er_eu==0
		*** 140615 obs left
		save dep_emp0614,replace 
	restore

	
	preserve
		keep if !missing(wage_lm06) & !missing(wage_lm14) & !missing(hhi_new)
		*** 119801 obs left
		*** wage effect can only be investigated with the cases for which in both 2006 and 2014 they have wages
		*** winsorize the top and bottom 1% for both 06 and 14
		sum wage_lm06,d
		global wage06_p1=r(p1)
		global wage06_p99=r(p99)
		sum wage_lm14,d
		global wage14_p1=r(p1)
		global wage14_p99=r(p99)
		drop if wage_lm06<$wage06_p1 | wage_lm06>$wage06_p99
		drop if wage_lm14<$wage14_p1 | wage_lm14>$wage14_p99
		*** 115593 obs left
		g d_lnwage_0614=lnwage_lm14-lnwage_lm06
		g d_wage_0614=wage_lm14-wage_lm06
		count if er_us_emp06==0
		*** 0
		count if er_eu==0
		*** 569
		drop if er_eu==0
		*** 115024 obs left
		save dep_wage0614,replace
	restore


