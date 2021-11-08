clear

* For more details, see https://michaelstepner.com/maptile/ or the STATA help file for maptile

ssc install maptile
ssc install spmap

loc pathDL "E:\Dropbox\RA_Ding\mapCZ"
loc path "`pathDL'"
loc dataPathDL "E:\Dropbox\RA_Ding\datafile"
loc geofolder "`path'\geo_templates\cz"
cd "`path'"

use CBPczyr_08,clear
keep if year==2008 | year==2000
replace empc=-empc if year==2000
bys czone: egen d_empc=total(empc)
bys czone: keep if _n==1
g d_emppop=d_emp/cz_workpop
keep czone d_emppop
save empchange0008,replace

use "`geofolder'\cz_database.dta", clear
	* This is the map file
	
mmerge cz using "`dataPathDL'\reliabilityCZ.dta", umatch(czone) type(1:1)
	* This contains the data to be shown on the maptile
keep if _merge==3
	* drops AK, HI

mmerge cz using "`dataPathDL'\vulnerabilityCZ.dta", umatch(czone) type(1:1)
mmerge cz using "`dataPathDL'\sensitivityCZ.dta", umatch(czone) type(1:1)
	* all m=3
mmerge cz using "empchange0008", umatch(czone) type(1:1)

g neg_d_emppop=-d_emppop

maptile neg_d_emppop, geo(cz) geofolder(`geofolder') conus stateoutline(medium) fcolor(GnBu) nquantiles(5) twopt(legend(lab(2 "<20th") lab(3 "20th-40th") lab(4 "40th-60th") lab(5 "60th-80th") lab(6 ">80th"))) savegraph("czEmppop.png") replace
maptile R_331111_1_1, geo(cz) geofolder(`geofolder') conus stateoutline(medium) fcolor(GnBu) nquantiles(5) twopt(legend(lab(2 "<20th") lab(3 "20th-40th") lab(4 "40th-60th") lab(5 "60th-80th") lab(6 ">80th"))) savegraph("czReliability.png") replace
maptile v_1_1_1, geo(cz) geofolder(`geofolder') conus stateoutline(medium) fcolor(GnBu) nquantiles(5) twopt(legend(lab(2 "<20th") lab(3 "20th-40th") lab(4 "40th-60th") lab(5 "60th-80th") lab(6 ">80th"))) savegraph("czVulnerability.png") replace
maptile s1, geo(cz) geofolder(`geofolder') conus stateoutline(medium) fcolor(GnBu) cutvalues(0 0.1 1 5 10 50) twopt(legend(lab(2 "0") lab(3 "0-0.1") lab(4 "0.1-1") lab(5 "1-5") lab(6 "5-10") lab(7 "10-50") lab(8 ">50"))) savegraph("czSensitivity.png") replace
*maptile s1, geo(cz) geofolder(`geofolder') conus stateoutline(medium) fcolor(GnBu) nquantiles(9) savegraph("czSensitivityJL.png") replace

