clear all
global ipums "E:\Dropbox\Research\Ding's Proposal\WorkingFile\empirical_v2"
global tempdata "E:\Dropbox\Research\Ding's Proposal\WorkingFile\empirical_v2\temp_data"
global cw_ipums "E:\Dropbox\Research\Ding's Proposal\WorkingFile\empirical_v2\cw_ipums"
global dofiles "E:\Dropbox\Research\Ding's Proposal\WorkingFile\empirical_v2\dofiles"
global datafiles "E:\Dropbox\Research\Ding's Proposal\WorkingFile\empirical_v2\datafiles"
cd "$datafiles"

******create IFRind level adjusted penetration of robots
use "E:\Dropbox\Research\Ding's Proposal\WorkingFile\AcemogluReplica\clean_data\industry_data_ifr19",clear
keep industry_ifr19 apr_us_adj04_14_ apr_euro5_qo00_14_
rename industry_ifr19 IFRind
save apr_ifr,replace
******make hhi_2016 ready
use "E:\Dropbox\Research\Ding's Proposal\WorkingFile\Marinescu\hhis_2016",clear
rename cz czone2000
rename hhi_lower hhi2016
drop year
save hhi_2016,replace


**********************************************************
**********first generate some useful crosswalks***********
**********************************************************

	*** the following concordance table are not used
	/*
		***occ2000 to soc crosswalk
		import excel "$cw_ipums\occ00_soc.xlsx", firstrow clear
		forvalues i=1(1)6{
		g soc`i'=substr(SOCEquivs,(`i'-1)*9+1,7)
		}
		rename Code occ00
		rename CategoryTitle soctitle
		drop SOCEquivs
		save "$cw_ipums\cw_occ00_soc",replace

		***occ1990 to occ2000 crosswalk
		import excel "$cw_ipums\occ_90-00.xls",clear
		drop if _n<=5
		rename A occ90
		rename B occ90title
		rename C occ00
		rename D occ00title
		rename E occ90LF
		rename F occ90to00pct
		rename G occ90to00LF  /*G infers F*/
		drop H
		drop if _n>=2167 & _n<=2173
		destring occ90,replace
		destring occ00,replace
		replace occ90=occ90[_n-1] if occ90==.
		replace occ90title=occ90title[_n-1] if occ90title==""
		replace occ90LF=occ90LF[_n-1] if occ90LF==""
		drop if missing(occ00)
		save "$cw_ipums\cw_occ90_occ00",replace

		***occ2010 to soc crosswalk
		import excel "$cw_ipums\occ10_soc.xls",clear
		drop if _n<=14
		drop if missing(C)
		drop if length(C)>=8
		replace C=substr(C,2,4) if length(C)>4
		replace D=substr(D,3,7) if substr(D,1,2)=="  "
		replace D=substr(D,2,7) if substr(D,1,1)==" "
		replace D=substr(D,1,7) if length(D)>7
		drop A
		rename B jobtitle
		rename C occ2010
		rename D soc
		destring occ2010,replace
		replace occ2010=130 if occ2010==136 | occ2010==135 | occ2010==137
		replace soc="11-31XX" if soc=="11-3111" | soc=="11-3121" | soc=="11-3131"
		replace occ2010=320 if occ2010==325
		replace occ2010=560 if occ2010==565
		replace occ2010=620 if occ2010==630 | occ2010==640 | occ2010==650
		replace soc="13-107X" if soc=="13-1070" | soc=="13-1141" | soc=="13-1151"
		replace occ2010=720 if occ2010==725
		replace occ2010=730 if occ2010==740
		replace occ2010=1000 if occ2010==1005 | occ2010==1006 | occ2010==1007
		replace soc="15-11XX" if soc=="15-1111" | soc=="15-1121" | soc=="15-1122"
		replace occ2010=1100 if occ2010==1105 | occ2010==1106 | occ2010==1107
		replace soc="15-114X" if soc=="15-1142" | soc=="15-1143" | soc=="15-1199"
		replace occ2010=1960 if occ2010==1965
		replace occ2010=2020 if occ2010==2025
		replace occ2010=2140 if occ2010==2145
		replace occ2010=2150 if occ2010==2160
		replace occ2010=3130 if occ2010==3255
		replace occ2010=3240 if occ2010==3245
		replace occ2010=3410 if occ2010==3420
		replace occ2010=3530 if occ2010==3535
		replace occ2010=3650 if occ2010==3655
		replace occ2010=3950 if occ2010==3955
		replace occ2010=8230 if occ2010==8255 | occ2010==8256
		replace soc="51-511X" if soc=="51-5112" | soc=="51-5113"
		replace occ2010=9100 if occ2010==9110 | occ2010==9120
		replace soc="53-30XX" if soc=="53-3011" | soc=="53-3020"
		bys occ2010: keep if _n==1
		save "$cw_ipums\cw_occ10_soc",replace
		   *** revised some occ2010 in cw according to census 90 ***
	*/
***county to cz2000 crosswalk
import excel "$cw_ipums\cz00_eqv_v1.xls",firstrow clear
egen popnation=total(CountyPopulation2000)
egen popnationbigbig=total(CountyPopulation2000) if CountyPopulation2000>=120000
count if CountyPopulation2000>100000
rename CommutingZoneID2000 czone2000
keep FIPS czone2000
destring FIPS,replace
save "$cw_ipums\cw_cty_cz2000",replace

***state to cz2000 crosswalk
import excel "$cw_ipums\cz00_eqv_v1.xls",firstrow clear
g statefip=substr(FIPS,1,2)
rename CommutingZoneID2000 czone2000
rename CountyPopulation2000 ctypop
keep statefip czone2000 ctypop
bys czone2000 statefip: egen cz_state_pop=total(ctypop)
bys czone2000: egen cz_pop=total(ctypop)
sort czone2000 statefip
bys czone2000: egen maxpop=max(cz_state_pop)
g state=statefip if maxpop==cz_state_pop
destring state,replace
by czone2000: egen statetemp=max(state)
replace state=statetemp
keep czone2000 state
bys czone2000 state:keep if _n==1
save "$cw_ipums\cw_state_cz2000",replace


***********************************************************************************************
***********************************************************************************************
***********************************************************************************************
/*  Two weighting schemes when reshaping puma-level census data to cz2000-level
    (a)Inaccurate method: Treat the population share of a county in a puma as the probability that 
                         the individual is from this county, then split the puma-level to county-level
						 by assuming new_weights=old_weights*probability
    (b)Accurate method: First extract available county-level FIPS and puma-state information 
	                   (check if a puma-state can uniquely assign a cz2000 to this individual ),
					   then do the first method 
*/
***********************************************************************************************
***********************************************************************************************
***********************************************************************************************
/*
*** In census 1990, there are 509 puma90.
import delimited "$cw_ipums\puma90_cty.csv", clear
rename county FIPS
rename pumacodefrom19905asample puma90
rename cntyname cty_name
rename countytoapumaallocationfactor ctypumaratio
keep FIPS puma90 cty_name pop ctypumaratio
tostring FIPS,replace
g statefip=substr(FIPS,1,1) if length(FIPS)==4
replace statefip=substr(FIPS,1,2) if length(FIPS)==5
destring FIPS,replace
destring statefip,replace
save "$cw_ipums\cw_cty_puma90",replace
   ****a crosswalk between cty and puma90 is generated
*/

*** In census 2000, there are 630 puma00.
import delimited "$cw_ipums\puma00_cty.csv", clear
drop if _n<=2
rename v1 FIPS
rename v3 puma00
rename v5 cty_name
rename v6 pop
rename v7 ctypumaratio
keep FIPS puma00 cty_name pop ctypumaratio
g statefip=substr(FIPS,1,1) if length(FIPS)==4
replace statefip=substr(FIPS,1,2) if length(FIPS)==5
destring FIPS,replace
destring statefip,replace
destring puma00,replace
save "$cw_ipums\cw_cty_puma00",replace
   ****a crosswalk between cty and puma00 is generated (will be used by method(b))

   /*no need
import delimited using "$cw_ipums\puma00_cty.csv",clear
drop if _n<=2
rename (v1 v2 v3 v4 v5 v6 v7) (FIPS statefip puma00 statecode cty_name pop factor)
keep FIPS puma00 pop
destring *, replace
replace puma00=77777 if puma00==01905
/*bys FIPS puma00: egen poptemp=total(pop)
replace pop=poptemp
bys FIPS puma00: keep if _n==1
drop poptemp*/
bys puma00: egen pop_puma=total(pop)
g cty_share=pop/pop_puma
drop pop pop_puma
sort puma00 FIPS
  reshape wide cty_share, i(puma00) j(FIPS)
save "$cw_ipums\cw_cty_puma00_v2",replace
    ****a second crosswalk between cty and puma00 is generated (will be used by method(a))
*/
	
*********************************
************Method(b)************
*********************************




******1990******
/*
***generate: 1. A dataset including all puma90-state areas that cover individuals without countyfips (but do have statefip)
************ 2. A dataset including all counties have been identified
use ipums_census90,clear
g FIPS=countyfip+statefip*1000
preserve
keep if countyfip==0
keep puma statefip
bys puma statefip: keep if _n==1
rename puma puma90
save "$tempdata\cen90_noid_cty",replace
restore
   ****588 puma90-state areas with no identified cty fips
keep if countyfip!=0
keep FIPS
bys FIPS: keep if _n==1
save "$tempdata\cen90_id_cty",replace
   ****385 counties



use "$cw_ipums\cw_cty_puma90",clear
mmerge puma90 statefip using "$tempdata\cen90_noid_cty",type(n:1)
/*
-------------------------------------------------------------------------------
merge specs          |
       matching type | n:1
  mv's on match vars | none
  unmatched obs from | both
---------------------+---------------------------------------------------------
  master        file | cw_cty_puma90.dta
                 obs |   3974
                vars |      6
          match vars | puma90 statefip  (not a key)
  -------------------+---------------------------------------------------------
  using         file | E:\Dropbox\Research\Ding's Proposal\WorkingFile\IPUMS\temp_data\cen90_noid_cty.dta
                 obs |    588
                vars |      2
          match vars | puma90 statefip  (key)
---------------------+---------------------------------------------------------
variables puma90 statefip do not uniquely identify observations in the master data
result          file | cw_cty_puma90.dta
                 obs |   3974
                vars |      8  (including _merge)
         ------------+---------------------------------------------------------
              _merge |   1138  obs only in master data                (code==1)
                     |   2836  obs both in master and using data      (code==3)
-------------------------------------------------------------------------------

*/
drop if _merge!=3
drop _merge
   ***Here is the list of potential counties a puma90-state could have included.
merge m:1 FIPS using "$tempdata\cen90_id_cty"
   ***This shows there is no such case that a puma90-state includes a county has been identified
drop if _merge!=1
drop _merge
mmerge FIPS using "$cw_ipums\cw_cty_cz2000",type(n:1)
/*
-------------------------------------------------------------------------------
merge specs          |
       matching type | n:1
  mv's on match vars | none
  unmatched obs from | both
---------------------+---------------------------------------------------------
  master        file | cw_cty_puma90.dta
                 obs |   2836
                vars |      6
          match vars | FIPS  (not a key)
  -------------------+---------------------------------------------------------
  using         file | cw_cty_cz2000.dta
                 obs |   3141
                vars |      2
          match vars | FIPS  (key)
---------------------+---------------------------------------------------------
variable FIPS does not uniquely identify observations in the master data
result          file | cw_cty_puma90.dta
                 obs |   3224
                vars |      9  (including _merge)
         ------------+---------------------------------------------------------
              _merge |      3  obs only in master data                (code==1)
                     |    388  obs only in using data                 (code==2)
                     |   2833  obs both in master and using data      (code==3)
-------------------------------------------------------------------------------
*/
drop if _merge!=3
drop _merge
sort puma90 statefip
bys puma90 statefip: g num_row=_N
bys puma90 statefip: egen cztotal=total(czone2000)
g cz2000=cztotal/num_row
g dummy=(czone2000==cz2000)
   ***the code above identifies whether a puma90-state can be uniquely distributed to a czone2000
   ***or say, dummy=1 if all counties in a puma90-state belong to a same czone2000
preserve
keep if dummy==1
keep puma90 statefip cz2000
bys puma90 statefip: keep if _n==1
save "$tempdata\cen90_id_cz",replace
    *** 210 puma90-state can be directly matched with a czone2000
restore
keep if dummy==0
bys puma90 state: egen poptotal=total(pop)
g cty_share=pop/poptotal   /*more accurately, this is cty-to-puma90state ratio. It doesn't matter if 1 cty matches to 2 PUMAs*/
keep FIPS puma90 cty_share statefip
bys puma90 statefip: g num_row=_n
sum num_row
 ****30 is the maxmum number of counties a puma has
save "$tempdata\cen90_noid_wtd",replace

  
use ipums_census90,clear
g FIPS=countyfip+statefip*1000
rename puma puma90
mmerge FIPS using "$cw_ipums\cw_cty_cz2000",type(n:1)
   ***Purpose 1: assign a cz2000 to all identified counties; 
   ***        2: drop the nonidentified counties (in crosswalk table)
/*
-------------------------------------------------------------------------------
merge specs          |
       matching type | n:1
  mv's on match vars | none
  unmatched obs from | both
---------------------+---------------------------------------------------------
  master        file | ipums_census90.dta
                 obs | 12501046
                vars |     35
          match vars | FIPS  (not a key)
  -------------------+---------------------------------------------------------
  using         file | cw_cty_cz2000.dta
                 obs |   3141
                vars |      2
          match vars | FIPS  (key)
---------------------+---------------------------------------------------------
variable FIPS does not uniquely identify observations in the master data
(note: variable FIPS was float, now double to accommodate using data's values)
result          file | ipums_census90.dta
                 obs | 12503802
                vars |     38  (including _merge)
         ------------+---------------------------------------------------------
              _merge | 5006833  obs only in master data                (code==1)
                     |   2756  obs only in using data                 (code==2)
                     | 7494213  obs both in master and using data      (code==3)
-------------------------------------------------------------------------------
*/
drop if _merge==2
drop _merge
mmerge puma90 statefip using "$tempdata\cen90_id_cz", type(n:1)
   *** check how large the size of identified(in terms of cz) puma90-state areas 
/*
-------------------------------------------------------------------------------
merge specs          |
       matching type | n:1
  mv's on match vars | none
  unmatched obs from | both
---------------------+---------------------------------------------------------
  master        file | ipums_census90.dta
                 obs | 12501046
                vars |     36
          match vars | puma90 statefip  (not a key)
  -------------------+---------------------------------------------------------
  using         file | E:\Dropbox\Research\Ding's Proposal\WorkingFile\IPUMS\temp_data\cen90_id_cz.dta
                 obs |    210
                vars |      3
          match vars | puma90 statefip  (key)
---------------------+---------------------------------------------------------
variables puma90 statefip do not uniquely identify observations in the master data
result          file | ipums_census90.dta
                 obs | 12501046
                vars |     39  (including _merge)
         ------------+---------------------------------------------------------
              _merge | 10771024  obs only in master data                (code==1)
                     | 1730022  obs both in master and using data      (code==3)
-------------------------------------------------------------------------------
*/
replace czone2000=cz2000 if czone2000==.
   *** all obs that were either identified through county FIPS or puma90-state-to-cz2000
   *** are now labeled with their czone2000
   count if czone2000==.
   *** 3276811 obs are not identified
drop cz2000 _merge
preserve
keep if missing(czone2000)
save "$tempdata\cen90_noid",replace
   *** individuals whose czone2000 cannot be identified are put in this sample
restore
keep if czone2000!=.
save "$tempdata\cen90_id",replace
   *** individuals whose czone2000 are directly identified are put in this sample

use "$tempdata\cen90_noid",clear
drop FIPS
expand 30
bys serial pernum: g num_row=_n
mmerge puma90 statefip num_row using "$tempdata\cen90_noid_wtd",type(n:1)
drop if _merge==1
sort serial pernum
drop czone2000 _merge num_row
replace perwt=perwt*cty_share
drop cty_share
merge m:1 FIPS using "$cw_ipums\cw_cty_cz2000"
drop if _merge!=3
drop _merge
append using "$tempdata\cen90_id"

******then reclassify jobs by SOC system******
merge m:1 occ2010 using "$cw_ipums\cw_occ10_soc"
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                         9,781
        from master                     9,603  (_merge==1)
        from using                        178  (_merge==2)

    matched                        30,380,845  (_merge==3)
    -----------------------------------------
*/
bys _merge: egen population=total(perwt)
table occ2010 if _merge==1
keep if _merge==3
drop _merge

******last step, aggregate ind1990 to IFRind******
g IFRind="n/a"
replace IFRind="agriculture" if ind1990>=10 & ind1990<=32
replace IFRind="mining" if ind1990>=40 & ind1990<=50
replace IFRind="construction" if ind1990==60
replace IFRind="food" if ind1990>=100 & ind1990<=130
replace IFRind="textiles" if ind1990>=132 & ind1990<=152
replace IFRind="paper" if ind1990>=160 & ind1990<=172
replace IFRind="petrochemicals" if ind1990>=180 & ind1990<=222
replace IFRind="furniture" if ind1990>=230 & ind1990<=242
replace IFRind="mineral" if ind1990>=250 & ind1990<=262
replace IFRind="metal_basic" if ind1990>=270 & ind1990<=280
replace IFRind="metal_products" if ind1990>=281 & ind1990<=301
replace IFRind="metal_machinery" if ind1990>=310 & ind1990<=332
replace IFRind="electronics" if ind1990>=340 & ind1990<=350
replace IFRind="automotive" if ind1990==351
replace IFRind="vehicles_other" if ind1990>=352 & ind1990<=370
replace IFRind="manufacturing_other" if ind1990>=371 & ind1990<=392
replace IFRind="utilities" if ind1990>=400 & ind1990<=472
replace IFRind="services" if (ind1990>=500 & ind1990<=841) | (ind1990>=861 & ind1990<=960 & ind1990!=891) 
replace IFRind="research" if (ind1990>=842 & ind1990<=860) | ind1990==891
save imputed_census90,replace
*/




**************************************************************

**************************************************************

**************************************************************

**************************************************************

**************************************************************



******Census 2000******

***generate: 1. A dataset including all puma90-state areas that cover individuals without countyfips (but do have statefip)
************ 2. A dataset including all obs whose counties have been identified
use ipums_census00,clear
keep if sample==200001
g FIPS=countyfip+statefip*1000
preserve
keep if countyfip==0
keep puma statefip
bys puma statefip: keep if _n==1
rename puma puma00
save "$tempdata\cen00_noid_cty",replace
restore
   ****837 puma00-state areas
keep if countyfip!=0
keep FIPS
bys FIPS: keep if _n==1
save "$tempdata\cen00_id_cty",replace
   ****377 identified counties



use "$cw_ipums\cw_cty_puma00",clear
mmerge puma00 statefip using "$tempdata\cen00_noid_cty",type(n:1)
/*
-------------------------------------------------------------------------------
merge specs          |
       matching type | n:1
  mv's on match vars | none
  unmatched obs from | both
---------------------+---------------------------------------------------------
  master        file | cw_cty_puma00.dta
                 obs |   4281
                vars |      6
          match vars | puma00 statefip  (not a key)
  -------------------+---------------------------------------------------------
  using         file | c00_puma00_state.dta
                 obs |    837
                vars |      2
          match vars | puma00 statefip  (key)
---------------------+---------------------------------------------------------
variables puma00 statefip do not uniquely identify observations in the master data
result          file | cw_cty_puma00.dta
                 obs |   4281
                vars |      8  (including _merge)
         ------------+---------------------------------------------------------
              _merge |   1234  obs only in master data                (code==1)
                     |   3047  obs both in master and using data      (code==3)
-------------------------------------------------------------------------------
*/
drop if _merge!=3
drop _merge
   ***Here is the list of potential counties a puma00-state could have included.
merge m:1 FIPS using "$tempdata\cen00_id_cty"
   ***This shows there is no such case that a puma00-state includes a county that has been identified
drop if _merge!=1
drop _merge
mmerge FIPS using "$cw_ipums\cw_cty_cz2000",type(n:1)
/*
-------------------------------------------------------------------------------
merge specs          |
       matching type | n:1
  mv's on match vars | none
  unmatched obs from | both
---------------------+---------------------------------------------------------
  master        file | cw_cty_puma00.dta
                 obs |   3047
                vars |      6
          match vars | FIPS  (not a key)
  -------------------+---------------------------------------------------------
  using         file | cw_cty_cz2000.dta
                 obs |   3141
                vars |      2
          match vars | FIPS  (key)
---------------------+---------------------------------------------------------
variable FIPS does not uniquely identify observations in the master data
result          file | cw_cty_puma00.dta
                 obs |   3424
                vars |      9  (including _merge)
         ------------+---------------------------------------------------------
              _merge |    377  obs only in using data                 (code==2)
                     |   3047  obs both in master and using data      (code==3)
-------------------------------------------------------------------------------
*/
drop if _merge!=3
drop _merge
sort puma00 statefip
bys puma00 statefip: g num_row=_N
bys puma00 statefip: egen cztotal=total(czone2000)
g cz2000=cztotal/num_row
g dummy=(czone2000==cz2000)
   ***the code above identifies all puma00-state cells that can uniquely identify a czone2000
   ***or say, dummy=1 if all counties in a puma00-state belong to same czone2000
preserve
keep if dummy==1
keep puma00 statefip cz2000
bys puma00 statefip: keep if _n==1
save "$tempdata\cen00_id_cz",replace
    *** 460 puma00-state can be directly matched with a czone2000
restore
keep if dummy==0
destring pop,replace
bys puma00 statefip: egen poptotal=total(pop)
g cty_share=pop/poptotal   /*more accurately, this is cty-to-puma90state ratio. It doesn't matter if 1 cty matches to 2 PUMAs*/
keep FIPS puma00 cty_share statefip
bys puma00 statefip: g num_row=_n
sum num_row
 ****26 is the maxmum number of counties a PUMA-state has
save "$tempdata\cen00_noid_wtd",replace

  
use ipums_census00,clear
keep if sample==200001
g FIPS=countyfip+statefip*1000
rename puma puma00
mmerge FIPS using "$cw_ipums\cw_cty_cz2000",type(n:1)
/*
-------------------------------------------------------------------------------
merge specs          |
       matching type | n:1
  mv's on match vars | none
  unmatched obs from | both
---------------------+---------------------------------------------------------
  master        file | ipums_census00.dta
                 obs | 14081466
                vars |     37
          match vars | FIPS  (not a key)
  -------------------+---------------------------------------------------------
  using         file | cw_cty_cz2000.dta
                 obs |   3141
                vars |      2
          match vars | FIPS  (key)
---------------------+---------------------------------------------------------
variable FIPS does not uniquely identify observations in the master data
(note: variable FIPS was float, now double to accommodate using data's values)
result          file | ipums_census00.dta
                 obs | 14084230
                vars |     40  (including _merge)
         ------------+---------------------------------------------------------
              _merge | 6335236  obs only in master data                (code==1)
                     |   2764  obs only in using data                 (code==2)
                     | 7746230  obs both in master and using data      (code==3)
-------------------------------------------------------------------------------

*/
drop if _merge==2
drop _merge
mmerge puma00 statefip using "$tempdata\cen00_id_cz", type(n:1)
/*
-------------------------------------------------------------------------------
merge specs          |
       matching type | n:1
  mv's on match vars | none
  unmatched obs from | both
---------------------+---------------------------------------------------------
  master        file | ipums_census00.dta
                 obs | 14081466
                vars |     38
          match vars | puma00 statefip  (not a key)
  -------------------+---------------------------------------------------------
  using         file | puma00_state_cz2000.dta
                 obs |    460
                vars |      3
          match vars | puma00 statefip  (key)
---------------------+---------------------------------------------------------
variables puma00 statefip do not uniquely identify observations in the master data
result          file | ipums_census00.dta
                 obs | 14081466
                vars |     41  (including _merge)
         ------------+---------------------------------------------------------
              _merge | 11039751  obs only in master data                (code==1)
                     | 3041715  obs both in master and using data      (code==3)
-------------------------------------------------------------------------------
*/
replace czone2000=cz2000 if czone2000==.
drop cz2000 _merge
   count if czone2000==.
   *** 3293521 obs are not identified
preserve
keep if missing(czone2000)
save "$tempdata\cen00_noid",replace
   *** 3293521 can not identify a cz2000
restore
keep if czone2000!=.
save "$tempdata\cen00_id",replace
   *** 10787945 individuals successfully get cz2000
   
   
use "$tempdata\cen00_noid",clear
drop FIPS
expand 26
bys serial pernum: g num_row=_n
mmerge puma00 statefip num_row using "$tempdata\cen00_noid_wtd",type(n:1)
drop if _merge==1
sort serial pernum
drop czone2000 _merge num_row
replace perwt=perwt*cty_share
drop cty_share
merge m:1 FIPS using "$cw_ipums\cw_cty_cz2000"
drop if _merge!=3
drop _merge
append using "$tempdata\cen00_id"
egen population=total(perwt)


****I don't really need the following step for 2000 since it has soc report. But I reclassify Marinescu's hhi based one crosswalk
*****then reclassify jobs by SOC system******
merge m:1 occ2010 using "$cw_ipums\cw_occ10_soc"
/*
    Result                           # of obs.
    -----------------------------------------
    not matched                            78
        from master                         0  (_merge==1)
        from using                         78  (_merge==2)

    matched                        30,894,600  (_merge==3)
    -----------------------------------------
*/

keep if _merge==3
drop _merge
************reclassify occsoc to match other samples (ACS06-14, marinescu)**********
replace occsoc="111011" if occsoc=="111031"
replace occsoc="119013" if occsoc=="119011" | occsoc=="119012"
replace occsoc="119199" if occsoc=="119061" | occsoc=="119131"
replace occsoc="172XXX" if occsoc=="172161"
replace occsoc="1930XX" if occsoc=="193020"
replace occsoc="1940XX" if occsoc=="194041"
replace occsoc="2310XX" if occsoc=="231011" | occsoc=="231020"
replace occsoc="397010" if occsoc=="396020" | occsoc=="396030"
replace occsoc="439XXX" if occsoc=="439031" | occsoc=="439199"
replace occsoc="472140" if occsoc=="472141" | occsoc=="472142"
replace occsoc="472221" if occsoc=="472XXX"
replace occsoc="47XXXX" if occsoc=="474090" | occsoc=="474071"
replace occsoc="49909X" if occsoc=="499095"
replace occsoc="514030" if occsoc=="514031" | occsoc=="514032" | occsoc=="514033" | occsoc=="514034"
replace occsoc="5140XX" if occsoc=="514060" | | occsoc=="514070"
replace occsoc="514XXX" if substr(occsoc,1,5)=="51419"
replace occsoc="515111" if occsoc=="515022"
drop if occsoc=="515010" | occsoc=="515021"
replace occsoc="516040" if occsoc=="516041" | occsoc=="516042"
replace occsoc="51606X" if occsoc=="516061" | occsoc=="516062"
replace occsoc="519151" if occsoc=="519130"
replace occsoc="5191XX" if occsoc=="519192"
replace occsoc="533099" if occsoc=="5330XX"
replace occsoc="534031" if occsoc=="534021"
replace occsoc="5350XX" if occsoc=="535031" | occsoc=="535011"
replace occsoc="5371XX" if occsoc=="537XXX"
replace occsoc="999920" if occsoc=="559920"




******last step, aggregate ind1990 to IFRind******

g IFRind="n/a"
replace IFRind="agriculture" if ind1990>=10 & ind1990<=32
replace IFRind="mining" if ind1990>=40 & ind1990<=50
replace IFRind="construction" if ind1990==60
replace IFRind="food" if ind1990>=100 & ind1990<=130
replace IFRind="textiles" if ind1990>=132 & ind1990<=152
replace IFRind="paper" if ind1990>=160 & ind1990<=172
replace IFRind="petrochemicals" if ind1990>=180 & ind1990<=222
replace IFRind="furniture" if ind1990>=230 & ind1990<=242
replace IFRind="mineral" if ind1990>=250 & ind1990<=262
replace IFRind="metal_basic" if ind1990>=270 & ind1990<=280
replace IFRind="metal_products" if ind1990>=281 & ind1990<=301
replace IFRind="metal_machinery" if ind1990>=310 & ind1990<=332
replace IFRind="electronics" if ind1990>=340 & ind1990<=350
replace IFRind="automotive" if ind1990==351
replace IFRind="vehicles_other" if ind1990>=352 & ind1990<=370
replace IFRind="manufacturing_other" if ind1990>=371 & ind1990<=392
replace IFRind="utilities" if ind1990>=400 & ind1990<=472
replace IFRind="services" if (ind1990>=500 & ind1990<=841) | (ind1990>=861 & ind1990<=960 & ind1990!=891) 
replace IFRind="research" if (ind1990>=842 & ind1990<=860) | ind1990==891
save imputed_census00,replace



**************************************************************

**************************************************************

**************************************************************

**************************************************************

**************************************************************



******ACS 2006******

use ipums_acs0614,clear
keep if sample==200601
rename puma puma00
drop if puma00==77777
g FIPS=countyfip+statefip*1000
preserve
keep if countyfip==0
keep puma statefip
bys puma statefip: keep if _n==1
save "$tempdata\acs06_noid_cty",replace
   *****838 puma00-state areas
restore
keep if countyfip!=0
keep FIPS
bys FIPS: keep if _n==1
save "$tempdata\acs06_id_cty",replace
   ****376 identified counties
   
use "$cw_ipums\cw_cty_puma00",clear
mmerge puma00 statefip using "$tempdata\acs06_noid_cty",type(n:1)
/*
-------------------------------------------------------------------------------
merge specs          |
       matching type | n:1
  mv's on match vars | none
  unmatched obs from | both
---------------------+---------------------------------------------------------
  master        file | E:\Dropbox\Research\Ding's Proposal\WorkingFile\IPUMS\cw_ipum
> s\cw_cty_puma00.dta
                 obs |   4281
                vars |      6
          match vars | puma00 statefip  (not a key)
  -------------------+---------------------------------------------------------
  using         file | E:\Dropbox\Research\Ding's Proposal\WorkingFile\IPUMS\temp_da
> ta\acs06_noid_cty.dta
                 obs |    838
                vars |      2
          match vars | puma00 statefip  (key)
---------------------+---------------------------------------------------------
variables puma00 statefip do not uniquely identify observations in the master data
result          file | E:\Dropbox\Research\Ding's Proposal\WorkingFile\IPUMS\cw_ipum
> s\cw_cty_puma00.dta
                 obs |   4281
                vars |      8  (including _merge)
         ------------+---------------------------------------------------------
              _merge |   1235  obs only in master data                (code==1)
                     |   3046  obs both in master and using data      (code==3)
-------------------------------------------------------------------------------
*/
drop if _merge!=3
drop _merge
merge m:1 FIPS using "$tempdata\acs06_id_cty"
   ***This shows there is no such case that a puma00-state includes a county has been identified
drop if _merge!=1
drop _merge
mmerge FIPS using "$cw_ipums\cw_cty_cz2000",type(n:1)
drop if _merge!=3
drop _merge
sort puma00 statefip
bys puma00 statefip: g num_row=_N
bys puma00 statefip: egen cztotal=total(czone2000)
g cz2000=cztotal/num_row
g dummy=(czone2000==cz2000)
preserve
keep if dummy==1
keep puma00 statefip cz2000
bys puma00 statefip: keep if _n==1
save "$tempdata\acs06_id_cz",replace
    *** 461 puma00-state can be directly matched with a czone2000
restore
keep if dummy==0
destring pop,replace
bys puma00 statefip: egen poptotal=total(pop)
g cty_share=pop/poptotal   /*more accurately, this is cty-to-puma90state ratio. It doesn't matter if 1 cty matches to 2 PUMAs*/
keep FIPS puma00 cty_share statefip
bys puma00 statefip: g num_row=_n
sum num_row
 ****26 is the maxmum number of counties a puma has
save "$tempdata\acs06_noid_wtd",replace


use ipums_acs0614,clear
keep if sample==200601
g FIPS=countyfip+statefip*1000
rename puma puma00
mmerge FIPS using "$cw_ipums\cw_cty_cz2000",type(n:1)
/*
-------------------------------------------------------------------------------
merge specs          |
       matching type | n:1
  mv's on match vars | none
  unmatched obs from | both
---------------------+---------------------------------------------------------
  master        file | ipums_acs0614.dta
                 obs | 2969741
                vars |     30
          match vars | FIPS  (not a key)
  -------------------+---------------------------------------------------------
  using         file | E:\Dropbox\Research\Ding's Proposal\WorkingFile\IPUMS\cw_ipum
> s\cw_cty_cz2000.dta
                 obs |   3141
                vars |      2
          match vars | FIPS  (key)
---------------------+---------------------------------------------------------
variable FIPS does not uniquely identify observations in the master data
(note: variable FIPS was float, now double to accommodate using data's values)
result          file | ipums_acs0614.dta
                 obs | 2972506
                vars |     33  (including _merge)
         ------------+---------------------------------------------------------
              _merge | 1300502  obs only in master data                (code==1)
                     |   2765  obs only in using data                 (code==2)
                     | 1669239  obs both in master and using data      (code==3)
-------------------------------------------------------------------------------
*/
drop if _merge==2
drop _merge
mmerge puma00 statefip using "$tempdata\acs06_id_cz", type(n:1)
/*
-------------------------------------------------------------------------------
merge specs          |
       matching type | n:1
  mv's on match vars | none
  unmatched obs from | both
---------------------+---------------------------------------------------------
  master        file | ipums_acs0614.dta
                 obs | 2969741
                vars |     31
          match vars | puma00 statefip  (not a key)
  -------------------+---------------------------------------------------------
  using         file | E:\Dropbox\Research\Ding's Proposal\WorkingFile\IPUMS\temp_da
> ta\acs06_id_cz.dta
                 obs |    461
                vars |      3
          match vars | puma00 statefip  (key)
---------------------+---------------------------------------------------------
variables puma00 statefip do not uniquely identify observations in the master data
result          file | ipums_acs0614.dta
                 obs | 2969741
                vars |     34  (including _merge)
         ------------+---------------------------------------------------------
              _merge | 2312581  obs only in master data                (code==1)
                     | 657160  obs both in master and using data      (code==3)
-------------------------------------------------------------------------------
*/
replace czone2000=cz2000 if czone2000==.
drop cz2000 _merge
preserve
keep if missing(czone2000)
save "$tempdata\acs06_noid",replace
   
restore
keep if czone2000!=.
save "$tempdata\acs06_id",replace
   

use "$tempdata\acs06_noid",clear
drop FIPS
expand 26
bys serial pernum: g num_row=_n
mmerge puma00 statefip num_row using "$tempdata\acs06_noid_wtd",type(n:1)
drop if _merge==1
sort serial pernum
drop czone2000 _merge num_row
replace perwt=perwt*cty_share
drop cty_share
merge m:1 FIPS using "$cw_ipums\cw_cty_cz2000"
drop if _merge!=3
drop _merge
append using "$tempdata\acs06_id"
egen population=total(perwt)


************reclassify occsoc to match other samples (census00, acs14, marinescu)**********
replace occsoc="111011" if occsoc=="1110XX"
replace occsoc="119013" if occsoc=="119011" | occsoc=="119012"
replace occsoc="119199" if occsoc=="119061" | occsoc=="119190" | occsoc=="1191XX"
replace occsoc="1311XX" if occsoc=="131XXX"
replace occsoc="172XXX" if occsoc=="172021" | occsoc=="172031" | occsoc=="1720XX" | occsoc=="1721YY"
replace occsoc="1930XX" if occsoc=="193020"
replace occsoc="1940XX" if occsoc=="194041"
replace occsoc="2310XX" if occsoc=="231011"
replace occsoc="397010" if occsoc=="396020" | occsoc=="396030"
replace occsoc="439XXX" if occsoc=="439031" | occsoc=="439199"
replace occsoc="472140" if occsoc=="472141" | occsoc=="472142"
replace occsoc="472020" if occsoc=="472171"
replace occsoc="47XXXX" if occsoc=="4740XX"
replace occsoc="49909X" if occsoc=="499095"
replace occsoc="514030" if occsoc=="514031" | occsoc=="514032" | occsoc=="514033" | occsoc=="514034"
replace occsoc="5140XX" if occsoc=="514060" | | occsoc=="514070"
replace occsoc="514XXX" if substr(occsoc,1,5)=="51419"
replace occsoc="515111" if occsoc=="515022"
drop if occsoc=="515010" | occsoc=="515021"
replace occsoc="516040" if occsoc=="516041" | occsoc=="516042"
replace occsoc="519151" if occsoc=="519130"
replace occsoc="5191XX" if occsoc=="519192"
drop if occsoc=="533011"
replace occsoc="534031" if occsoc=="534021"
replace occsoc="537041" if occsoc=="5370XX"

******last step, aggregate ind1990 to IFRind******

g IFRind="n/a"
replace IFRind="agriculture" if ind1990>=10 & ind1990<=32
replace IFRind="mining" if ind1990>=40 & ind1990<=50
replace IFRind="construction" if ind1990==60
replace IFRind="food" if ind1990>=100 & ind1990<=130
replace IFRind="textiles" if ind1990>=132 & ind1990<=152
replace IFRind="paper" if ind1990>=160 & ind1990<=172
replace IFRind="petrochemicals" if ind1990>=180 & ind1990<=222
replace IFRind="furniture" if ind1990>=230 & ind1990<=242
replace IFRind="mineral" if ind1990>=250 & ind1990<=262
replace IFRind="metal_basic" if ind1990>=270 & ind1990<=280
replace IFRind="metal_products" if ind1990>=281 & ind1990<=301
replace IFRind="metal_machinery" if ind1990>=310 & ind1990<=332
replace IFRind="electronics" if ind1990>=340 & ind1990<=350
replace IFRind="automotive" if ind1990==351
replace IFRind="vehicles_other" if ind1990>=352 & ind1990<=370
replace IFRind="manufacturing_other" if ind1990>=371 & ind1990<=392
replace IFRind="utilities" if ind1990>=400 & ind1990<=472
replace IFRind="services" if (ind1990>=500 & ind1990<=841) | (ind1990>=861 & ind1990<=960 & ind1990!=891) 
replace IFRind="research" if (ind1990>=842 & ind1990<=860) | ind1990==891
save imputed_acs06,replace




**************************************************************

**************************************************************

**************************************************************

**************************************************************

**************************************************************



******ACS 2014******

use ipums_acs0614,clear
keep if sample==201401
rename puma puma12
g FIPS=countyfip+statefip*1000
preserve
keep if countyfip==0
keep puma12 statefip
bys puma12 statefip: keep if _n==1
save "$tempdata\acs14_noid_cty",replace
   *****828 puma12-state areas
restore
keep if countyfip!=0
keep FIPS
bys FIPS: keep if _n==1
save "$tempdata\acs14_id_cty",replace
   ****430 identified counties
   
use "$cw_ipums\cw_cty_puma12",clear
drop if FIPS==2105 | FIPS==2158 | FIPS==2195 | FIPS==2198 | FIPS==2230 | ///
FIPS==2275 | FIPS==8014 | FIPS==46102 /*reason illustrated later*/
drop if FIPS==26013 | FIPS==26043 | FIPS==26061 | FIPS==26071 | FIPS==26083 | FIPS==26103
                                       /*reason illustrated later*/
mmerge puma12 statefip using "$tempdata\acs14_noid_cty",type(n:1)
/*
-------------------------------------------------------------------------------
merge specs          |
       matching type | n:1
  mv's on match vars | none
  unmatched obs from | both
---------------------+---------------------------------------------------------
  master        file | E:\Dropbox\Research\Ding's Proposal\WorkingFile\IPUMS\cw_ipum
> s\cw_cty_puma12.dta
                 obs |   4531
                vars |      5
          match vars | puma12 statefip  (not a key)
  -------------------+---------------------------------------------------------
  using         file | E:\Dropbox\Research\Ding's Proposal\WorkingFile\IPUMS\temp_da
> ta\acs14_noid_cty.dta
                 obs |    828
                vars |      2
          match vars | puma12 statefip  (key)
---------------------+---------------------------------------------------------
variables puma12 statefip do not uniquely identify observations in the master data
result          file | E:\Dropbox\Research\Ding's Proposal\WorkingFile\IPUMS\cw_ipum
> s\cw_cty_puma12.dta
                 obs |   4531
                vars |      7  (including _merge)
         ------------+---------------------------------------------------------
              _merge |   1523  obs only in master data                (code==1)
                     |   3008  obs both in master and using data      (code==3)
-------------------------------------------------------------------------------
*/
drop if _merge!=3
drop _merge
merge m:1 FIPS using "$tempdata\acs14_id_cty"
   ***This shows there is no such case that a puma00-state includes a county has been identified
drop if _merge!=1
drop _merge
mmerge FIPS using "$cw_ipums\cw_cty_cz2000",type(n:1)
   ***FIPS 2105, 2158, 2195, 2198, 2230, 2275, 8014*2, 46102 do not match with any czone2000
drop if _merge!=3
drop _merge
sort puma12 statefip
bys puma12 statefip: g num_row=_N
bys puma12 statefip: egen cztotal=total(czone2000)
g cz2000=cztotal/num_row
g dummy=(czone2000==cz2000)
preserve
keep if dummy==1
keep puma12 statefip cz2000
bys puma12 statefip: keep if _n==1
save "$tempdata\acs14_id_cz",replace
    *** 440 puma12-state can be directly matched with a czone2000
restore
keep if dummy==0
destring pop,replace
bys puma12 statefip: egen poptotal=total(pop)
g cty_share=pop/poptotal   /*more accurately, this is cty-to-puma12state ratio. It doesn't matter if 1 cty matches to 2 PUMAs*/
keep FIPS puma12 cty_share statefip
bys puma12 statefip: g num_row=_n
sum num_row
 ****24 is the maxmum number of counties a puma has
save "$tempdata\acs14_noid_wtd",replace


use ipums_acs0614,clear
keep if sample==201401
g FIPS=countyfip+statefip*1000
rename puma puma12
mmerge FIPS using "$cw_ipums\cw_cty_cz2000",type(n:1)
/*
-------------------------------------------------------------------------------
merge specs          |
       matching type | n:1
  mv's on match vars | none
  unmatched obs from | both
---------------------+---------------------------------------------------------
  master        file | ipums_acs0614.dta
                 obs | 3132610
                vars |     31
          match vars | FIPS  (not a key)
  -------------------+---------------------------------------------------------
  using         file | E:\Dropbox\Research\Ding's Proposal\WorkingFile\IPUMS\cw_ipum
> s\cw_cty_cz2000.dta
                 obs |   3141
                vars |      2
          match vars | FIPS  (key)
---------------------+---------------------------------------------------------
variable FIPS does not uniquely identify observations in the master data
(note: variable FIPS was float, now double to accommodate using data's values)
result          file | ipums_acs0614.dta
                 obs | 3135321
                vars |     34  (including _merge)
         ------------+---------------------------------------------------------
              _merge | 1245536  obs only in master data                (code==1)
                     |   2711  obs only in using data                 (code==2)
                     | 1887074  obs both in master and using data      (code==3)
-------------------------------------------------------------------------------

*/
drop if _merge==2
drop _merge
mmerge puma12 statefip using "$tempdata\acs14_id_cz", type(n:1)
/*
-------------------------------------------------------------------------------
merge specs          |
       matching type | n:1
  mv's on match vars | none
  unmatched obs from | both
---------------------+---------------------------------------------------------
  master        file | ipums_acs0614.dta
                 obs | 3132610
                vars |     32
          match vars | puma12 statefip  (not a key)
  -------------------+---------------------------------------------------------
  using         file | E:\Dropbox\Research\Ding's Proposal\WorkingFile\IPUMS\temp_da
> ta\acs14_id_cz.dta
                 obs |    440
                vars |      3
          match vars | puma12 statefip  (key)
---------------------+---------------------------------------------------------
variables puma12 statefip do not uniquely identify observations in the master data
result          file | ipums_acs0614.dta
                 obs | 3132610
                vars |     35  (including _merge)
         ------------+---------------------------------------------------------
              _merge | 2539119  obs only in master data                (code==1)
                     | 593491  obs both in master and using data      (code==3)
-------------------------------------------------------------------------------

*/
replace czone2000=cz2000 if czone2000==.
drop cz2000 _merge
preserve
keep if missing(czone2000)
save "$tempdata\acs14_noid",replace
restore
keep if czone2000!=.
save "$tempdata\acs14_id",replace
   

use "$tempdata\acs14_noid",clear
drop FIPS
expand 24
bys serial pernum: g num_row=_n
mmerge puma12 statefip num_row using "$tempdata\acs14_noid_wtd",type(n:1)
   ****FIPS 26013,26043,26061, 26071, 26083, 26106 only appear in cw, so dropped(at the beginning)
drop if _merge==1
sort serial pernum
drop czone2000 _merge num_row
replace perwt=perwt*cty_share
drop cty_share
merge m:1 FIPS using "$cw_ipums\cw_cty_cz2000"
drop if _merge!=3
drop _merge
append using "$tempdata\acs14_id"
egen population=total(perwt)


************reclassify occsoc to match other samples (census00, acs14, marinescu)**********
replace occsoc="111011" if occsoc=="1110XX"
replace occsoc="113040" if occsoc=="113111" | occsoc=="113121" | occsoc=="113131"
replace occsoc="119199" if occsoc=="119161" | occsoc=="119XXX"
replace occsoc="1311XX" if occsoc=="131131" | occsoc=="131141" | occsoc=="131151" | occsoc=="131161" | occsoc=="131199"
replace occsoc="1510XX" if occsoc=="151111" | occsoc=="151121" | occsoc=="151122"
replace occsoc="151021" if occsoc=="151131"
replace occsoc="151030" if occsoc=="15113X" | occsoc=="151134"
replace occsoc="151041" if occsoc=="151150"
replace occsoc="151061" if occsoc=="151141"
replace occsoc="151071" if occsoc=="151142"
replace occsoc="151081" if occsoc=="151143" | occsoc=="151199"
replace occsoc="172XXX" if occsoc=="1720XX" | occsoc=="1721YY"
replace occsoc="191040" if occsoc=="1910XX"
replace occsoc="1940XX" if occsoc=="1940YY"
replace occsoc="211090" if occsoc=="211092" | occsoc=="211093" | occsoc=="21109X"
replace occsoc="2310XX" if occsoc=="231012"
replace occsoc="252040" if occsoc=="252050"
replace occsoc="291111" if occsoc=="291141" | occsoc=="291151" | occsoc=="2911XX"
replace occsoc="291121" if occsoc=="291181"
replace occsoc="291129" if occsoc=="29112X"
replace occsoc="31909X" if occsoc=="319092" | occsoc=="319094" | occsoc=="319095" | occsoc=="319096" | occsoc=="319097"
replace occsoc="33909X" if occsoc=="339093"
replace occsoc="394000" if occsoc=="3940XX" | occsoc=="394031"
drop if occsoc=="433099"
replace occsoc="451010" if occsoc=="451011"
replace occsoc="472020" if occsoc=="472XXX"
replace occsoc="499042" if occsoc=="499071"
replace occsoc="49909X" if occsoc=="4990XX"
drop if occsoc=="513099"
replace occsoc="515023" if occsoc=="515112" | occsoc=="515113"
drop if occsoc=="532031" | occsoc=="533011"
replace occsoc="5360XX" if occsoc=="536061"
replace occsoc="537041" if occsoc=="5370XX"



******last step, aggregate ind1990 to IFRind******

g IFRind="n/a"
replace IFRind="agriculture" if ind1990>=10 & ind1990<=32
replace IFRind="mining" if ind1990>=40 & ind1990<=50
replace IFRind="construction" if ind1990==60
replace IFRind="food" if ind1990>=100 & ind1990<=130
replace IFRind="textiles" if ind1990>=132 & ind1990<=152
replace IFRind="paper" if ind1990>=160 & ind1990<=172
replace IFRind="petrochemicals" if ind1990>=180 & ind1990<=222
replace IFRind="furniture" if ind1990>=230 & ind1990<=242
replace IFRind="mineral" if ind1990>=250 & ind1990<=262
replace IFRind="metal_basic" if ind1990>=270 & ind1990<=280
replace IFRind="metal_products" if ind1990>=281 & ind1990<=301
replace IFRind="metal_machinery" if ind1990>=310 & ind1990<=332
replace IFRind="electronics" if ind1990>=340 & ind1990<=350
replace IFRind="automotive" if ind1990==351
replace IFRind="vehicles_other" if ind1990>=352 & ind1990<=370
replace IFRind="manufacturing_other" if ind1990>=371 & ind1990<=392
replace IFRind="utilities" if ind1990>=400 & ind1990<=472
replace IFRind="services" if (ind1990>=500 & ind1990<=841) | (ind1990>=861 & ind1990<=960 & ind1990!=891) 
replace IFRind="research" if (ind1990>=842 & ind1990<=860) | ind1990==891
save imputed_acs14,replace
