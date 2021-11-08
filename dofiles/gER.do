clear all
global empirical_v2 "E:\Dropbox\Research\Ding's Proposal\WorkingFile\empirical_v2"
global tempdata "E:\Dropbox\Research\Ding's Proposal\WorkingFile\empirical_v2\temp_data"
global cw_ipums "E:\Dropbox\Research\Ding's Proposal\WorkingFile\empirical_v2\cw_ipums"
cd "$ipums\datafiles"
/*
use imputed_census90,clear
preserve
keep soc
bys soc: keep if _n==1
save cen90_soclist,replace
restore
tab empstat
/*
 employment status |
 [general version] |      Freq.     Percent        Cum.
-------------------+-----------------------------------
               n/a |  7,342,007       24.17       24.17
          employed | 13,400,519       44.11       68.28
        unemployed |    918,987        3.02       71.30
not in labor force |  8,719,332       28.70      100.00
-------------------+-----------------------------------
             Total | 30,380,845      100.00
*/
g emp_temp=0
replace emp_temp=1 if empstat==1
egen emp_tot=total(perwt*emp_temp)
bys IFRind soc czone2000: egen emp_lm_ind=total(emp_temp*perwt)
bys IFRind soc czone2000: keep if _n==1
keep year czone2000 soc IFRind emp_lm_ind
sort czone2000 soc
drop if IFRind=="n/a" | soc=="none"
sum emp_lm_ind
/* 
    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
  emp_lm_ind |    814,680    143.6713    1204.138          0   206850.7
*/
mmerge IFRind using apr_ifr,type(n:1)
/*
-------------------------------------------------------------------------------
merge specs          |
       matching type | n:1
  mv's on match vars | none
  unmatched obs from | both
---------------------+---------------------------------------------------------
  master        file | imputed_census90.dta
                 obs | 814680
                vars |      5
          match vars | IFRind  (not a key)
  -------------------+---------------------------------------------------------
  using         file | apr_ifr.dta
                 obs |     19
                vars |      3
          match vars | IFRind  (key)
---------------------+---------------------------------------------------------
variable IFRind does not uniquely identify observations in the master data
result          file | imputed_census90.dta
                 obs | 814680
                vars |      9  (including _merge)
         ------------+---------------------------------------------------------
              _merge | 814680  obs both in master and using data      (code==3)
-------------------------------------------------------------------------------
*/
drop _merge
bys czone2000 soc: egen emp_lm=total(emp_lm_ind)
bys czone2000 soc: egen er_eu_0014=total(apr_euro5_price00_14_*emp_lm_ind/emp_lm)
    *** Exposure to robot
bys czone2000 soc: keep if _n==1
keep czone2000 soc er_eu_0014
save er_iv,replace
*/

/*
***use census 2000 to generate weights in ER, witout iv
use imputed_census00,clear
preserve
keep occsoc
bys occsoc: keep if _n==1
save cen00_soclist,replace
restore
tab empstat
/*
 [general version] |      Freq.     Percent        Cum.
-------------------+-----------------------------------
               n/a |  7,101,736       23.00       23.00
          employed | 13,821,165       44.76       67.76
        unemployed |    835,938        2.71       70.47
not in labor force |  9,119,809       29.53      100.00
-------------------+-----------------------------------
             Total | 30,878,648      100.00
*/
g emp_temp=0
replace emp_temp=1 if empstat==1
egen emp_total=total(emp_temp*perwt)
bys IFRind occsoc czone2000: egen emp_lm_ind=total(emp_temp*perwt)
bys IFRind occsoc czone2000: keep if _n==1
keep year czone2000 occsoc IFRind emp_lm_ind
sort czone2000 occsoc
drop if IFRind=="n/a" | occsoc=="000000" | occsoc=="999920" | substr(occsoc,1,2)=="55"
sum emp_lm_ind
/*
    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
  emp_lm_ind |    907,047    144.1348    1106.294          0   189717.2
*/
mmerge IFRind using apr_ifr,type(n:1)
/*
-------------------------------------------------------------------------------
merge specs          |
       matching type | n:1
  mv's on match vars | none
  unmatched obs from | both
---------------------+---------------------------------------------------------
  master        file | imputed_census00.dta
                 obs | 907047
                vars |      5
          match vars | IFRind  (not a key)
  -------------------+---------------------------------------------------------
  using         file | apr_ifr.dta
                 obs |     19
                vars |      3
          match vars | IFRind  (key)
---------------------+---------------------------------------------------------
variable IFRind does not uniquely identify observations in the master data
result          file | imputed_census00.dta
                 obs | 907047
                vars |      9  (including _merge)
         ------------+---------------------------------------------------------
              _merge | 907047  obs both in master and using data      (code==3)
-------------------------------------------------------------------------------
*/
drop _merge
bys czone2000 occsoc: egen emp_lm=total(emp_lm_ind)
bys czone2000 occsoc: egen er_us_emp00=total(apr_us_adj04_14_*0.8*emp_lm_ind/emp_lm)
    *** Exposure to robot
sum emp_lm,detail
/*
                           emp_lm
-------------------------------------------------------------
      Percentiles      Smallest
 1%            0              0
 5%     3.304871              0
10%     8.778296              0       Obs             907,047
25%     39.03382              0       Sum of Wgt.     907,047

50%     182.4023                      Mean           1267.166
                        Largest       Std. Dev.      4595.044
75%     769.4295       174788.1
90%     2626.146       174788.1       Variance       2.11e+07
95%     5394.132       190283.2       Skewness       12.64424
99%        18853       190283.2       Kurtosis        267.696
*/
bys czone2000 occsoc: keep if _n==1
keep czone2000 occsoc er_us_emp00
save er_us_emp00,replace
*/

***use acs 2006 as weights in US ER, census 2000 as weights iv ER
use imputed_census00,clear
tab empstat
/*
 [general version] |      Freq.     Percent        Cum.
-------------------+-----------------------------------
               n/a |  7,101,736       23.00       23.00
          employed | 13,821,165       44.76       67.76
        unemployed |    835,938        2.71       70.47
not in labor force |  9,119,809       29.53      100.00
-------------------+-----------------------------------
             Total | 30,878,648      100.00
*/
g emp_temp=0
replace emp_temp=1 if empstat==1
egen emp_total=total(emp_temp*perwt)
bys IFRind occsoc czone2000: egen emp_lm_ind=total(emp_temp*perwt)
bys IFRind occsoc czone2000: keep if _n==1
keep year czone2000 occsoc IFRind emp_lm_ind
sort czone2000 occsoc
drop if IFRind=="n/a" | occsoc=="000000" | occsoc=="999920" | occsoc=="559830"
sum emp_lm_ind
/*
    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
  emp_lm_ind |    907,047    144.1348    1106.294          0   189717.2
*/
mmerge IFRind using apr_ifr,type(n:1)
/*
-------------------------------------------------------------------------------
merge specs          |
       matching type | n:1
  mv's on match vars | none
  unmatched obs from | both
---------------------+---------------------------------------------------------
  master        file | imputed_census00.dta
                 obs | 908434
                vars |      5
          match vars | IFRind  (not a key)
  -------------------+---------------------------------------------------------
  using         file | apr_ifr.dta
                 obs |     19
                vars |      3
          match vars | IFRind  (key)
---------------------+---------------------------------------------------------
variable IFRind does not uniquely identify observations in the master data
result          file | imputed_census00.dta
                 obs | 908434
                vars |      9  (including _merge)
         ------------+---------------------------------------------------------
              _merge | 908434  obs both in master and using data      (code==3)
-------------------------------------------------------------------------------
*/
drop _merge
bys czone2000 occsoc: egen emp_lm=total(emp_lm_ind)
bys czone2000 occsoc: egen er_eu=total(apr_euro5_qo00_14_*8/14*emp_lm_ind/emp_lm)
    *** Exposure to robot
sum emp_lm,detail
/*
                           emp_lm
-------------------------------------------------------------
      Percentiles      Smallest
 1%            0              0
 5%     3.304871              0
10%     8.778296              0       Obs             907,047
25%     39.03382              0       Sum of Wgt.     907,047

50%     182.4023                      Mean           1267.166
                        Largest       Std. Dev.      4595.044
75%     769.4295       174788.1
90%     2626.146       174788.1       Variance       2.11e+07
95%     5394.132       190283.2       Skewness       12.64424
99%        18853       190283.2       Kurtosis        267.696
*/
bys czone2000 occsoc: keep if _n==1
keep czone2000 occsoc er_eu
save er_eu,replace
	*** make it a balanced panel
	use "$cw_ipums\cw_cty_cz2000",clear
	drop FIPS
	bys czone2000: keep if _n==1
	expand 446
	bys czone2000: g row=_n
	merge m:1 row using "$tempdata\marinew_soclist"
	drop _merge row
	merge 1:1 czone2000 occsoc using er_eu
	*** 40400 markets have no robot exposure (b/c there are no such markets)
	replace er_eu=0 if missing(er_eu)
	drop _merge
save er_eu,replace
	*** ther are 446*709=316214 obs



use imputed_acs06,clear
tab empstat
/*
 employment status |
 [general version] |      Freq.     Percent        Cum.
-------------------+-----------------------------------
               n/a |  1,265,629       20.39       20.39
          employed |  2,846,989       45.87       66.26
        unemployed |    170,968        2.75       69.01
not in labor force |  1,923,168       30.99      100.00
-------------------+-----------------------------------
             Total |  6,206,754      100.00
*/
g emp_temp=0
replace emp_temp=1 if empstat==1
egen emp_total=total(emp_temp*perwt)
bys IFRind occsoc czone2000: egen emp_lm_ind=total(emp_temp*perwt)
bys IFRind occsoc czone2000: keep if _n==1
keep year czone2000 occsoc IFRind emp_lm_ind
sort czone2000 occsoc
drop if IFRind=="n/a" | occsoc=="     0" | occsoc=="999920" | occsoc=="559830"
sum emp_lm_ind


mmerge IFRind using apr_ifr,type(n:1)
/*
-------------------------------------------------------------------------------
merge specs          |
       matching type | n:1
  mv's on match vars | none
  unmatched obs from | both
---------------------+---------------------------------------------------------
  master        file | imputed_acs06.dta
                 obs | 435037
                vars |      5
          match vars | IFRind  (not a key)
  -------------------+---------------------------------------------------------
  using         file | apr_ifr.dta
                 obs |     19
                vars |      3
          match vars | IFRind  (key)
---------------------+---------------------------------------------------------
variable IFRind does not uniquely identify observations in the master data
result          file | imputed_acs06.dta
                 obs | 435037
                vars |      9  (including _merge)
         ------------+---------------------------------------------------------
              _merge | 435037  obs both in master and using data      (code==3)
-------------------------------------------------------------------------------
*/
drop _merge
bys czone2000 occsoc: egen emp_lm=total(emp_lm_ind)
bys czone2000 occsoc: egen er_us_emp06=total(apr_us_adj04_14_*0.8*emp_lm_ind/emp_lm)
    *** Exposure to robot
sum emp_lm,detail

bys czone2000 occsoc: keep if _n==1
keep czone2000 occsoc er_us_emp06
save er_us_emp06,replace
	*** make if balanced panel
	use "$cw_ipums\cw_cty_cz2000",clear
	drop FIPS
	bys czone2000: keep if _n==1
	expand 446
	bys czone2000: g row=_n
	merge m:1 row using "$tempdata\marinew_soclist"
	drop _merge row
	merge 1:1 czone2000 occsoc using er_us_emp06
	*** 108738 markets have no robot penetration
	replace er_us_emp06=0 if missing(er_us_emp06)
	drop _merge
save er_us_emp06,replace
	*** ther are 446*709=316214 obs
