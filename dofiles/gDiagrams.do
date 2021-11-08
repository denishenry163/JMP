clear all
global ipums "E:\Dropbox\Research\Ding's Proposal\WorkingFile\empirical_v2"
global tempdata "E:\Dropbox\Research\Ding's Proposal\WorkingFile\empirical_v2\temp_data"
global cw_ipums "E:\Dropbox\Research\Ding's Proposal\WorkingFile\empirical_v2\cw_ipums"
global dofiles "E:\Dropbox\Research\Ding's Proposal\WorkingFile\empirical_v2\dofiles"
global datafiles "E:\Dropbox\Research\Ding's Proposal\WorkingFile\empirical_v2\datafiles"
global results "E:\Dropbox\Research\Ding's Proposal\WorkingFile\empirical_v2\results"
global graphs "E:\Dropbox\Research\Ding's Proposal\WorkingFile\empirical_v2\graphs"
global mapCZ "E:\Dropbox\Research\Ding's Proposal\WorkingFile\empirical_v2\mapCZ"
global geofolder "$mapCZ\geo_templates\cz2000"
global JMPproposal "E:\Dropbox\Research\Ding's Proposal\WorkingFile\JMPproposal"
global countries "DK" "FI" "FR" "DE" "IT" "JP" "SE" "UK" "US"
global demographic share_male share_nonwhite share_elder share_nocoll share_somecoll share_collprof share_mastdoc share_emp_manuf
cd "$datafiles"
**********************************************************
************************** Maps **************************
**********************************************************

*** map of cz-level robot exposure (weighted by market-level employment)
*** map of cz-level emp-to-workpopulation ratio change (weighted by market-level employment)
*** map of cz-level HHI (weighted by market-level employment)

* For more details, see https://michaelstepner.com/maptile/ or the STATA help file for maptile

cd "$mapCZ"

ssc install maptile
ssc install spmap

use "$datafiles\dep_emp0614",clear
merge m:1 czone2000 using "$cw_ipums\cw_state_cz2000"
drop if _merge!=3
drop _merge
merge m:1 state using "$cw_ipums\cw_state_division"
drop if _merge!=3
drop _merge
sort czone2000 occsoc

	bys czone2000: egen emp06_workpop06_ratio_cz_sample=total(emp06_workpop06_ratio)
	bys czone2000: egen emp14_workpop06_ratio_cz_sample=total(emp14_workpop06_ratio)
	g d_emp_workpop06_ratio_cz_sample=emp14_workpop06_ratio_cz_sample-emp06_workpop06_ratio_cz_sample

collapse (mean) er_us_emp06 d_emp_workpop06_ratio_cz d_emp_workpop06_ratio_cz_sample er_eu hhi_new [w=emp_lm06], by(czone2000)
save exposure,replace

use "$geofolder\cz2000_database.dta", clear
	* This is the map file
	
mmerge cz using exposure.dta, umatch(czone2000) type(1:1)
	* This contains the data to be shown on the maptile
keep if _merge==3
	* drops AK, HI

maptile er_us_emp06, geo(cz2000) geofolder($geofolder) conus stateoutline(medium) fcolor(GnBu) nquantiles(9) twopt(title("Panel A: The US exposure to robots in 2006-2014", size(14pt) pos(11)) legend(title("Quantiles", size(12pt)))) savegraph("ExposureUS.png") replace

maptile er_eu, geo(cz2000) geofolder($geofolder) conus stateoutline(medium) fcolor(GnBu) nquantiles(9) twopt(title("Panel B: The EURO5 exposure to robots in 2006-2014", size(14pt) pos(11)) legend(title("Quantiles", size(12pt)))) savegraph("ExposureEU.png") replace

maptile d_emp_workpop06_ratio_cz, geo(cz2000) geofolder($geofolder) conus stateoutline(medium) fcolor(GnBu) nquantiles(9) twopt(title("Panel A: The change in the employment-to-population ratio in the ACS sample in 2006-2014", size(10pt) pos(11)) legend(title("Quantiles", size(12pt)))) savegraph("EmpchangePopulation.png") replace

maptile d_emp_workpop06_ratio_cz_sample, geo(cz2000) geofolder($geofolder) conus stateoutline(medium) fcolor(GnBu) nquantiles(9) twopt(title("Panel B: The change in the employment-to-population ratio in the regression sample in 2006-2014", size(10pt) pos(11)) legend(title("Quantiles", size(12pt)))) savegraph("EmpchangeSample.png") replace

maptile hhi_new, geo(cz2000) geofolder($geofolder) conus stateoutline(medium) fcolor(GnBu) nquantiles(9) twopt(title("Average HHI in 2006-2014", size(14pt) pos(11)) legend(title("Quantiles", size(12pt)))) savegraph("HHI_US.png") replace

	
************************************************************
************************** Figures **************************
************************************************************

************************************ data *************************************

cd "$datafiles"
*** 2000-2014 robot adoption of U.S., Japan, Germany and Euro five countries

foreach i in "$countries" "EU"{
import excel "$graphs\\`i'.xls",clear
g year=year(A)
drop A
rename B employment
g country="`i'"
save "$graphs\\`i'",replace
}


use robot_world,clear
keep if country=="DK" |country=="FI"| country=="FR"| country=="DE" |country=="IT"| country=="JP" |country=="SE"| country=="UK" |country=="US"
keep if year>=2000
keep if industry=="000"
foreach i in "$countries" {
merge 1:1 country year using "$graphs\\`i'.dta",update
keep if year<=2017
drop _merge
}
replace country="euro5" if country=="DK" |country=="FI"| country=="FR"| country=="SE" |country=="IT"
bys country year: egen totrobot=total(operationalstock)
replace operationalstock=totrobot
bys country year: egen totemp=total(employment)
replace employment=totemp
bys country year: keep if _n==1
drop totrobot totemp
g robotpercap=operationalstock/employment*1000
twoway (connected robotpercap year if country=="DE", msymbol(square)) (connected robotpercap year if country=="US", msymbol(triangle)) (connected robotpercap year if country=="euro5", msymbol(circle)) (connected robotpercap year if country=="JP", msymbol(diamond)) (connected robotpercap year if country=="UK", msymbol(arrow)), legend(lab(1 "Germany") lab(2 "United States") lab(3 "Denmark, Finland, France, Switzerland, Italy") lab(4 "Japan") lab(5 "UK")) xlabel(2000(5)2017) xtitle("Year") ytitle("Robot stock per thousand workers") graphregion(color(white)) saving("$graphs\robotpercapita", replace)



******* IFR graph 2 *****

use robot_world,clear
	preserve
	bys v5: keep if _n==1
	keep country v5
	save "$graphs\countrylist",replace
	restore
	*keep if country=="CEU" | country=="EU" | country=="EUU" | country=="REU" | country=="WEU" | country=="OEU" | country=="OEE"
keep if country=="US" | country=="EU"
keep if industry=="000"
replace operationalstock=operationalstock/100000
/*
merge 1:1 country year using "$graphs\EU.dta"
keep if year<=2017
drop _merge
merge 1:1 country year using "$graphs\US.dta",update
drop _merge 
drop if missing(employment) | year==2000
g robotpercap=operationalstock/employment*1000
*/
label variable operationalstock "Robot stock"
twoway (connected operationalstock year if country=="US", msymbol(triangle hollow) mlcolor(gs1) mfcolor(red) lp(solid) lc(gs1)) (connected operationalstock year if country=="EU", msymbol(smcircle) mlcolor(gs1) mfcolor(green) lp(solid) lc(gs1)), legend(lab(1 "US robot stock") lab(2 "Europe robot stock") size(2)) xlabel(1990(5)2020) xtitle("Year") ytitle("Robot stock ({it:in 10{sup:5}})") graphregion(color(white))

graph save "$graphs\robots_USEU.png", replace

***************************** summary and results ******************************

********************************************************************
************************** Summary Tables **************************
********************************************************************
cd "$datafiles"

use hhi_2016,clear
sum hhi2016,d
sum hhi2016 if ranking_size<=100,d
sum hhi2016 if ranking_size<=200,d
sum hhi2016 if ranking_size<=50,d
sum hhi2016 if ranking_size>=700,d

use regemp,clear
g hhi_new_10000=hhi_new*10000
sum hhi_new,d
sum hhi_new_10000,d
g d_emp_workpop06_ratio_1000=d_emp_workpop06_ratio/1000
sum d_emp_workpop06_ratio
collapse (mean) hhi_new_10000 [w=emp_lm06], by(occsoc)
sum hhi_new_10000
sort hhi

use regwage,clear
sum d_wage_0614
sum wage_lm06,d
sum wage_lm14,d
bro if wage_lm06==509000

use regemp,clear
sum er_us_emp06
sum er_eu
sum interaction
sum emp_lm06
sum emp_lm14
preserve
bys czone2000:keep if _n==1
sum cz_pop
sum cz_workpop
restore
sum emp06_workpop06_ratio
sum share_male
sum share_elder
sum share_nocoll
sum share_somecoll
sum share_collprof
sum share_mastdoc
sum share_nonwhite
sum share_emp_manuf
********************************************************************
************************** Results Tables **************************
********************************************************************

/*

********* results 1 ***********
use regemp,clear
label var er_us_emp06 "Exposure to Robots"
ivreg2 d_emp_workpop06_ratio (er_us_emp06=er_eu), endog(er_us_emp06) cluster(state) 
		eststo result1col1
		eststo result1col1, add(Observations e(N))
		eststo result1col1, add(Underidentification e(idp))   /*Underidentification test with Kleibergen-Paap rk LM statistic*/
		eststo result1col1, add(Weakidentification e(widstat))   /*Weak identification test with Kleibergen-Paap rk Wald F statistic*/
		*** no hansen j statistics when equation is exactly identified
		*eststo result1col1, add(Overidentification e(jp))
		eststo result1col1, add(Endogeneity e(estatp))  /*Endogeneity test*/

ivreghdfe d_emp_workpop06_ratio (er_us_emp06=er_eu), absorb(division) endog(er_us_emp06) cluster(state)
		eststo result1col2
		eststo result1col2, add(Observations e(N))
		eststo result1col2, add(Underidentification e(idp))
		eststo result1col2, add(Weakidentification e(widstat))
		*** no hansen j statistics when equation is exactly identified
		*eststo result1col1, add(Overidentification e(jp))
		eststo result1col2, add(Endogeneity e(estatp))

ivreghdfe d_emp_workpop06_ratio (er_us_emp06=er_eu) $demographic, absorb(division) endog(er_us_emp06) cluster(state)
		eststo result1col3
		eststo result1col3, add(Observations e(N))
		eststo result1col3, add(Underidentification e(idp))
		eststo result1col3, add(Weakidentification e(widstat))
		*** no hansen j statistics when equation is exactly identified
		*eststo result1col1, add(Overidentification e(jp))
		eststo result1col3, add(Endogeneity e(estatp))

ivreghdfe d_emp_workpop06_ratio (er_us_emp06=er_eu) $demographic, absorb(occsoc division) endog(er_us_emp06) cluster(state)
		eststo result1col4
		eststo result1col4, add(Observations e(N))
		eststo result1col4, add(Underidentification e(idp))
		eststo result1col4, add(Weakidentification e(widstat))  
		*** no hansen j statistics when equation is exactly identified
		*eststo result1col1, add(Overidentification e(jp))
		eststo result1col4, add(Endogeneity e(estatp))


************************************
********* MAKE LATEX TABLE *********
************************************

esttab result1col1 result1col2 result1col3 result1col4 ///
	using "$JMPproposal\result_acemoglucopyemp.tex", ///
	se nonotes  style(tex)  b(%12.3f) se(%12.3f)  ///
	starlevels(* 0.10 ** 0.05 *** 0.01) scalar(Underidentification Weakidentification Endogeneity) label mlabels("" "" "" "" "" "" "" "" "" "" ) ///
	 keep(er_us_emp06) nonumbers  replace  fragment  ///
	 prehead(\begin{center} ///
				\caption{Effect of Exposure to Robots on Employment: IV estimates} ///
			\scalebox{1}[1]{\begin{threeparttable} ///
			{\begin{tabular}{lcccccccccc} ///
			\hline \hline ///
			& \multicolumn{4}{c}{TSLS} \\ \cline{2-5} ///
			& (1) & (2) & (3) & (4) \\) ///
	 prefoot( \\ ) ///
	 postfoot( ///
			\hline ///
			"Census divisions" & & \checkmark & \checkmark & \checkmark \\ ///
			"Demographics" & & & \checkmark & \checkmark \\ ///
			"Occupation fixed effects" & & & & \checkmark \\ ///
			\hline \hline \end{tabular} } ///
			\begin{tablenotes}[para,flushleft] ///
				\footnotesize{NOTES. Table \ref{acemoglucopyemp} estimates the effect of exposure to robots on employment with each market being defined as a CZ-by-SOC cell. The US exposure to robots is instrumented by EURO5 exposure to robots. The demographic characteristics include the share of male, the share of elders (over 65), the share of the population with no college, some college, college or professional, and master or doctoral degree, the share of non-white, and the share of manufacturing industry workers. Errors are clustered within states. The under-identification test reports p-value of the Kleibergen-Paap LM statistic. The weak identification test reports the Kleibergen-Paap Wald F statistic. The over-identification test reports p-value of the Hansen J statistic. The endogeneity test reports p-value of the chi-square statistic. * p $<$.10, ** p$<$ .05, *** p$<$.01.} ///
			\end{tablenotes} ///
			\end{threeparttable}} ///
			\label{acemoglucopyemp} ///
			\end{center})
	  

	  
********* results 2 ***********
use regemp,clear
label var er_us_emp06 "Exposure to Robots"
label var hhi_new "HHI"
label var interaction "HHI*Exposure to Robots"
ivreghdfe d_emp_workpop06_ratio (er_us_emp06 interaction=er_eu ///
					ivinteraction) hhi_new $demographic, absorb(occsoc) endog(er_us_emp06 interaction) cluster(state)
		eststo result2col1
		eststo result2col1, add(Observations e(N))
		eststo result2col1, add(Underidentification e(idp))
		eststo result2col1, add(Weakidentification e(widstat))
		eststo result2col1, add(Endogeneity e(estatp))

ivreghdfe d_emp_workpop06_ratio (er_us_emp06 interaction=er_eu ///
					ivinteraction) hhi_new $demographic [weight=emp_lm06], absorb(occsoc) endog(er_us_emp06 interaction) cluster(state)
		eststo result2col2
		eststo result2col2, add(Observations e(N))
		eststo result2col2, add(Underidentification e(idp))
		eststo result2col2, add(Weakidentification e(widstat))
		eststo result2col2, add(Endogeneity e(estatp))

ivreghdfe d_emp_workpop06_ratio (er_us_emp06 interaction=er_eu ///
					ivinteraction) hhi_new $demographic, absorb(occsoc state) endog(er_us_emp06 interaction) cluster(state)
		eststo result2col3
		eststo result2col3, add(Observations e(N))
		eststo result2col3, add(Underidentification e(idp))
		eststo result2col3, add(Weakidentification e(widstat))
		eststo result2col3, add(Endogeneity e(estatp))

ivreghdfe d_emp_workpop06_ratio (er_us_emp06 interaction=er_eu ///
					ivinteraction) hhi_new $demographic [weight=emp_lm06], absorb(occsoc state) endog(er_us_emp06 interaction) cluster(state)
		eststo result2col4
		eststo result2col4, add(Observations e(N))
		eststo result2col4, add(Underidentification e(idp))
		eststo result2col4, add(Weakidentification e(widstat))
		eststo result2col4, add(Endogeneity e(estatp))
		
************************************
********* MAKE LATEX TABLE *********
************************************

esttab result2col1 result2col2 result2col3 result2col4 ///
	using "$JMPproposal\result_noIVforHHIemp.tex", ///
	se nonotes  style(tex)  b(%12.3f) se(%12.3f)  ///
	starlevels(* 0.10 ** 0.05 *** 0.01) scalar(Underidentification Weakidentification Endogeneity) label mlabels("" "" "" "" "" "" "" "" "" "" ) ///
	 keep(er_us_emp06 hhi_new interaction) nonumbers  replace  fragment  ///
	 prehead(\begin{center} ///
				\caption{Effect of Exposure to Robots on Employment in Concentrated Market: IV for ER} ///
			\scalebox{1.2}[1.2]{\begin{threeparttable} ///
			{\begin{tabular}{lcccccccccc} ///
			\hline \hline ///
			& \multicolumn{4}{c}{TSLS} \\ \cline{2-5} ///
			& (1) & (2) & (3) & (4) \\) ///
	 prefoot( \\ ) ///
	 postfoot( ///
			\hline ///
			"Occupation fixed effects" & \checkmark & \checkmark & \checkmark & \checkmark \\ ///
			"Demographics" & \checkmark & \checkmark & \checkmark & \checkmark \\ ///
			"State fixed effects" & & & \checkmark & \checkmark \\ ///
			"Weighted" & & \checkmark & & \checkmark \\ ///
			\hline \hline \end{tabular} } ///
			\begin{tablenotes}[para,flushleft] ///
				\footnotesize{NOTES. Table \ref{noIVforHHIemp} presents the variation of the effect of exposure to robots on employment across markets with different concentration level. The US market-level exposure to robots is instrumented by EURO5-based market-level exposure to robots. The demographic characteristics include the share of male, the share of elders (over 65), the share of the population with no college, some college, college or professional, and master or doctoral degree, the share of non-white, and the share of manufacturing industry workers. Errors are clustered within states. The under-identification test reports p-value of the Kleibergen-Paap LM statistic. The weak identification test reports the Kleibergen-Paap Wald F statistic. The over-identification test reports p-value of the Hansen J statistic. The endogeneity test reports p-value of the chi-square statistic. * p $<$.10, ** p$<$ .05, *** p$<$.01.} ///
			\end{tablenotes} ///
			\end{threeparttable}} ///
			\label{noIVforHHIemp} ///
			\end{center})


			
			
********* results 3 ***********
use regemp,clear
label var er_us_emp06 "Exposure to Robots"
label var hhi_new "HHI"
label var interaction "HHI*Exposure to Robots"
ivreghdfe d_emp_workpop06_ratio (er_us_emp06 interaction hhi_new=er_eu ccollprof_ehat cmanuf_ehat ivinteraction2 ivinteraction5) $demographic, absorb(occsoc) endog(er_us_emp06 hhi_new interaction) cluster(state)
		eststo result3col1
		eststo result3col1, add(Observations e(N))
		eststo result3col1, add(Underidentification e(idp))
		eststo result3col1, add(Weakidentification e(widstat))
		eststo result3col1, add(Overidentification e(jp))
		eststo result3col1, add(Endogeneity e(estatp))

ivreghdfe d_emp_workpop06_ratio (er_us_emp06 interaction hhi_new=er_eu ccollprof_ehat cmanuf_ehat ivinteraction2 ivinteraction5) $demographic [weight=emp_lm06], absorb(occsoc) endog(er_us_emp06 hhi_new interaction) cluster(state)
		eststo result3col2
		eststo result3col2, add(Observations e(N))
		eststo result3col2, add(Underidentification e(idp))
		eststo result3col2, add(Weakidentification e(widstat))
		eststo result3col2, add(Overidentification e(jp))
		eststo result3col2, add(Endogeneity e(estatp))
		
ivreghdfe d_emp_workpop06_ratio (er_us_emp06 interaction hhi_new=er_eu ccollprof_ehat_2 cmanuf_ehat_2 ivinteraction2_2 ivinteraction3_2) $demographic, absorb(occsoc state) endog(er_us_emp06 hhi_new interaction) cluster(state)
		eststo result3col3
		eststo result3col3, add(Observations e(N))
		eststo result3col3, add(Underidentification e(idp))
		eststo result3col3, add(Weakidentification e(widstat))
		eststo result3col3, add(Overidentification e(jp))
		eststo result3col3, add(Endogeneity e(estatp))

ivreghdfe d_emp_workpop06_ratio (er_us_emp06 interaction hhi_new=er_eu ccollprof_ehat_2 cmanuf_ehat_2 ivinteraction2_2 ivinteraction3_2) $demographic [weight=emp_lm06], absorb(occsoc state) endog(er_us_emp06 hhi_new interaction) cluster(state)
		eststo result3col4
		eststo result3col4, add(Observations e(N))
		eststo result3col4, add(Underidentification e(idp))
		eststo result3col4, add(Weakidentification e(widstat))
		eststo result3col4, add(Overidentification e(jp))
		eststo result3col4, add(Endogeneity e(estatp))
		
************************************
********* MAKE LATEX TABLE *********
************************************

esttab result3col1 result3col2 result3col3 result3col4 ///
	using "$JMPproposal\result_LewbelIV1forHHIemp.tex", ///
	se nonotes  style(tex)  b(%12.3f) se(%12.3f)  ///
	starlevels(* 0.10 ** 0.05 *** 0.01) scalar(Underidentification Weakidentification Overidentification Endogeneity) label mlabels("" "" "" "" "" "" "" "" "" "" ) ///
	 keep(er_us_emp06 hhi_new interaction) nonumbers  replace  fragment  ///
	 prehead(\begin{center} ///
				\caption{Effect of Exposure to Robots on Employment in Concentrated Market: Lewbel IV set 1 for HHI} ///
			\scalebox{1.2}{\begin{threeparttable} ///
			{\begin{tabular}{lcccccccccc} ///
			\hline \hline ///
			& \multicolumn{4}{c}{TSLS} \\ \cline{2-5} ///
			& (1) & (2) & (3) & (4) \\) ///
	 prefoot( \\ ) ///
	 postfoot( ///
			\hline ///
			"Occupation fixed effects" & \checkmark & \checkmark & \checkmark & \checkmark \\ ///
			"Demographics" & \checkmark & \checkmark & \checkmark & \checkmark \\ ///
			"State fixed effects" & & & \checkmark & \checkmark \\ ///
			"Weighted" & & \checkmark & & \checkmark \\ ///
			\hline \hline \end{tabular} } ///
			\begin{tablenotes}[para,flushleft] ///
				\footnotesize{NOTES. Table \ref{LewbelIV1forHHIemp} presents the variation of the effect of exposure to robots on employment across markets with different concentration levels. The US exposure to robots is instrumented by EURO5 exposure to robots. I used Lewbel's heteroskedasticity-based IV set 1, including the share of the population with college or professional degree and the share of manufacturing workers in the market, to instrument HHI. The demographic characteristics include the share of male, the share of elders (over 65), the share of the population with no college, some college, college or professional, and master or doctoral degree, the share of non-white, and the share of manufacturing industry workers. Errors are clustered within states. The under-identification test reports p-value of the Kleibergen-Paap LM statistic. The weak identification test reports the Kleibergen-Paap Wald F statistic. The over-identification test reports p-value of the Hansen J statistic. The endogeneity test reports p-value of the chi-square statistic. * p $<$.10, ** p$<$ .05, *** p$<$.01.} ///
			\end{tablenotes} ///
			\end{threeparttable}} ///
			\label{LewbelIV1forHHIemp} ///
			\end{center})


			
********* results 4 ***********
use regemp,clear
label var er_us_emp06 "Exposure to Robots"
label var hhi_new "HHI"
label var interaction "HHI*Exposure to Robots"
ivreghdfe d_emp_workpop06_ratio (er_us_emp06 interaction hhi_new=er_eu cnocoll_ehat cmanuf_ehat ivinteraction3 ivinteraction5) $demographic, absorb(occsoc) endog(er_us_emp06 hhi_new interaction) cluster(state)
		eststo result4col1
		eststo result4col1, add(Observations e(N))
		eststo result4col1, add(Underidentification e(idp))
		eststo result4col1, add(Weakidentification e(widstat))
		eststo result4col1, add(Overidentification e(jp))
		eststo result4col1, add(Endogeneity e(estatp))

ivreghdfe d_emp_workpop06_ratio (er_us_emp06 interaction hhi_new=er_eu cnocoll_ehat cmanuf_ehat ivinteraction3 ivinteraction5) $demographic [weight=emp_lm06], absorb(occsoc) endog(er_us_emp06 hhi_new interaction) cluster(state)
		eststo result4col2
		eststo result4col2, add(Observations e(N))
		eststo result4col2, add(Underidentification e(idp))
		eststo result4col2, add(Weakidentification e(widstat))
		eststo result4col2, add(Overidentification e(jp))
		eststo result4col2, add(Endogeneity e(estatp))
		
ivreghdfe d_emp_workpop06_ratio (er_us_emp06 interaction hhi_new=er_eu cnocoll_ehat_2 cmanuf_ehat_2 ivinteraction5_2 ivinteraction3_2) $demographic, absorb(occsoc state) endog(er_us_emp06 hhi_new interaction) cluster(state)
		eststo result4col3
		eststo result4col3, add(Observations e(N))
		eststo result4col3, add(Underidentification e(idp))
		eststo result4col3, add(Weakidentification e(widstat))
		eststo result4col3, add(Overidentification e(jp))
		eststo result4col3, add(Endogeneity e(estatp))
		
ivreghdfe d_emp_workpop06_ratio (er_us_emp06 interaction hhi_new=er_eu cnocoll_ehat_2 cmanuf_ehat_2 ivinteraction5_2 ivinteraction3_2) $demographic [weight=emp_lm06], absorb(occsoc state) endog(er_us_emp06 hhi_new interaction) cluster(state)
		eststo result4col4
		eststo result4col4, add(Observations e(N))
		eststo result4col4, add(Underidentification e(idp))
		eststo result4col4, add(Weakidentification e(widstat))
		eststo result4col4, add(Overidentification e(jp))
		eststo result4col4, add(Endogeneity e(estatp))
	
		
************************************
********* MAKE LATEX TABLE *********
************************************

esttab result4col1 result4col2 result4col3 result4col4 ///
	using "$JMPproposal\result_LewbelIV2forHHIemp.tex", ///
	se nonotes  style(tex)  b(%12.3f) se(%12.3f)  ///
	starlevels(* 0.10 ** 0.05 *** 0.01) scalar(Underidentification Weakidentification Overidentification Endogeneity) label mlabels("" "" "" "" "" "" "" "" "" "" ) ///
	 keep(er_us_emp06 hhi_new interaction) nonumbers  replace  fragment  ///
	 prehead(\begin{center} ///
				\caption{Effect of Exposure to Robots on Employment in Concentrated Market: Lewbel IV set 2 for HHI} ///
			\scalebox{1.2}{\begin{threeparttable} ///
			{\begin{tabular}{lcccccccccc} ///
			\hline \hline ///
			& \multicolumn{4}{c}{TSLS} \\ \cline{2-5} ///
			& (1) & (2) & (3) & (4) \\) ///
	 prefoot( \\ ) ///
	 postfoot( ///
			\hline ///
			"Occupation fixed effects" & \checkmark & \checkmark & \checkmark & \checkmark \\ ///
			"Demographics" & \checkmark & \checkmark & \checkmark & \checkmark \\ ///
			"State fixed effects" & & & \checkmark & \checkmark \\ ///
			"Weighted" & & \checkmark & & \checkmark \\ ///
			\hline \hline \end{tabular} } ///
			\begin{tablenotes}[para,flushleft] ///
				\footnotesize{NOTES. Table \ref{LewbelIV2forHHIemp} presents the variation of the effect of exposure to robots on employment across markets with different concentration levels. The US exposure to robots is instrumented by EURO5 exposure to robots. I use Lewbel's heteroskedasticity-based IV set 1, including the share of non-college, the share of manufacturing workers in the market, to instrument HHI. The demographic characteristics include the share of male, the share of elders (over 65), the share of the population with no college, some college, college or professional, and master or doctoral degree, the share of non-white, and the share of manufacturing industry workers. Errors are clustered within states. The under-identification test reports p-value of the Kleibergen-Paap LM statistic. The weak identification test reports the Kleibergen-Paap Wald F statistic. The over-identification test reports p-value of the Hansen J statistic. The endogeneity test reports p-value of the chi-square statistic. * p $<$.10, ** p$<$ .05, *** p$<$.01.} ///
			\end{tablenotes} ///
			\end{threeparttable}} ///
			\label{LewbelIV2forHHIemp} ///
			\end{center})

			
			
			
********* results 5 ***********
use regwage,clear
label var er_us_emp06 "Exposure to Robots"
label var hhi_new "HHI"
label var interaction "HHI*Exposure to Robots"
ivreg2 d_lnwage_0614 (er_us_emp06=er_eu), endog(er_us_emp06) cluster(state)
		eststo result5col1
		eststo result5col1, add(Observations e(N))
		eststo result5col1, add(Underidentification e(idp))
		eststo result5col1, add(Weakidentification e(widstat))
		eststo result5col1, add(Endogeneity e(estatp))

ivreghdfe d_lnwage_0614 (er_us_emp06=er_eu), absorb(division) endog(er_us_emp06) cluster(state)
		eststo result5col2
		eststo result5col2, add(Observations e(N))
		eststo result5col2, add(Underidentification e(idp))
		eststo result5col2, add(Weakidentification e(widstat))
		eststo result5col2, add(Endogeneity e(estatp))

ivreghdfe d_lnwage_0614 (er_us_emp06=er_eu) $demographic, absorb(division) endog(er_us_emp06) cluster(state)
		eststo result5col3
		eststo result5col3, add(Observations e(N))
		eststo result5col3, add(Underidentification e(idp))
		eststo result5col3, add(Weakidentification e(widstat))
		eststo result5col3, add(Endogeneity e(estatp))

ivreghdfe d_lnwage_0614 (er_us_emp06=er_eu) $demographic, absorb(occsoc division) endog(er_us_emp06) cluster(state)
		eststo result5col4
		eststo result5col4, add(Observations e(N))
		eststo result5col4, add(Underidentification e(idp))
		eststo result5col4, add(Weakidentification e(widstat))
		eststo result5col4, add(Endogeneity e(estatp))

		
************************************
********* MAKE LATEX TABLE *********
************************************

esttab result5col1 result5col2 result5col3 result5col4 ///
	using "$JMPproposal\result_acemoglucopywage.tex", ///
	se nonotes  style(tex)  b(%12.3f) se(%12.3f)  ///
	starlevels(* 0.10 ** 0.05 *** 0.01) scalar(Underidentification Weakidentification Endogeneity) label mlabels("" "" "" "" "" "" "" "" "" "" ) ///
	 keep(er_us_emp06) nonumbers  replace  fragment  ///
	 prehead(\begin{center} ///
				\caption{Effect of Exposure to Robots on Wage: IV estimates} ///
			\scalebox{1}[1]{\begin{threeparttable} ///
			{\begin{tabular}{lcccccccccc} ///
			\hline \hline ///
			& \multicolumn{4}{c}{TSLS} \\ \cline{2-5} ///
			& (1) & (2) & (3) & (4) \\) ///
	 prefoot( \\ ) ///
	 postfoot( ///
			\hline ///
			"Census divisions" & & \checkmark & \checkmark & \checkmark \\ ///
			"Demographics" & & & \checkmark & \checkmark \\ ///
			"Occupation fixed effects" & & & & \checkmark \\ ///
			\hline \hline \end{tabular} } ///
			\begin{tablenotes}[para,flushleft] ///
				\footnotesize{NOTES. Table \ref{acemoglucopywage} estimates the effect of exposure to robots on wage with each market being defined as a CZ-by-SOC cell. The US exposure to robots is instrumented by EURO5 exposure to robots. The demographic characteristics include the share of male, the share of elders (over 65), the share of the population with no college, some college, college or professional, and master or doctoral degree, the share of non-white, and the share of manufacturing industry workers. Errors are clustered within states. The under-identification test reports p-value of the Kleibergen-Paap LM statistic. The weak identification test reports the Kleibergen-Paap Wald F statistic. The over-identification test reports p-value of the Hansen J statistic. The endogeneity test reports p-value of the chi-square statistic. * p $<$.10, ** p$<$ .05, *** p$<$.01.} ///
			\end{tablenotes} ///
			\end{threeparttable}} ///
			\label{acemoglucopywage} ///
			\end{center})
			
			
			
********* results 6 ***********
use regwage,clear
label var er_us_emp06 "Exposure to Robots"
label var hhi_new "HHI"
label var interaction "HHI*Exposure to Robots"
ivreghdfe d_lnwage_0614 (er_us_emp06 interaction=er_eu ivinteraction) hhi_new $demographic, absorb(occsoc) endog(er_us_emp06 interaction) cluster(state)
		eststo result6col1
		eststo result6col1, add(Observations e(N))
		eststo result6col1, add(Underidentification e(idp))
		eststo result6col1, add(Weakidentification e(widstat))
		eststo result6col1, add(Endogeneity e(estatp))

ivreghdfe d_lnwage_0614 (er_us_emp06 interaction=er_eu ivinteraction) hhi_new $demographic [weight=emp_lm06], absorb(occsoc) endog(er_us_emp06 interaction) cluster(state)
		eststo result6col2
		eststo result6col2, add(Observations e(N))
		eststo result6col2, add(Underidentification e(idp))
		eststo result6col2, add(Weakidentification e(widstat))
		eststo result6col2, add(Endogeneity e(estatp))

ivreghdfe d_lnwage_0614 (er_us_emp06 interaction=er_eu ivinteraction) hhi_new $demographic, absorb(occsoc state) endog(er_us_emp06 interaction) cluster(state)
		eststo result6col3
		eststo result6col3, add(Observations e(N))
		eststo result6col3, add(Underidentification e(idp))
		eststo result6col3, add(Weakidentification e(widstat))
		eststo result6col3, add(Endogeneity e(estatp))

ivreghdfe d_lnwage_0614 (er_us_emp06 interaction=er_eu ivinteraction) hhi_new $demographic [weight=emp_lm06], absorb(occsoc state) endog(er_us_emp06 interaction) cluster(state)
		eststo result6col4
		eststo result6col4, add(Observations e(N))
		eststo result6col4, add(Underidentification e(idp))
		eststo result6col4, add(Weakidentification e(widstat))
		eststo result6col4, add(Endogeneity e(estatp))
		
************************************
********* MAKE LATEX TABLE *********
************************************

esttab result6col1 result6col2 result6col3 result6col4 ///
	using "$JMPproposal\result_noIVforHHIwage.tex", ///
	se nonotes  style(tex)  b(%12.3f) se(%12.3f)  ///
	starlevels(* 0.10 ** 0.05 *** 0.01) scalar(Underidentification Weakidentification Endogeneity) label mlabels("" "" "" "" "" "" "" "" "" "" ) ///
	 keep(er_us_emp06 hhi_new interaction) nonumbers  replace  fragment  ///
	 prehead(\begin{center} ///
				\caption{Effect of Exposure to Robots on Wage in Concentrated Market: IV for ER} ///
			\scalebox{1.2}[1.2]{\begin{threeparttable} ///
			{\begin{tabular}{lcccccccccc} ///
			\hline \hline ///
			& \multicolumn{4}{c}{TSLS} \\ \cline{2-5} ///
			& (1) & (2) & (3) & (4) \\) ///
	 prefoot( \\ ) ///
	 postfoot( ///
			\hline ///
			"Occupation fixed effects" & \checkmark & \checkmark & \checkmark & \checkmark \\ ///
			"Demographics" & \checkmark & \checkmark & \checkmark & \checkmark \\ ///
			"State fixed effects" & & & \checkmark & \checkmark \\ ///
			"Weighted" & & \checkmark & & \checkmark \\ ///
			\hline \hline \end{tabular} } ///
			\begin{tablenotes}[para,flushleft] ///
				\footnotesize{NOTES. Table \ref{noIVforHHIwage} presents the variation of the effect of exposure to robots on log annual wage across markets with different concentration levels. The US exposure to robots is instrumented by EURO5 exposure to robots. The demographic characteristics include the share of male, the share of elders (over 65), the share of the population with no college, some college, college or professional, and master or doctoral degree, the share of non-white, and the share of manufacturing industry workers. Errors are clustered within states. The under-identification test reports p-value of the Kleibergen-Paap LM statistic. The weak identification test reports the Kleibergen-Paap Wald F statistic. The over-identification test reports p-value of the Hansen J statistic. The endogeneity test reports p-value of the chi-square statistic. * p $<$.10, ** p$<$ .05, *** p$<$.01.} ///
			\end{tablenotes} ///
			\end{threeparttable}} ///
			\label{noIVforHHIwage} ///
			\end{center})
			

********* results 7 ***********
use regwage,clear
label var er_us_emp06 "Exposure to Robots"
label var hhi_new "HHI"
label var interaction "HHI*Exposure to Robots"
ivreghdfe d_lnwage_0614 (er_us_emp06 interaction hhi_new=er_eu celder_ehat cmanuf_ehat ivinteraction3 ivinteraction4) $demographic, absorb(occsoc) endog(er_us_emp06 hhi_new interaction) cluster(state)
		eststo result7col1
		eststo result7col1, add(Observations e(N))
		eststo result7col1, add(Underidentification e(idp))
		eststo result7col1, add(Weakidentification e(widstat))
		eststo result7col1, add(Overidentification e(jp))
		eststo result7col1, add(Endogeneity e(estatp))

ivreghdfe d_lnwage_0614 (er_us_emp06 interaction hhi_new=er_eu celder_ehat cmanuf_ehat ivinteraction3 ivinteraction4) $demographic [weight=emp_lm06], absorb(occsoc) endog(er_us_emp06 hhi_new interaction) cluster(state)
		eststo result7col2
		eststo result7col2, add(Observations e(N))
		eststo result7col2, add(Underidentification e(idp))
		eststo result7col2, add(Weakidentification e(widstat))
		eststo result7col2, add(Overidentification e(jp))
		eststo result7col2, add(Endogeneity e(estatp))

ivreghdfe d_lnwage_0614 (er_us_emp06 interaction hhi_new=er_eu celder_ehat_2 cmanuf_ehat_2 ivinteraction4_2 ivinteraction5_2) $demographic, absorb(occsoc state) endog(er_us_emp06 hhi_new interaction) cluster(state)
		eststo result7col3
		eststo result7col3, add(Observations e(N))
		eststo result7col3, add(Underidentification e(idp))
		eststo result7col3, add(Weakidentification e(widstat))
		eststo result7col3, add(Overidentification e(jp))
		eststo result7col3, add(Endogeneity e(estatp))

ivreghdfe d_lnwage_0614 (er_us_emp06 interaction hhi_new=er_eu celder_ehat_2 cmanuf_ehat_2 ivinteraction4_2 ivinteraction5_2) $demographic [weight=emp_lm06], absorb(occsoc state) endog(er_us_emp06 hhi_new interaction) cluster(state)
		eststo result7col4
		eststo result7col4, add(Observations e(N))
		eststo result7col4, add(Underidentification e(idp))
		eststo result7col4, add(Weakidentification e(widstat))
		eststo result7col4, add(Overidentification e(jp))
		eststo result7col4, add(Endogeneity e(estatp))
		
************************************
********* MAKE LATEX TABLE *********
************************************

esttab result7col1 result7col2 result7col3 result7col4 ///
	using "$JMPproposal\result_LewbelIV1forHHIwage.tex", ///
	se nonotes  style(tex)  b(%12.3f) se(%12.3f)  ///
	starlevels(* 0.10 ** 0.05 *** 0.01) scalar(Underidentification Weakidentification Overidentification Endogeneity) label mlabels("" "" "" "" "" "" "" "" "" "" ) ///
	 keep(er_us_emp06 hhi_new interaction) nonumbers  replace  fragment  ///
	 prehead(\begin{center} ///
				\caption{Effect of Exposure to Robots on Wage in Concentrated Market: Lewbel IV set 1 for HHI} ///
			\scalebox{1.2}[1.2]{\begin{threeparttable} ///
			{\begin{tabular}{lcccccccccc} ///
			\hline \hline ///
			& \multicolumn{4}{c}{TSLS} \\ \cline{2-5} ///
			& (1) & (2) & (3) & (4) \\) ///
	 prefoot( \\ ) ///
	 postfoot( ///
			\hline ///
			"Occupation fixed effects" & \checkmark & \checkmark & \checkmark & \checkmark \\ ///
			"Demographics" & \checkmark & \checkmark & \checkmark & \checkmark \\ ///
			"State fixed effects" & & & \checkmark & \checkmark \\ ///
			"Weighted" & & \checkmark & & \checkmark \\ ///
			\hline \hline \end{tabular} } ///
			\begin{tablenotes}[para,flushleft] ///
				\footnotesize{NOTES. Table \ref{LewbelIV1forHHIwage} presents the variation of the effect of exposure to robots on wage across markets with different concentration levels. The US exposure to robots is instrumented by EURO5 exposure to robots. I use Lewbel's heteroskedasticity-based IVs, built upon share of elders and the share of manufacturing workers in the market, to instrument HHI. The demographic characteristics include the share of male, the share of elders (over 65), the share of the population with no college, some college, college or professional, and master or doctoral degree, the share of non-white, and the share of manufacturing industry workers. Errors are clustered within states. The under-identification test reports p-value of the Kleibergen-Paap LM statistic. The weak identification test reports the Kleibergen-Paap Wald F statistic. The over-identification test reports p-value of the Hansen J statistic. The endogeneity test reports p-value of the chi-square statistic. * p $<$.10, ** p$<$ .05, *** p$<$.01.} ///
			\end{tablenotes} ///
			\end{threeparttable}} ///
			\label{LewbelIV1forHHIwage} ///
			\end{center})
			

			
			
********* results 7_2***********
use regwage,clear
label var er_us_emp06 "Exposure to Robots"
label var hhi_new "HHI"
label var interaction "HHI*Exposure to Robots"
ivreghdfe d_lnwage_0614 (er_us_emp06 interaction hhi_new=er_eu cmanuf_ehat cmastdoc_ehat ivinteraction4 ivinteraction6) $demographic, absorb(occsoc) endog(er_us_emp06 hhi_new interaction) cluster(state)
		eststo result72col1
		eststo result72col1, add(Observations e(N))
		eststo result72col1, add(Underidentification e(idp))
		eststo result72col1, add(Weakidentification e(widstat))
		eststo result72col1, add(Overidentification e(jp))
		eststo result72col1, add(Endogeneity e(estatp))

ivreghdfe d_lnwage_0614 (er_us_emp06 interaction hhi_new=er_eu cmanuf_ehat cmastdoc_ehat ivinteraction4 ivinteraction6) $demographic [weight=emp_lm06], absorb(occsoc) endog(er_us_emp06 hhi_new interaction) cluster(state)
		eststo result72col2
		eststo result72col2, add(Observations e(N))
		eststo result72col2, add(Underidentification e(idp))
		eststo result72col2, add(Weakidentification e(widstat))
		eststo result72col2, add(Overidentification e(jp))
		eststo result72col2, add(Endogeneity e(estatp))

ivreghdfe d_lnwage_0614 (er_us_emp06 interaction hhi_new=er_eu cmastdoc_ehat_2 cmanuf_ehat_2 ivinteraction2_2 ivinteraction4_2) $demographic, absorb(occsoc state) endog(er_us_emp06 hhi_new interaction) cluster(state)
		eststo result72col3
		eststo result72col3, add(Observations e(N))
		eststo result72col3, add(Underidentification e(idp))
		eststo result72col3, add(Weakidentification e(widstat))
		eststo result72col3, add(Overidentification e(jp))
		eststo result72col3, add(Endogeneity e(estatp))

ivreghdfe d_lnwage_0614 (er_us_emp06 interaction hhi_new=er_eu cmastdoc_ehat_2 cmanuf_ehat_2 ivinteraction2_2 ivinteraction4_2) $demographic [weight=emp_lm06], absorb(occsoc state) endog(er_us_emp06 hhi_new interaction) cluster(state)
		eststo result72col4
		eststo result72col4, add(Observations e(N))
		eststo result72col4, add(Underidentification e(idp))
		eststo result72col4, add(Weakidentification e(widstat))
		eststo result72col4, add(Overidentification e(jp))
		eststo result72col4, add(Endogeneity e(estatp))
		
************************************
********* MAKE LATEX TABLE *********
************************************

esttab result72col1 result72col2 result72col3 result72col4 ///
	using "$JMPproposal\result_LewbelIV2forHHIwage.tex", ///
	se nonotes  style(tex)  b(%12.3f) se(%12.3f)  ///
	starlevels(* 0.10 ** 0.05 *** 0.01) scalar(Underidentification Weakidentification Overidentification Endogeneity) label mlabels("" "" "" "" "" "" "" "" "" "" ) ///
	 keep(er_us_emp06 hhi_new interaction) nonumbers  replace  fragment  ///
	 prehead(\begin{center} ///
				\caption{Effect of Exposure to Robots on Wage in Concentrated Market: Lewbel IV set 2 for HHI} ///
			\scalebox{1.2}[1.2]{\begin{threeparttable} ///
			{\begin{tabular}{lcccccccccc} ///
			\hline \hline ///
			& \multicolumn{4}{c}{TSLS} \\ \cline{2-5} ///
			& (1) & (2) & (3) & (4) \\) ///
	 prefoot( \\ ) ///
	 postfoot( ///
			\hline ///
			"Occupation fixed effects" & \checkmark & \checkmark & \checkmark & \checkmark \\ ///
			"Demographics" & \checkmark & \checkmark & \checkmark & \checkmark \\ ///
			"State fixed effects" & & & \checkmark & \checkmark \\ ///
			"Weighted" & & \checkmark & & \checkmark \\ ///
			\hline \hline \end{tabular} } ///
			\begin{tablenotes}[para,flushleft] ///
				\footnotesize{NOTES. Table \ref{LewbelIV2forHHIwage} presents the variation of the effect of exposure to robots on wage across markets with different concentration levels. The US exposure to robots is instrumented by EURO5 exposure to robots. I use Lewbel's heteroskedasticity-based IVs, built upon share of manufacturing workers and share of population with master or doctoral degree in the market, to instrument HHI. The demographic characteristics include the share of male, the share of elders (over 65), the share of the population with no college, some college, college or professional, and master or doctoral degree, the share of non-white, and the share of manufacturing industry workers. Errors are clustered within states. The under-identification test reports p-value of the Kleibergen-Paap LM statistic. The weak identification test reports the Kleibergen-Paap Wald F statistic. The over-identification test reports p-value of the Hansen J statistic. The endogeneity test reports p-value of the chi-square statistic. * p $<$.10, ** p$<$ .05, *** p$<$.01.} ///
			\end{tablenotes} ///
			\end{threeparttable}} ///
			\label{LewbelIV2forHHIwage} ///
			\end{center})
			
			
/*		
********* results 8 ***********
use regemp,clear
		g tripleinteraction=er_us_emp06*hhi_new*rti1
		g ivtripleinteraction=er_eu*hhi_new*rti1
		g ivtripleinteraction1=cworkpop_ehat*er_eu*rti1
		g ivtripleinteraction2=cnonwhite_ehat*er_eu*rti1
		g ivtripleinteraction3=celder_ehat*er_eu*rti1
		g ivtripleinteraction4=cmastdoc_ehat*er_eu*rti1
		g ivtripleinteraction5=cmanuf_ehat*er_eu*rti1
		g ivtripleinteraction6=cmale_ehat*er_eu*rti1
label var er_us_emp06 "Exposure to Robots"
label var hhi_new "HHI"
label var interaction "HHI*ER"
label var tripleinteraction "HHI*ER*RTI"

ivreghdfe d_emp_workpop06_ratio (er_us_emp06 interaction tripleinteraction=er_eu ivinteraction ivtripleinteraction) hhi_new $demographic, absorb(occsoc state) endog(er_us_emp06 interaction tripleinteraction) cluster(state)
		eststo result8col1
		eststo result8col1, add(Observations e(N))
		eststo result8col1, add(Underidentification e(idp))
		eststo result8col1, add(Weakidentification e(widstat))
		eststo result8col1, add(Overidentification e(jp))
		eststo result8col1, add(Endogeneity e(estatp))

ivreghdfe d_emp_workpop06_ratio (er_us_emp06 hhi_new interaction tripleinteraction=er_eu cmanuf_ehat cmale_ehat ivinteraction5 ivinteraction6 ivtripleinteraction5 ivtripleinteraction6) $demographic, absorb(occsoc state) endog(er_us_emp06 interaction hhi_new tripleinteraction) cluster(state)
		eststo result8col2
		eststo result8col2, add(Observations e(N))
		eststo result8col2, add(Underidentification e(idp))
		eststo result8col2, add(Weakidentification e(widstat))
		eststo result8col2, add(Overidentification e(jp))
		eststo result8col2, add(Endogeneity e(estatp))

use regwage,clear
		g tripleinteraction=er_us_emp06*hhi_new*rti1
		g ivtripleinteraction=er_eu*hhi_new*rti1
		g ivtripleinteraction1=cworkpop_ehat*er_eu*rti1
		g ivtripleinteraction2=cmastdoc_ehat*er_eu*rti1
		g ivtripleinteraction3=celder_ehat*er_eu*rti1
		g ivtripleinteraction4=cmanuf_ehat*er_eu*rti1
		g ivtripleinteraction5=cnocoll_ehat*er_eu*rti1
label var er_us_emp06 "Exposure to Robots"
label var hhi_new "HHI"
label var interaction "HHI*ER"
label var tripleinteraction "HHI*ER*RTI"		
		
ivreghdfe d_lnwage_0614 (er_us_emp06 interaction tripleinteraction=er_eu ivinteraction ivtripleinteraction) hhi_new $demographic, absorb(occsoc state) endog(er_us_emp06 interaction tripleinteraction) cluster(state)
		eststo result8col3
		eststo result8col3, add(Observations e(N))
		eststo result8col3, add(Underidentification e(idp))
		eststo result8col3, add(Weakidentification e(widstat))
		eststo result8col3, add(Overidentification e(jp))
		eststo result8col3, add(Endogeneity e(estatp))
ivreghdfe d_lnwage_0614 (er_us_emp06 hhi_new interaction tripleinteraction=er_eu cmanuf_ehat celder_ehat ivinteraction4 ivinteraction3 ivtripleinteraction4 ivtripleinteraction3) $demographic, absorb(occsoc state) endog(er_us_emp06 interaction hhi_new tripleinteraction) cluster(state)
		eststo result8col4
		eststo result8col4, add(Observations e(N))
		eststo result8col4, add(Underidentification e(idp))
		eststo result8col4, add(Weakidentification e(widstat))
		eststo result8col4, add(Overidentification e(jp))
		eststo result8col4, add(Endogeneity e(estatp))
		
************************************
********* MAKE LATEX TABLE *********
************************************

esttab result8col1 result8col2 result8col3 result8col4 ///
	using "$JMPproposal\result_rti.tex", ///
	se nonotes  style(tex)  b(%12.3f) se(%12.3f)  ///
	starlevels(* 0.10 ** 0.05 *** 0.01) scalar(Underidentification Weakidentification Overidentification Endogeneity) label mlabels("" "" "" "" "" "" "" "" "" "" ) ///
	 keep(er_us_emp06 hhi_new interaction tripleinteraction) nonumbers  replace  fragment  ///
	 prehead(\begin{center} ///
				\caption{Effect of Exposure to Robots on Employment and Wage in Concentrated Market} ///
			\scalebox{1.2}{\begin{threeparttable} ///
			{\begin{tabular}{lcccccccccc} ///
			\hline \hline ///			
			& \multicolumn{2}{c}{Employment} & \multicolumn{2}{c}{Wage} \\ ///
			& (1) & (2) & (3) & (4) \\) ///
	 prefoot( \\ ) ///
	 postfoot( ///
			\hline ///
			"Occupation fixed effects" & \checkmark & \checkmark & \checkmark & \checkmark \\ ///
			"Demographics" & \checkmark & \checkmark & \checkmark & \checkmark \\ ///
			"State fixed effects" & \checkmark & \checkmark & \checkmark & \checkmark \\ ///
			"Lewbel's IV for HHI" &  & \checkmark & & \checkmark  \\ ///
			\hline \hline \end{tabular} } ///
			\begin{tablenotes}[para,flushleft] ///
				\footnotesize{NOTES. Table \ref{rti} presents the restuls variation of the effect of exposure to robots on log annual wage across markets with different concentration levels. The US exposure to robots is instrumented by EURO5 exposure to robots. I use Lewbel's heteroskedasticity-based IVs, built upon the CZ working-age population and the share of manufacturing workers in the market, to instrument HHI. The demographic characteristics include the share of male, the share of elders (over 65), the share of the population with no college, some college, college or professional, and master or doctoral degree, the share of non-white, the share of manufacturing industry workers and CZ-level population. Errors are clustered at state level. The under-identification test reports p-value of the Kleibergen-Paap LM statistic. The weak identification test reports the Kleibergen-Paap Wald F statistic. The over-identification test reports p-value of the Hansen J statistic. The endogeneity test reports p-value of the chi-square statistic. * p $<$.10, ** p$<$ .05, *** p$<$.01.} ///
			\end{tablenotes} ///
			\end{threeparttable}} ///
			\label{rti} ///
			\end{center})
			
*/
			
			
			
********* results 9 ***********
use regemp_nofullhhi,clear
label var er_us_emp06 "Exposure to Robots"
label var hhi_new "HHI"
label var interaction "HHI*Exposure to Robots"
ivreghdfe d_emp_workpop06_ratio (er_us_emp06 interaction hhi_new=er_eu ccollprof_ehat cmanuf_ehat ivinteraction2 ivinteraction6) $demographic, absorb(occsoc) endog(er_us_emp06 hhi_new interaction) cluster(state)
		eststo result9col1
		eststo result9col1, add(Observations e(N))
		eststo result9col1, add(Underidentification e(idp))
		eststo result9col1, add(Weakidentification e(widstat))
		eststo result9col1, add(Overidentification e(jp))
		eststo result9col1, add(Endogeneity e(estatp))

ivreghdfe d_emp_workpop06_ratio (er_us_emp06 interaction hhi_new=er_eu ccollprof_ehat cmanuf_ehat ivinteraction2 ivinteraction6) $demographic [weight=emp_lm06], absorb(occsoc) endog(er_us_emp06 hhi_new interaction) cluster(state)
		eststo result9col2
		eststo result9col2, add(Observations e(N))
		eststo result9col2, add(Underidentification e(idp))
		eststo result9col2, add(Weakidentification e(widstat))
		eststo result9col2, add(Overidentification e(jp))
		eststo result9col2, add(Endogeneity e(estatp))
		
ivreghdfe d_emp_workpop06_ratio (er_us_emp06 interaction hhi_new=er_eu ccollprof_ehat_2 cmanuf_ehat_2 ivinteraction2_2 ivinteraction5_2) $demographic, absorb(occsoc state) endog(er_us_emp06 hhi_new interaction) cluster(state)
		eststo result9col3
		eststo result9col3, add(Observations e(N))
		eststo result9col3, add(Underidentification e(idp))
		eststo result9col3, add(Weakidentification e(widstat))
		eststo result9col3, add(Overidentification e(jp))
		eststo result9col3, add(Endogeneity e(estatp))

ivreghdfe d_emp_workpop06_ratio (er_us_emp06 interaction hhi_new=er_eu ccollprof_ehat_2 cmanuf_ehat_2 ivinteraction2_2 ivinteraction5_2) $demographic [weight=emp_lm06], absorb(occsoc state) endog(er_us_emp06 hhi_new interaction) cluster(state)
		eststo result9col4
		eststo result9col4, add(Observations e(N))
		eststo result9col4, add(Underidentification e(idp))
		eststo result9col4, add(Weakidentification e(widstat))
		eststo result9col4, add(Overidentification e(jp))
		eststo result9col4, add(Endogeneity e(estatp))
		
************************************
********* MAKE LATEX TABLE *********
************************************

esttab result9col1 result9col2 result9col3 result9col4 ///
	using "$JMPproposal\result_LewbelIV1forHHIemp_nofullhhi.tex", ///
	se nonotes  style(tex)  b(%12.3f) se(%12.3f)  ///
	starlevels(* 0.10 ** 0.05 *** 0.01) scalar(Underidentification Weakidentification Overidentification Endogeneity) label mlabels("" "" "" "" "" "" "" "" "" "" ) ///
	 keep(er_us_emp06 hhi_new interaction) nonumbers  replace  fragment  ///
	 prehead(\begin{center} ///
				\caption{Effect of Exposure to Robots on Employment in Concentrated Market: Lewbel IV set 1 for HHI} ///
			\scalebox{1.2}{\begin{threeparttable} ///
			{\begin{tabular}{lcccccccccc} ///
			\hline \hline ///
			& \multicolumn{4}{c}{TSLS} \\ \cline{2-5} ///
			& (1) & (2) & (3) & (4) \\) ///
	 prefoot( \\ ) ///
	 postfoot( ///
			\hline ///
			"Occupation fixed effects" & \checkmark & \checkmark & \checkmark & \checkmark \\ ///
			"Demographics" & \checkmark & \checkmark & \checkmark & \checkmark \\ ///
			"State fixed effects" & & & \checkmark & \checkmark \\ ///
			"Weighted" & & \checkmark & & \checkmark \\ ///
			\hline \hline \end{tabular} } ///
			\begin{tablenotes}[para,flushleft] ///
				\footnotesize{NOTES. Table \ref{LewbelIV1forHHIemp:nofullhhi} presents the variation of the effect of exposure to robots on employment across markets with different concentration levels. The fully concentrated markets are excluded from the regression sample. The US exposure to robots is instrumented by EURO5 exposure to robots. I used Lewbel's heteroskedasticity-based IV set 1, built upon the share of college or professional degress and the share of manufacturing workers in the market, to instrument HHI. The demographic characteristics include the share of male, the share of elders (over 65), the share of the population with no college, some college, college or professional, and master or doctoral degree, the share of non-white, and the share of manufacturing industry workers. Errors are clustered within states. The under-identification test reports p-value of the Kleibergen-Paap LM statistic. The weak identification test reports the Kleibergen-Paap Wald F statistic. The over-identification test reports p-value of the Hansen J statistic. The endogeneity test reports p-value of the chi-square statistic. * p $<$.10, ** p$<$ .05, *** p$<$.01.} ///
			\end{tablenotes} ///
			\end{threeparttable}} ///
			\label{LewbelIV1forHHIemp:nofullhhi} ///
			\end{center})
			
			
			
			
			
********* results 10 ***********
use regwage,clear
label var er_us_emp06 "Exposure to Robots"
label var hhi_new "HHI"
label var interaction "HHI*Exposure to Robots"
reghdfe d_lnwage_0614 er_us_emp06 interaction hhi_new $demographic, absorb(occsoc) cluster(state)
		eststo result10col1

reghdfe d_lnwage_0614 er_us_emp06 interaction hhi_new $demographic [weight=emp_lm06], absorb(occsoc) cluster(state)
		eststo result10col2

reghdfe d_lnwage_0614 er_us_emp06 interaction hhi_new $demographic, absorb(occsoc state) cluster(state)
		eststo result10col3

reghdfe d_lnwage_0614 er_us_emp06 interaction hhi_new $demographic [weight=emp_lm06], absorb(occsoc state) cluster(state)
		eststo result10col4

		
************************************
********* MAKE LATEX TABLE *********
************************************

esttab result10col1 result10col2 result10col3 result10col4 ///
	using "$JMPproposal\result_OLSwage.tex", ///
	se nonotes  style(tex)  b(%12.3f) se(%12.3f)  ///
	starlevels(* 0.10 ** 0.05 *** 0.01) label mlabels("" "" "" "" "" "" "" "" "" "" ) ///
	 keep(er_us_emp06 hhi_new interaction) nonumbers  replace  fragment  ///
	 prehead(\begin{center} ///
				\caption{Effect of Exposure to Robots on Wage in Concentrated Market: OLS} ///
			\scalebox{1}[1]{\begin{threeparttable} ///
			{\begin{tabular}{lcccccccccc} ///
			\hline \hline ///
			& \multicolumn{4}{c}{OLS} \\ \cline{2-5} ///
			& (1) & (2) & (3) & (4) \\) ///
	 prefoot( \\ ) ///
	 postfoot( ///
			\hline ///
			"Occupation fixed effects" & \checkmark & \checkmark & \checkmark & \checkmark \\ ///
			"Demographics" & \checkmark & \checkmark & \checkmark & \checkmark \\ ///
			"State fixed effects" & & & \checkmark & \checkmark \\ ///
			"Weighted" & & \checkmark & & \checkmark \\ ///
			\hline \hline \end{tabular} } ///
			\begin{tablenotes}[para,flushleft] ///
				\footnotesize{NOTES. Table \ref{OLSwage} presents OLS estimates of the variation of the effect of exposure to robots on log annual wage across markets with different concentration levels. The demographic characteristics include the share of male, the share of elders (over 65), the share of the population with no college, some college, college or professional, and master or doctoral degree, the share of non-white, and the share of manufacturing industry workers. Errors are clustered within states. * p $<$.10, ** p$<$ .05, *** p$<$.01.} ///
			\end{tablenotes} ///
			\end{threeparttable}} ///
			\label{OLSwage} ///
			\end{center})
		
		
		
********* results 11 ***********
use regwage_nofullhhi,clear
label var er_us_emp06 "Exposure to Robots"
label var hhi_new "HHI"
label var interaction "HHI*Exposure to Robots"
ivreghdfe d_lnwage_0614 (er_us_emp06 interaction hhi_new=er_eu celder_ehat cmanuf_ehat ivinteraction4 ivinteraction5) $demographic, absorb(occsoc) endog(er_us_emp06 hhi_new interaction) cluster(state)
		eststo result11col1
		eststo result11col1, add(Observations e(N))
		eststo result11col1, add(Underidentification e(idp))
		eststo result11col1, add(Weakidentification e(widstat))
		eststo result11col1, add(Overidentification e(jp))
		eststo result11col1, add(Endogeneity e(estatp))

ivreghdfe d_lnwage_0614 (er_us_emp06 interaction hhi_new=er_eu celder_ehat cmanuf_ehat ivinteraction4 ivinteraction5) $demographic [weight=emp_lm06], absorb(occsoc) endog(er_us_emp06 hhi_new interaction) cluster(state)
		eststo result11col2
		eststo result11col2, add(Observations e(N))
		eststo result11col2, add(Underidentification e(idp))
		eststo result11col2, add(Weakidentification e(widstat))
		eststo result11col2, add(Overidentification e(jp))
		eststo result11col2, add(Endogeneity e(estatp))

ivreghdfe d_lnwage_0614 (er_us_emp06 interaction hhi_new=er_eu celder_ehat_2 cmanuf_ehat_2 ivinteraction2_2 ivinteraction3_2) $demographic, absorb(occsoc state) endog(er_us_emp06 hhi_new interaction) cluster(state)
		eststo result11col3
		eststo result11col3, add(Observations e(N))
		eststo result11col3, add(Underidentification e(idp))
		eststo result11col3, add(Weakidentification e(widstat))
		eststo result11col3, add(Overidentification e(jp))
		eststo result11col3, add(Endogeneity e(estatp))

ivreghdfe d_lnwage_0614 (er_us_emp06 interaction hhi_new=er_eu celder_ehat_2 cmanuf_ehat_2 ivinteraction2_2 ivinteraction3_2) $demographic [weight=emp_lm06], absorb(occsoc state) endog(er_us_emp06 hhi_new interaction) cluster(state)
		eststo result11col4
		eststo result11col4, add(Observations e(N))
		eststo result11col4, add(Underidentification e(idp))
		eststo result11col4, add(Weakidentification e(widstat))
		eststo result11col4, add(Overidentification e(jp))
		eststo result11col4, add(Endogeneity e(estatp))
		
************************************
********* MAKE LATEX TABLE *********
************************************

esttab result11col1 result11col2 result11col3 result11col4 ///
	using "$JMPproposal\result_LewbelIV1forHHIwage_nofullhhi.tex", ///
	se nonotes  style(tex)  b(%12.3f) se(%12.3f)  ///
	starlevels(* 0.10 ** 0.05 *** 0.01) scalar(Underidentification Weakidentification Overidentification Endogeneity) label mlabels("" "" "" "" "" "" "" "" "" "" ) ///
	 keep(er_us_emp06 hhi_new interaction) nonumbers  replace  fragment  ///
	 prehead(\begin{center} ///
				\caption{Effect of Exposure to Robots on Wage in Concentrated Market: Lewbel IV set 1 for HHI} ///
			\scalebox{1.2}[1.2]{\begin{threeparttable} ///
			{\begin{tabular}{lcccccccccc} ///
			\hline \hline ///
			& \multicolumn{4}{c}{TSLS} \\ \cline{2-5} ///
			& (1) & (2) & (3) & (4) \\) ///
	 prefoot( \\ ) ///
	 postfoot( ///
			\hline ///
			"Occupation fixed effects" & \checkmark & \checkmark & \checkmark & \checkmark \\ ///
			"Demographics" & \checkmark & \checkmark & \checkmark & \checkmark \\ ///
			"State fixed effects" & & & \checkmark & \checkmark \\ ///
			"Weighted" & & \checkmark & & \checkmark \\ ///
			\hline \hline \end{tabular} } ///
			\begin{tablenotes}[para,flushleft] ///
				\footnotesize{NOTES. Table \ref{LewbelIV1forHHIwage:nofullhhi} presents the variation of the effect of exposure to robots on log annual wage across markets with different concentration levels. The fully concentrated markets are excluded from the regression sample. The US exposure to robots is instrumented by EURO5 exposure to robots. I use Lewbel's heteroskedasticity-based IVs, built upon share of elders and the share of manufacturing workers in the market, to instrument HHI. The demographic characteristics include the share of male, the share of elders (over 65), the share of the population with no college, some college, college or professional, and master or doctoral degree, the share of non-white, and the share of manufacturing industry workers. Errors are clustered within states. The under-identification test reports p-value of the Kleibergen-Paap LM statistic. The weak identification test reports the Kleibergen-Paap Wald F statistic. The over-identification test reports p-value of the Hansen J statistic. The endogeneity test reports p-value of the chi-square statistic. * p $<$.10, ** p$<$ .05, *** p$<$.01.} ///
			\end{tablenotes} ///
			\end{threeparttable}} ///
			\label{LewbelIV1forHHIwage:nofullhhi} ///
			\end{center})
*/
		
*******************************************************************************			
******************* v2 tables: combine emp and wage results  ******************
*******************************************************************************

*acemoglu replication
use regemp,clear
label var er_us_emp06 "Exposure to Robots"
ivreg2 d_emp_workpop06_ratio (er_us_emp06=er_eu), endog(er_us_emp06) cluster(state) 
		eststo result12col1
		eststo result12col1, add(Observations e(N))
		eststo result12col1, add(Underidentification e(idp))
		eststo result12col1, add(Weakidentification e(widstat))
		eststo result12col1, add(Endogeneity e(estatp)) 

ivreghdfe d_emp_workpop06_ratio (er_us_emp06=er_eu) $demographic, absorb(occsoc division) endog(er_us_emp06) cluster(state)
		eststo result12col2
		eststo result12col2, add(Observations e(N))
		eststo result12col2, add(Underidentification e(idp))
		eststo result12col2, add(Weakidentification e(widstat))
		eststo result12col2, add(Endogeneity e(estatp))
use regwage,clear
label var er_us_emp06 "Exposure to Robots"
ivreghdfe d_lnwage_0614 (er_us_emp06=er_eu), absorb(division) endog(er_us_emp06) cluster(state)
		eststo result12col3
		eststo result12col3, add(Observations e(N))
		eststo result12col3, add(Underidentification e(idp))
		eststo result12col3, add(Weakidentification e(widstat))
		eststo result12col3, add(Endogeneity e(estatp))

ivreghdfe d_lnwage_0614 (er_us_emp06=er_eu) $demographic, absorb(occsoc division) endog(er_us_emp06) cluster(state)
		eststo result12col4
		eststo result12col4, add(Observations e(N))
		eststo result12col4, add(Underidentification e(idp))
		eststo result12col4, add(Weakidentification e(widstat))  
		eststo result12col4, add(Endogeneity e(estatp))
************************************
********* MAKE LATEX TABLE *********
************************************
esttab result12col1 result12col2 result12col3 result12col4 ///
	using "$JMPproposal\result_acemoglucopy.tex", ///
	se nonotes  style(tex)  b(%12.3f) se(%12.3f)  ///
	starlevels(* 0.10 ** 0.05 *** 0.01) scalar(Underidentification Weakidentification Endogeneity) label mlabels("" "" "" "" "" "" "" "" "" "" ) ///
	 keep(er_us_emp06) nonumbers  replace  fragment  ///
	 prehead(\begin{center} ///
				\caption{Effect of robots on employment and wages: IV estimates} ///
			\scalebox{1}[1]{\begin{threeparttable} ///
			{\begin{tabular}{lcccccccccc} ///
			\hline \hline ///
			& \multicolumn{4}{c}{TSLS} \\ \cline{2-5} ///
			& \multicolumn{2}{c}{Employment} & \multicolumn{2}{c}{Wages}\\ \cline{2-5} ///
			& (1) & (2) & (3) & (4) \\) ///
	 prefoot( \\ ) ///
	 postfoot( ///
			\hline ///
			"Census divisions" & \checkmark & \checkmark & \checkmark & \checkmark \\ ///
			"Demographics" & & \checkmark & & \checkmark \\ ///
			"Occupation fixed effects" & & \checkmark & & \checkmark \\ ///
			\hline \hline \end{tabular} } ///
			\begin{tablenotes}[para,flushleft] ///
				\footnotesize{NOTES. Table \ref{acemoglucopy} presents the IV estimates of the effects of exposure to robots on employment and wages for 2006-2014. Each labor market is defined as a CZ-by-occupation cell. I instrument the US exposure to robots using the EURO5 exposure to robots. Columns 1 and 2 present results for employment-to-CZ-working-age-population ratio. Columns 3 and 4 present results for log annual wages. The demographic characteristics include the share of male, the share of elders (over 65), the share of the population with no college, some college, college or professional, and master or doctoral degree, the share of non-white, and the share of manufacturing industry workers. The under-identification test reports p-value of the Kleibergen-Paap LM statistic. The weak identification test reports the Kleibergen-Paap Wald F statistic. The endogeneity test reports p-value of the chi-square statistic. Standard errors are clustered at the state level. * p $<$.10, ** p$<$ .05, *** p$<$.01.} ///
			\end{tablenotes} ///
			\end{threeparttable}} ///
			\label{acemoglucopy} ///
			\end{center})

			
			
* endogenous ER only
use regemp,clear
label var er_us_emp06 "Exposure to Robots"
label var hhi_new "HHI"
label var interaction "HHI*Exposure to Robots"
ivreghdfe d_emp_workpop06_ratio (er_us_emp06 interaction=er_eu ivinteraction) hhi_new $demographic, absorb(occsoc) endog(er_us_emp06 interaction) cluster(state)
		eststo result13col1
		eststo result13col1, add(Observations e(N))
		eststo result13col1, add(Underidentification e(idp))
		eststo result13col1, add(Weakidentification e(widstat))
		eststo result13col1, add(Endogeneity e(estatp))

ivreghdfe d_emp_workpop06_ratio (er_us_emp06 interaction=er_eu ivinteraction) hhi_new $demographic, absorb(occsoc state) endog(er_us_emp06 interaction) cluster(state)
		eststo result13col2
		eststo result13col2, add(Observations e(N))
		eststo result13col2, add(Underidentification e(idp))
		eststo result13col2, add(Weakidentification e(widstat))
		eststo result13col2, add(Endogeneity e(estatp))

use regwage,clear
label var er_us_emp06 "Exposure to Robots"
label var hhi_new "HHI"
label var interaction "HHI*Exposure to Robots"
ivreghdfe d_lnwage_0614 (er_us_emp06 interaction=er_eu ivinteraction) hhi_new $demographic, absorb(occsoc) endog(er_us_emp06 interaction) cluster(state)
		eststo result13col3
		eststo result13col3, add(Observations e(N))
		eststo result13col3, add(Underidentification e(idp))
		eststo result13col3, add(Weakidentification e(widstat))
		eststo result13col3, add(Endogeneity e(estatp))

ivreghdfe d_lnwage_0614 (er_us_emp06 interaction=er_eu ivinteraction) hhi_new $demographic, absorb(occsoc state) endog(er_us_emp06 interaction) cluster(state)
		eststo result13col4
		eststo result13col4, add(Observations e(N))
		eststo result13col4, add(Underidentification e(idp))
		eststo result13col4, add(Weakidentification e(widstat))
		eststo result13col4, add(Endogeneity e(estatp))	
************************************
********* MAKE LATEX TABLE *********
************************************
esttab result13col1 result13col2 result13col3 result13col4 ///
	using "$JMPproposal\result_noIVforHHI.tex", ///
	se nonotes  style(tex)  b(%12.3f) se(%12.3f)  ///
	starlevels(* 0.10 ** 0.05 *** 0.01) scalar(Underidentification Weakidentification Endogeneity) label mlabels("" "" "" "" "" "" "" "" "" "" ) ///
	 keep(er_us_emp06 hhi_new interaction) nonumbers  replace  fragment  ///
	 prehead(\begin{center} ///
				\caption{Effect of robots on employment and wages in concentrated markets: endogenous ER; exogenous HHI} ///
			\scalebox{1}[1]{\begin{threeparttable} ///
			{\begin{tabular}{lcccccccccc} ///
			\hline \hline ///
			& \multicolumn{4}{c}{TSLS} \\ \cline{2-5} ///
			& \multicolumn{2}{c}{Employment} & \multicolumn{2}{c}{Wages} \\ \cline{2-5} ///
			& (1) & (2) & (3) & (4) \\) ///
	 prefoot( \\ ) ///
	 postfoot( ///
			\hline ///
			"Occupation fixed effects" & \checkmark & \checkmark & \checkmark & \checkmark \\ ///
			"Demographics" & \checkmark & \checkmark & \checkmark & \checkmark \\ ///
			"State fixed effects" & & \checkmark & & \checkmark \\ ///
			\hline \hline \end{tabular} } ///
			\begin{tablenotes}[para,flushleft] ///
				\footnotesize{NOTES. Table \ref{noIVforHHI} presents the IV estimates of the marginal effects of exposure to robots on employment and wages under different concentration levels for 2006-2014. Each labor market is defined as a CZ-by-occupation cell. In all columns, I instrument the US exposure to robots using the EURO5 exposure to robots and treat HHI exogenous. Columns 1 and 2 present results for employment-to-CZ-working-age-population ratio. Columns 3 and 4 present results for log annual wage. The demographic characteristics include the share of male, the share of elders (over 65), the share of the population with no college, some college, college or professional, and master or doctoral degree, the share of non-white, and the share of manufacturing industry workers. The under-identification test reports p-value of the Kleibergen-Paap LM statistic. The weak identification test reports the Kleibergen-Paap Wald F statistic. The over-identification test reports p-value of the Hansen J statistic. The endogeneity test reports p-value of the chi-square statistic. Standard errors are clustered at the state level. * p $<$.10, ** p$<$ .05, *** p$<$.01.} ///
			\end{tablenotes} ///
			\end{threeparttable}} ///
			\label{noIVforHHI} ///
			\end{center})


			
			
*endogenous both ER and HHI: Lewbel IV set 1
use regemp,clear
label var er_us_emp06 "Exposure to Robots"
label var hhi_new "HHI"
label var interaction "HHI*Exposure to Robots"
ivreghdfe d_emp_workpop06_ratio (er_us_emp06 interaction hhi_new=er_eu ccollprof_ehat cmanuf_ehat ivinteraction2 ivinteraction5) $demographic, absorb(occsoc) endog(er_us_emp06 hhi_new interaction) cluster(state)
		eststo result14col1
		eststo result14col1, add(Observations e(N))
		eststo result14col1, add(Underidentification e(idp))
		eststo result14col1, add(Weakidentification e(widstat))
		eststo result14col1, add(Overidentification e(jp))
		eststo result14col1, add(Endogeneity e(estatp))

ivreghdfe d_emp_workpop06_ratio (er_us_emp06 interaction hhi_new=er_eu ccollprof_ehat_2 cmanuf_ehat_2 ivinteraction2_2 ivinteraction3_2) $demographic, absorb(occsoc state) endog(er_us_emp06 hhi_new interaction) cluster(state)
		eststo result14col2
		eststo result14col2, add(Observations e(N))
		eststo result14col2, add(Underidentification e(idp))
		eststo result14col2, add(Weakidentification e(widstat))
		eststo result14col2, add(Overidentification e(jp))
		eststo result14col2, add(Endogeneity e(estatp))
		
use regwage,clear
label var er_us_emp06 "Exposure to Robots"
label var hhi_new "HHI"
label var interaction "HHI*Exposure to Robots"
ivreghdfe d_lnwage_0614 (er_us_emp06 interaction hhi_new=er_eu celder_ehat cmanuf_ehat ivinteraction3 ivinteraction4) $demographic, absorb(occsoc) endog(er_us_emp06 hhi_new interaction) cluster(state)
		eststo result3col3
		eststo result14col3, add(Observations e(N))
		eststo result14col3, add(Underidentification e(idp))
		eststo result14col3, add(Weakidentification e(widstat))
		eststo result14col3, add(Overidentification e(jp))
		eststo result14col3, add(Endogeneity e(estatp))

ivreghdfe d_lnwage_0614 (er_us_emp06 interaction hhi_new=er_eu celder_ehat_2 cmanuf_ehat_2 ivinteraction4_2 ivinteraction5_2) $demographic, absorb(occsoc state) endog(er_us_emp06 hhi_new interaction) cluster(state)
		eststo result14col4
		eststo result14col4, add(Observations e(N))
		eststo result14col4, add(Underidentification e(idp))
		eststo result14col4, add(Weakidentification e(widstat))
		eststo result14col4, add(Overidentification e(jp))
		eststo result14col4, add(Endogeneity e(estatp))	
************************************
********* MAKE LATEX TABLE *********
************************************
esttab result14col1 result14col2 result14col3 result14col4 ///
	using "$JMPproposal\result_LewbelIV1forHHI.tex", ///
	se nonotes  style(tex)  b(%12.3f) se(%12.3f)  ///
	starlevels(* 0.10 ** 0.05 *** 0.01) scalar(Underidentification Weakidentification Overidentification Endogeneity) label mlabels("" "" "" "" "" "" "" "" "" "" ) ///
	 keep(er_us_emp06 hhi_new interaction) nonumbers  replace  fragment  ///
	 prehead(\begin{center} ///
				\caption{Effect of robots on employment and wages in concentrated markets: endogenous ER and HHI} ///
			\scalebox{1}{\begin{threeparttable} ///
			{\begin{tabular}{lcccccccccc} ///
			\hline \hline ///
			& \multicolumn{4}{c}{TSLS} \\ \cline{2-5} ///
			& \multicolumn{2}{c}{Employment} & \multicolumn{2}{c}{Wages} \\ \cline{2-5} ///
			& (1) & (2) & (3) & (4) \\) ///
	 prefoot( \\ ) ///
	 postfoot( ///
			\hline ///
			"Occupation fixed effects" & \checkmark & \checkmark & \checkmark & \checkmark \\ ///
			"Demographics" & \checkmark & \checkmark & \checkmark & \checkmark \\ ///
			"State fixed effects" & & \checkmark & & \checkmark \\ ///
			\hline \hline \end{tabular} } ///
			\begin{tablenotes}[para,flushleft] ///
				\footnotesize{NOTES. Table \ref{LewbelIV1forHHI} presents the IV estimates of the marginal effects of exposure to robots on employment and wages under different concentration levels for 2006-2014. Each labor market is defined as a CZ-by-occupation cell. In all columns, I instrument US exposure to robots using EURO5 exposure to robots, and HHI using a heteroskedasticity-based IV set. The set in the employment regressions contains the share of the population with college or professional degree and the share of manufacturing workers. The set in the wage regressions includes the share of elders (over 65) and the share of manufacturing workers. Column 1 and 2 present results for employment-to-CZ-working-age-population ratio. Column 3 and 4 present results for log annual wage. The demographic characteristics include the share of male, the share of elders (over 65), the share of the population with no college, some college, college or professional, and master or doctoral degree, the share of non-white, and the share of manufacturing industry workers. The under-identification test reports p-value of the Kleibergen-Paap LM statistic. The weak identification test reports the Kleibergen-Paap Wald F statistic. The over-identification test reports p-value of the Hansen J statistic. The endogeneity test reports p-value of the chi-square statistic. Standard errors are clustered at the state level. * p $<$.10, ** p$<$ .05, *** p$<$.01.} ///
			\end{tablenotes} ///
			\end{threeparttable}} ///
			\label{LewbelIV1forHHI} ///
			\end{center})


*** OLS employment and wages			
use regemp,clear
label var er_us_emp06 "Exposure to Robots"
label var hhi_new "HHI"
label var interaction "HHI*Exposure to Robots"
reghdfe d_emp_workpop06_ratio er_us_emp06 interaction hhi_new $demographic, absorb(occsoc) cluster(state)
		eststo result10col1

reghdfe d_emp_workpop06_ratio er_us_emp06 interaction hhi_new $demographic, absorb(occsoc state) cluster(state)
		eststo result10col2

			
use regwage,clear
label var er_us_emp06 "Exposure to Robots"
label var hhi_new "HHI"
label var interaction "HHI*Exposure to Robots"
reghdfe d_lnwage_0614 er_us_emp06 interaction hhi_new $demographic, absorb(occsoc) cluster(state)
		eststo result10col3

reghdfe d_lnwage_0614 er_us_emp06 interaction hhi_new $demographic, absorb(occsoc state) cluster(state)
		eststo result10col4


		
************************************
********* MAKE LATEX TABLE *********
************************************

esttab result10col1 result10col2 result10col3 result10col4 ///
	using "$JMPproposal\result_OLS.tex", ///
	se nonotes  style(tex)  b(%12.3f) se(%12.3f)  ///
	starlevels(* 0.10 ** 0.05 *** 0.01) label mlabels("" "" "" "" "" "" "" "" "" "" ) ///
	 keep(er_us_emp06 hhi_new interaction) nonumbers  replace  fragment  ///
	 prehead(\begin{center} ///
				\caption{Effect of robots on employment and wages in concentrated market: OLS} ///
			\scalebox{1}[1]{\begin{threeparttable} ///
			{\begin{tabular}{lcccccccccc} ///
			\hline \hline ///
			& \multicolumn{4}{c}{OLS} \\ \cline{2-5} ///
			& \multicolumn{2}{c}{Employment} & \multicolumn{2}{c}{Wages} \\ \cline{2-5} ///
			& (1) & (2) & (3) & (4) \\) ///
	 prefoot( \\ ) ///
	 postfoot( ///
			\hline ///
			"Occupation fixed effects" & \checkmark & \checkmark & \checkmark & \checkmark \\ ///
			"Demographics" & \checkmark & \checkmark & \checkmark & \checkmark \\ ///
			"State fixed effects" & &\checkmark  & & \checkmark \\ ///
			\hline \hline \end{tabular} } ///
			\begin{tablenotes}[para,flushleft] ///
				\footnotesize{NOTES. Table \ref{OLS} presents the OLS estimates of the marginal effects of exposure to robots on employment and wages under different concentration levels for 2006-2014. Columns 1 and 2 present results for employment-to-CZ-working-age-population ratio. Columns 3 and 4 present results for log annual wages. The demographic characteristics include the share of male, the share of elders (over 65), the share of the population with no college, some college, college or professional, and master or doctoral degree, the share of non-white, and the share of manufacturing industry workers. The standard errors are clustered at the state level. * p $<$.10, ** p$<$ .05, *** p$<$.01.} ///
			\end{tablenotes} ///
			\end{threeparttable}} ///
			\label{OLS} ///
			\end{center})
			
			
			
			
			
*endogenous both ER and HHI: Lewbel IV set 2
use regemp,clear
label var er_us_emp06 "Exposure to Robots"
label var hhi_new "HHI"
label var interaction "HHI*Exposure to Robots"
ivreghdfe d_emp_workpop06_ratio (er_us_emp06 interaction hhi_new=er_eu cnocoll_ehat cmanuf_ehat ivinteraction3 ivinteraction5) $demographic, absorb(occsoc) endog(er_us_emp06 hhi_new interaction) cluster(state)
		eststo result15col1
		eststo result15col1, add(Observations e(N))
		eststo result15col1, add(Underidentification e(idp))
		eststo result15col1, add(Weakidentification e(widstat))
		eststo result15col1, add(Overidentification e(jp))
		eststo result15col1, add(Endogeneity e(estatp))

ivreghdfe d_emp_workpop06_ratio (er_us_emp06 interaction hhi_new=er_eu cnocoll_ehat_2 cmanuf_ehat_2 ivinteraction5_2 ivinteraction3_2) $demographic, absorb(occsoc state) endog(er_us_emp06 hhi_new interaction) cluster(state)
		eststo result15col2
		eststo result15col2, add(Observations e(N))
		eststo result15col2, add(Underidentification e(idp))
		eststo result15col2, add(Weakidentification e(widstat))
		eststo result15col2, add(Overidentification e(jp))
		eststo result15col2, add(Endogeneity e(estatp))
		
use regwage,clear
label var er_us_emp06 "Exposure to Robots"
label var hhi_new "HHI"
label var interaction "HHI*Exposure to Robots"
ivreghdfe d_lnwage_0614 (er_us_emp06 interaction hhi_new=er_eu cmanuf_ehat cmastdoc_ehat ivinteraction4 ivinteraction6) $demographic, absorb(occsoc) endog(er_us_emp06 hhi_new interaction) cluster(state)
		eststo result15col3
		eststo result15col3, add(Observations e(N))
		eststo result15col3, add(Underidentification e(idp))
		eststo result15col3, add(Weakidentification e(widstat))
		eststo result15col3, add(Overidentification e(jp))
		eststo result15col3, add(Endogeneity e(estatp))
		
ivreghdfe d_lnwage_0614 (er_us_emp06 interaction hhi_new=er_eu cmastdoc_ehat_2 cmanuf_ehat_2 ivinteraction2_2 ivinteraction4_2) $demographic, absorb(occsoc state) endog(er_us_emp06 hhi_new interaction) cluster(state)
		eststo result15col4
		eststo result15col4, add(Observations e(N))
		eststo result15col4, add(Underidentification e(idp))
		eststo result15col4, add(Weakidentification e(widstat))
		eststo result15col4, add(Overidentification e(jp))
		eststo result15col4, add(Endogeneity e(estatp))			
************************************
********* MAKE LATEX TABLE *********
************************************
esttab result15col1 result15col2 result15col3 result15col4 ///
	using "$JMPproposal\result_LewbelIV2forHHI.tex", ///
	se nonotes  style(tex)  b(%12.3f) se(%12.3f)  ///
	starlevels(* 0.10 ** 0.05 *** 0.01) scalar(Underidentification Weakidentification Overidentification Endogeneity) label mlabels("" "" "" "" "" "" "" "" "" "" ) ///
	 keep(er_us_emp06 hhi_new interaction) nonumbers  replace  fragment  ///
	 prehead(\begin{center} ///
				\caption{Alternative Lewbel IVs: endogenous ER and HHI} ///
			\scalebox{1}{\begin{threeparttable} ///
			{\begin{tabular}{lcccccccccc} ///
			\hline \hline ///
			& \multicolumn{4}{c}{TSLS} \\ \cline{2-5} ///
			& \multicolumn{2}{c}{Employment} & \multicolumn{2}{c}{Wages} \\ \cline{2-5} ///
			& (1) & (2) & (3) & (4) \\) ///
	 prefoot( \\ ) ///
	 postfoot( ///
			\hline ///
			"Occupation fixed effects" & \checkmark & \checkmark & \checkmark & \checkmark \\ ///
			"Demographics" & \checkmark & \checkmark & \checkmark & \checkmark \\ ///
			"State fixed effects" & & \checkmark & & \checkmark \\ ///
			\hline \hline \end{tabular} } ///
			\begin{tablenotes}[para,flushleft] ///
				\footnotesize{NOTES. Table \ref{LewbelIV2forHHI} presents the IV estimates of the marginal effects of exposure to robots on employment and wages under different concentration levels for 2006-2014. Each labor market is defined as a CZ-by-occupation cell. In all columns, I instrument the US exposure to robots using the EURO5 exposure to robots, and HHI using a heteroskedasticity-based IV set. The set in the employment regressions contains the share of the population with no college degree and the share of manufacturing workers. The set in the wage regressions includes the share of population with master or doctoral degree and the share of manufacturing workers. Columns 1 and 2 present results for employment-to-CZ-working-age-population ratio. Columns 3 and 4 present results for log annual wages. The demographic characteristics include the share of male, the share of elders (over 65), the share of the population with no college, some college, college or professional, and master or doctoral degree, the share of non-white, and the share of manufacturing industry workers. The under-identification test reports p-value of the Kleibergen-Paap LM statistic. The weak identification test reports the Kleibergen-Paap Wald F statistic. The over-identification test reports p-value of the Hansen J statistic. The endogeneity test reports p-value of the chi-square statistic. Standard errors are clustered at the state level. * p $<$.10, ** p$<$ .05, *** p$<$.01.} ///
			\end{tablenotes} ///
			\end{threeparttable}} ///
			\label{LewbelIV2forHHI} ///
			\end{center})
			

			
* without fully concentrated markets
use regemp_nofullhhi,clear
label var er_us_emp06 "Exposure to Robots"
label var hhi_new "HHI"
label var interaction "HHI*Exposure to Robots"
ivreghdfe d_emp_workpop06_ratio (er_us_emp06 interaction hhi_new=er_eu ccollprof_ehat cmanuf_ehat ivinteraction2 ivinteraction6) $demographic, absorb(occsoc) endog(er_us_emp06 hhi_new interaction) cluster(state)
		eststo result16col1
		eststo result16col1, add(Observations e(N))
		eststo result16col1, add(Underidentification e(idp))
		eststo result16col1, add(Weakidentification e(widstat))
		eststo result16col1, add(Overidentification e(jp))
		eststo result16col1, add(Endogeneity e(estatp))

ivreghdfe d_emp_workpop06_ratio (er_us_emp06 interaction hhi_new=er_eu ccollprof_ehat_2 cmanuf_ehat_2 ivinteraction2_2 ivinteraction5_2) $demographic, absorb(occsoc state) endog(er_us_emp06 hhi_new interaction) cluster(state)
		eststo result16col2
		eststo result16col2, add(Observations e(N))
		eststo result16col2, add(Underidentification e(idp))
		eststo result16col2, add(Weakidentification e(widstat))
		eststo result16col2, add(Overidentification e(jp))
		eststo result16col2, add(Endogeneity e(estatp))
		
use regwage_nofullhhi,clear
label var er_us_emp06 "Exposure to Robots"
label var hhi_new "HHI"
label var interaction "HHI*Exposure to Robots"
ivreghdfe d_lnwage_0614 (er_us_emp06 interaction hhi_new=er_eu celder_ehat cmanuf_ehat ivinteraction4 ivinteraction5) $demographic, absorb(occsoc) endog(er_us_emp06 hhi_new interaction) cluster(state)
		eststo result16col3
		eststo result16col3, add(Observations e(N))
		eststo result16col3, add(Underidentification e(idp))
		eststo result16col3, add(Weakidentification e(widstat))
		eststo result16col3, add(Overidentification e(jp))
		eststo result16col3, add(Endogeneity e(estatp))

ivreghdfe d_lnwage_0614 (er_us_emp06 interaction hhi_new=er_eu celder_ehat_2 cmanuf_ehat_2 ivinteraction2_2 ivinteraction3_2) $demographic, absorb(occsoc state) endog(er_us_emp06 hhi_new interaction) cluster(state)
		eststo result16col4
		eststo result16col4, add(Observations e(N))
		eststo result16col4, add(Underidentification e(idp))
		eststo result16col4, add(Weakidentification e(widstat))
		eststo result16col4, add(Overidentification e(jp))
		eststo result16col4, add(Endogeneity e(estatp))	
************************************
********* MAKE LATEX TABLE *********
************************************
esttab result16col1 result16col2 result16col3 result16col4 ///
	using "$JMPproposal\result_LewbelIV1forHHI_nofullhhi.tex", ///
	se nonotes  style(tex)  b(%12.3f) se(%12.3f)  ///
	starlevels(* 0.10 ** 0.05 *** 0.01) scalar(Underidentification Weakidentification Overidentification Endogeneity) label mlabels("" "" "" "" "" "" "" "" "" "" ) ///
	 keep(er_us_emp06 hhi_new interaction) nonumbers  replace  fragment  ///
	 prehead(\begin{center} ///
				\caption{Without fully concentrated markets: endogenous ER and HHI} ///
			\scalebox{1}{\begin{threeparttable} ///
			{\begin{tabular}{lcccccccccc} ///
			\hline \hline ///
			& \multicolumn{4}{c}{TSLS} \\ \cline{2-5} ///
			& \multicolumn{2}{c}{Employment} & \multicolumn{2}{c}{Wages} \\ \cline{2-5} ///
			& (1) & (2) & (3) & (4) \\) ///
	 prefoot( \\ ) ///
	 postfoot( ///
			\hline ///
			"Occupation fixed effects" & \checkmark & \checkmark & \checkmark & \checkmark \\ ///
			"Demographics" & \checkmark & \checkmark & \checkmark & \checkmark \\ ///
			"State fixed effects" & & \checkmark & & \checkmark \\ ///
			\hline \hline \end{tabular} } ///
			\begin{tablenotes}[para,flushleft] ///
				\footnotesize{NOTES. Table \ref{LewbelIV1forHHI:nofullhhi} presents the IV estimates of the marginal effects of exposure to robots on employment and wages under different concentration levels for 2006-2014. Each labor market is defined as a CZ-by-occupation cell. The fully concentrated markets are excluded from the sample. In all columns, I instrument the US exposure to robots using the EURO5 exposure to robots, and HHI using a heteroskedasticity-based IV set. The set in the employment regressions contains the share of the population with college or professional degree and the share of manufacturing workers. The set in the wage regressions includes the share of elders (over 65) and the share of manufacturing workers. Columns 1 and 2 present results for employment-to-CZ-working-age-population ratio. Columns 3 and 4 present results for log annual wages. The demographic characteristics include the share of male, the share of elders (over 65), the share of the population with no college, some college, college or professional, and master or doctoral degree, the share of non-white, and the share of manufacturing industry workers. The under-identification test reports p-value of the Kleibergen-Paap LM statistic. The weak identification test reports the Kleibergen-Paap Wald F statistic. The over-identification test reports p-value of the Hansen J statistic. The endogeneity test reports p-value of the chi-square statistic. Standard errors are clustered at the state level. * p $<$.10, ** p$<$ .05, *** p$<$.01.} ///
			\end{tablenotes} ///
			\end{threeparttable}} ///
			\label{LewbelIV1forHHI:nofullhhi} ///
			\end{center})			
			

			
* weighted regression of Lewbel IV set 1
use regemp,clear
label var er_us_emp06 "Exposure to Robots"
label var hhi_new "HHI"
label var interaction "HHI*Exposure to Robots"
ivreghdfe d_emp_workpop06_ratio (er_us_emp06 interaction hhi_new=er_eu ccollprof_ehat cmanuf_ehat ivinteraction2 ivinteraction5) $demographic [weight=emp_lm06], absorb(occsoc) endog(er_us_emp06 hhi_new interaction) cluster(state)
		eststo result17col1
		eststo result17col1, add(Observations e(N))
		eststo result17col1, add(Underidentification e(idp))
		eststo result17col1, add(Weakidentification e(widstat))
		eststo result17col1, add(Overidentification e(jp))
		eststo result17col1, add(Endogeneity e(estatp))

ivreghdfe d_emp_workpop06_ratio (er_us_emp06 interaction hhi_new=er_eu ccollprof_ehat_2 cmanuf_ehat_2 ivinteraction2_2 ivinteraction3_2) $demographic [weight=emp_lm06], absorb(occsoc state) endog(er_us_emp06 hhi_new interaction) cluster(state)
		eststo result17col2
		eststo result17col2, add(Observations e(N))
		eststo result17col2, add(Underidentification e(idp))
		eststo result17col2, add(Weakidentification e(widstat))
		eststo result17col2, add(Overidentification e(jp))
		eststo result17col2, add(Endogeneity e(estatp))
		
use regwage,clear
label var er_us_emp06 "Exposure to Robots"
label var hhi_new "HHI"
label var interaction "HHI*Exposure to Robots"
ivreghdfe d_lnwage_0614 (er_us_emp06 interaction hhi_new=er_eu celder_ehat cmanuf_ehat ivinteraction3 ivinteraction4) $demographic [weight=emp_lm06], absorb(occsoc) endog(er_us_emp06 hhi_new interaction) cluster(state)
		eststo result17col3
		eststo result17col3, add(Observations e(N))
		eststo result17col3, add(Underidentification e(idp))
		eststo result17col3, add(Weakidentification e(widstat))
		eststo result17col3, add(Overidentification e(jp))
		eststo result17col3, add(Endogeneity e(estatp))

ivreghdfe d_lnwage_0614 (er_us_emp06 interaction hhi_new=er_eu celder_ehat_2 cmanuf_ehat_2 ivinteraction4_2 ivinteraction5_2) $demographic [weight=emp_lm06], absorb(occsoc state) endog(er_us_emp06 hhi_new interaction) cluster(state)
		eststo result17col4
		eststo result17col4, add(Observations e(N))
		eststo result17col4, add(Underidentification e(idp))
		eststo result17col4, add(Weakidentification e(widstat))
		eststo result17col4, add(Overidentification e(jp))
		eststo result17col4, add(Endogeneity e(estatp))	
************************************
********* MAKE LATEX TABLE *********
************************************
esttab result17col1 result17col2 result17col3 result17col4 ///
	using "$JMPproposal\result_LewbelIV1forHHI_weighted.tex", ///
	se nonotes  style(tex)  b(%12.3f) se(%12.3f)  ///
	starlevels(* 0.10 ** 0.05 *** 0.01) scalar(Underidentification Weakidentification Overidentification Endogeneity) label mlabels("" "" "" "" "" "" "" "" "" "" ) ///
	 keep(er_us_emp06 hhi_new interaction) nonumbers  replace  fragment  ///
	 prehead(\begin{center} ///
				\caption{Weighted regressions: endogenous ER and HHI} ///
			\scalebox{1}{\begin{threeparttable} ///
			{\begin{tabular}{lcccccccccc} ///
			\hline \hline ///
			& \multicolumn{4}{c}{TSLS} \\ \cline{2-5} ///
			& \multicolumn{2}{c}{Employment} & \multicolumn{2}{c}{Wages} \\ \cline{2-5} ///
			& (1) & (2) & (3) & (4) \\) ///
	 prefoot( \\ ) ///
	 postfoot( ///
			\hline ///
			"Occupation fixed effects" & \checkmark & \checkmark & \checkmark & \checkmark \\ ///
			"Demographics" & \checkmark & \checkmark & \checkmark & \checkmark \\ ///
			"State fixed effects" & & \checkmark & & \checkmark \\ ///
			\hline \hline \end{tabular} } ///
			\begin{tablenotes}[para,flushleft] ///
				\footnotesize{NOTES. Table \ref{LewbelIV1forHHI:weighted} presents the IV estimates of the marginal effects of exposure to robots on employment and wages under different concentration levels for 2006-2014. Each labor market is defined as a CZ-by-occupation cell. Regressions are weighted by the market-level employment. In all columns, I instrument the US exposure to robots using the EURO5 exposure to robots, and HHI using a heteroskedasticity-based IV set. The set in the employment regressions contains the share of the population with college or professional degree and the share of manufacturing workers. The set in the wage regressions includes the share of elders (over 65) and the share of manufacturing workers. Columns 1 and 2 present results for employment-to-CZ-working-age-population ratio. Columns 3 and 4 present results for log annual wages. The demographic characteristics include the share of male, the share of elders (over 65), the share of the population with no college, some college, college or professional, and master or doctoral degree, the share of non-white, and the share of manufacturing industry workers. The under-identification test reports p-value of the Kleibergen-Paap LM statistic. The weak identification test reports the Kleibergen-Paap Wald F statistic. The over-identification test reports p-value of the Hansen J statistic. The endogeneity test reports p-value of the chi-square statistic. Standard errors are clustered at the state level. * p $<$.10, ** p$<$ .05, *** p$<$.01.} ///
			\end{tablenotes} ///
			\end{threeparttable}} ///
			\label{LewbelIV1forHHI:weighted} ///
			\end{center})
			
			
* endogenous ER only: weighted
use regemp,clear
label var er_us_emp06 "Exposure to Robots"
label var hhi_new "HHI"
label var interaction "HHI*Exposure to Robots"
ivreghdfe d_emp_workpop06_ratio (er_us_emp06 interaction=er_eu ivinteraction) hhi_new $demographic [weight=emp_lm06], absorb(occsoc) endog(er_us_emp06 interaction) cluster(state)
		eststo result18col1
		eststo result18col1, add(Observations e(N))
		eststo result18col1, add(Underidentification e(idp))
		eststo result18col1, add(Weakidentification e(widstat))
		eststo result18col1, add(Endogeneity e(estatp))

ivreghdfe d_emp_workpop06_ratio (er_us_emp06 interaction=er_eu ivinteraction) hhi_new $demographic [weight=emp_lm06], absorb(occsoc state) endog(er_us_emp06 interaction) cluster(state)
		eststo result18col2
		eststo result18col2, add(Observations e(N))
		eststo result18col2, add(Underidentification e(idp))
		eststo result18col2, add(Weakidentification e(widstat))
		eststo result18col2, add(Endogeneity e(estatp))

use regwage,clear
label var er_us_emp06 "Exposure to Robots"
label var hhi_new "HHI"
label var interaction "HHI*Exposure to Robots"
ivreghdfe d_lnwage_0614 (er_us_emp06 interaction=er_eu ivinteraction) hhi_new $demographic [weight=emp_lm06], absorb(occsoc) endog(er_us_emp06 interaction) cluster(state)
		eststo result18col3
		eststo result18col3, add(Observations e(N))
		eststo result18col3, add(Underidentification e(idp))
		eststo result18col3, add(Weakidentification e(widstat))
		eststo result18col3, add(Endogeneity e(estatp))

ivreghdfe d_lnwage_0614 (er_us_emp06 interaction=er_eu ivinteraction) hhi_new $demographic [weight=emp_lm06], absorb(occsoc state) endog(er_us_emp06 interaction) cluster(state)
		eststo result18col4
		eststo result18col4, add(Observations e(N))
		eststo result18col4, add(Underidentification e(idp))
		eststo result18col4, add(Weakidentification e(widstat))
		eststo result18col4, add(Endogeneity e(estatp))	
************************************
********* MAKE LATEX TABLE *********
************************************
esttab result18col1 result18col2 result18col3 result18col4 ///
	using "$JMPproposal\result_noIVforHHI_weighted.tex", ///
	se nonotes  style(tex)  b(%12.3f) se(%12.3f)  ///
	starlevels(* 0.10 ** 0.05 *** 0.01) scalar(Underidentification Weakidentification Endogeneity) label mlabels("" "" "" "" "" "" "" "" "" "" ) ///
	 keep(er_us_emp06 hhi_new interaction) nonumbers  replace  fragment  ///
	 prehead(\begin{center} ///
				\caption{Weighted regressions: endogenous ER; exogenous HHI} ///
			\scalebox{1}[1]{\begin{threeparttable} ///
			{\begin{tabular}{lcccccccccc} ///
			\hline \hline ///
			& \multicolumn{4}{c}{TSLS} \\ \cline{2-5} ///
			& \multicolumn{2}{c}{Employment} & \multicolumn{2}{c}{Wages} \\ \cline{2-5} ///
			& (1) & (2) & (3) & (4) \\) ///
	 prefoot( \\ ) ///
	 postfoot( ///
			\hline ///
			"Occupation fixed effects" & \checkmark & \checkmark & \checkmark & \checkmark \\ ///
			"Demographics" & \checkmark & \checkmark & \checkmark & \checkmark \\ ///
			"State fixed effects" & & \checkmark & & \checkmark \\ ///
			\hline \hline \end{tabular} } ///
			\begin{tablenotes}[para,flushleft] ///
				\footnotesize{NOTES. Table \ref{noIVforHHI：weighted} presents the IV estimates of the marginal effects of exposure to robots on employment and wages under different concentration levels for 2006-2014. Each labor market is defined as a CZ-by-occupation cell. Regressions are weighted by the market-level employment. In all columns, I instrument the US exposure to robots using the EURO5 exposure to robots and treat HHI exogenous. Columns 1 and 2 present results for employment-to-CZ-working-age-population ratio. Columns 3 and 4 present results for log annual wages. The demographic characteristics include the share of male, the share of elders (over 65), the share of the population with no college, some college, college or professional, and master or doctoral degree, the share of non-white, and the share of manufacturing industry workers. The under-identification test reports p-value of the Kleibergen-Paap LM statistic. The weak identification test reports the Kleibergen-Paap Wald F statistic. The over-identification test reports p-value of the Hansen J statistic. The endogeneity test reports p-value of the chi-square statistic. Standard errors are clustered at the state level. * p $<$.10, ** p$<$ .05, *** p$<$.01.} ///
			\end{tablenotes} ///
			\end{threeparttable}} ///
			\label{noIVforHHI：weighted} ///
			\end{center})
*********************************************************************
************************** Results Figures **************************
*********************************************************************



*************** unweighted ***************

use regemp,clear


***** results graph1 *****
ivreghdfe d_emp_workpop06_ratio (er_us_emp06 interaction=er_eu ivinteraction) hhi_new $demographic, absorb(occsoc state) endog(er_us_emp06 interaction) cluster(state)

		preserve
				g b= _b[er_us_emp06] + _b[interaction]*hhi_new
				matrix v=e(V)
				g var_b=v[1,1]+hhi_new^2*v[2,2]+hhi_new*v[2,1]*2
				g se_b=sqrt(var_b)
				g lb=b-invttail(e(df_r),0.025)*se_b
				g ub=b+invttail(e(df_r),0.025)*se_b
				collapse (mean) b lb ub, by(hhi_new)
				twoway (rarea ub lb hhi_new, sort fcolor(gs10) lcolor(gs0)) (connected b hhi_new,lpattern(dash) lcolor(green) ms(i)), yline(0, lcolor(black)) ///
							 ytitle("Effects on change in employment-to-population ratio ({it:in 10{sup:-3}})",size(small)) xtitle("HHI ({it:in 10{sup:4}})",size(small)) xline(0, lcolor(black)) ///
							legend(size(vsmall) order(2 1) r(2) label(1 "95% Confidence Interval") label(2 "TSLS estimates of robot effect on employment")) ///
							graphregion(fcolor(white) ifcolor(white) ilcolor(white)) plotregion(fcolor(white) ifcolor(white) ilcolor(white) margin(b+2))
				
				graph save "$results\graphs\result_noIVforHHI_col2.png",replace
		restore

		
***** results graph2 *****
ivreghdfe d_emp_workpop06_ratio (er_us_emp06 interaction hhi_new=er_eu ccollprof_ehat_2 cmanuf_ehat_2 ivinteraction2_2 ivinteraction3_2) $demographic, absorb(occsoc state) endog(er_us_emp06 hhi_new interaction) cluster(state)

		preserve
				g b= _b[er_us_emp06] + _b[interaction]*hhi_new
				matrix v=e(V)
				g var_b=v[1,1]+hhi_new^2*v[2,2]+hhi_new*v[2,1]*2
				g se_b=sqrt(var_b)
				g lb=b-invttail(e(df_r),0.025)*se_b
				g ub=b+invttail(e(df_r),0.025)*se_b
				collapse (mean) b lb ub, by(hhi_new)
				twoway (rarea ub lb hhi_new, sort fcolor(gs10) lcolor(gs0)) (connected b hhi_new,lpattern(dash) lcolor(green) ms(i)), yline(0, lcolor(black)) ///
						 ytitle("Effects on change in employment-to-population ratio ({it:in 10{sup:-3}})",size(small)) xtitle("HHI ({it:in 10{sup:4}})",size(small)) xline(0, lcolor(black)) ///
							legend(size(vsmall) order(2 1) r(2) label(1 "95% Confidence Interval") label(2 "TSLS estimates of robot effect on employment")) ///
							graphregion(fcolor(white) ifcolor(white) ilcolor(white)) plotregion(fcolor(white) ifcolor(white) ilcolor(white) margin(b+2))
							
				graph save "$results\graphs\result_LewbelIV1forHHI_col2.png",replace
						
		restore

		
		
***** results graph3 *****
ivreghdfe d_emp_workpop06_ratio (er_us_emp06 interaction hhi_new=er_eu cnocoll_ehat_2 cmanuf_ehat_2 ivinteraction5_2 ivinteraction3_2) $demographic, absorb(occsoc state) endog(er_us_emp06 hhi_new interaction) cluster(state)
					
	preserve
		g b= _b[er_us_emp06] + _b[interaction]*hhi_new
		matrix v=e(V)
		g var_b=v[1,1]+hhi_new^2*v[2,2]+hhi_new*v[2,1]*2
		g se_b=sqrt(var_b)
		g lb=b-invttail(e(df_r),0.025)*se_b
		g ub=b+invttail(e(df_r),0.025)*se_b
		collapse (mean) b lb ub, by(hhi_new)
		twoway (rarea ub lb hhi_new, sort fcolor(gs10) lcolor(gs0)) (connected b hhi_new,lpattern(dash) lcolor(green) ms(i)), yline(0, lcolor(black)) ///
					title("IV set 2",size(small)) ytitle("Effects on change in employment-to-population ratio ({it:in 10{sup:-3}})",size(small)) xtitle("HHI ({it:in 10{sup:4}})",size(small)) xline(0, lcolor(black)) ///
					legend(size(vsmall) order(2 1) r(2) label(1 "95% Confidence Interval") label(2 "TSLS estimates of robot effect on employment")) ///
					graphregion(fcolor(white) ifcolor(white) ilcolor(white)) plotregion(fcolor(white) ifcolor(white) ilcolor(white) margin(b+2))

		graph save "$results\graphs\result_LewbelIV2forHHI_col2.png",replace

	restore

	
***** results graph4 *****
use regemp_nofullhhi,clear
ivreghdfe d_emp_workpop06_ratio (er_us_emp06 interaction hhi_new=er_eu ccollprof_ehat_2 cmanuf_ehat_2 ivinteraction2_2 ivinteraction5_2) $demographic, absorb(occsoc state) endog(er_us_emp06 hhi_new interaction) cluster(state)

		preserve
				g b= _b[er_us_emp06] + _b[interaction]*hhi_new
				matrix v=e(V)
				g var_b=v[1,1]+hhi_new^2*v[2,2]+hhi_new*v[2,1]*2
				g se_b=sqrt(var_b)
				g lb=b-invttail(e(df_r),0.025)*se_b
				g ub=b+invttail(e(df_r),0.025)*se_b
				collapse (mean) b lb ub, by(hhi_new)
				twoway (rarea ub lb hhi_new, sort fcolor(gs10) lcolor(gs0)) (connected b hhi_new,lpattern(dash) lcolor(green) ms(i)), yline(0, lcolor(black)) ///
							title("Without fully concentrated markets",size(small))  ytitle("Effects on change in employment-to-population ratio ({it:in 10{sup:-3}})",size(small)) xtitle("HHI ({it:in 10{sup:4}})",size(small)) xline(0, lcolor(black)) ///
							legend(size(vsmall) order(2 1) r(2) label(1 "95% Confidence Interval") label(2 "TSLS estimates of robot effect on employment")) ///
							graphregion(fcolor(white) ifcolor(white) ilcolor(white)) plotregion(fcolor(white) ifcolor(white) ilcolor(white) margin(b+2))
							
				graph save "$results\graphs\result_LewbelIV1forHHI_nofullhhi_col2.png",replace
						
		restore
	
	
***** results graph5 *****
use regwage,clear
ivreghdfe d_lnwage_0614 (er_us_emp06 interaction=er_eu ivinteraction) hhi_new $demographic, absorb(occsoc state) endog(er_us_emp06 interaction) cluster(state)

	preserve
		g b= _b[er_us_emp06] + _b[interaction]*hhi_new
		matrix v=e(V)
		g var_b=v[1,1]+hhi_new^2*v[2,2]+hhi_new*v[2,1]*2
		g se_b=sqrt(var_b)
		g lb=b-invttail(e(df_r),0.025)*se_b
		g ub=b+invttail(e(df_r),0.025)*se_b
		collapse (mean) b lb ub, by(hhi_new)
		twoway (rarea ub lb hhi_new, sort fcolor(gs10) lcolor(gs0)) (connected b hhi_new,lpattern(dash) lcolor(green) ms(i)), yline(0, lcolor(black)) ///
					 ytitle("Effects on change in log annual wages",size(small)) xtitle("HHI ({it:in 10{sup:4}})",size(small)) xline(0, lcolor(black)) ///
					legend(size(vsmall) order(2 1) r(2) label(1 "95% Confidence Interval") label(2 "TSLS estimates of robot effect on wages")) ///
					graphregion(fcolor(white) ifcolor(white) ilcolor(white)) plotregion(fcolor(white) ifcolor(white) ilcolor(white) margin(b+2))
		
		graph save "$results\graphs\result_noIVforHHI_col4.png",replace
		
	restore
	

	
***** results graph6 *****
ivreghdfe d_lnwage_0614 (er_us_emp06 interaction hhi_new=er_eu celder_ehat_2 cmanuf_ehat_2 ivinteraction4_2 ivinteraction5_2) $demographic, absorb(occsoc state) endog(er_us_emp06 hhi_new interaction) cluster(state)

	preserve
		g b= _b[er_us_emp06] + _b[interaction]*hhi_new
		matrix v=e(V)
		g var_b=v[1,1]+hhi_new^2*v[2,2]+hhi_new*v[2,1]*2
		g se_b=sqrt(var_b)
		g lb=b-invttail(e(df_r),0.025)*se_b
		g ub=b+invttail(e(df_r),0.025)*se_b
		collapse (mean) b lb ub, by(hhi_new)
		twoway (rarea ub lb hhi_new, sort fcolor(gs10) lcolor(gs0)) (connected b hhi_new,lpattern(dash) lcolor(green) ms(i)), yline(0, lcolor(black)) ///
					 ytitle("Effects on change in log annual wages",size(small)) xtitle("HHI ({it:in 10{sup:4}})",size(small)) xline(0, lcolor(black)) ///
					legend(size(vsmall) order(2 1) r(2) label(1 "95% Confidence Interval") label(2 "TSLS estimates of robot effect on wages")) ///
					graphregion(fcolor(white) ifcolor(white) ilcolor(white)) plotregion(fcolor(white) ifcolor(white) ilcolor(white) margin(b+2))
		
		graph save "$results\graphs\result_LewbelIV1forHHI_col4.png",replace
		
	restore
	
	
***** results graph7 *****	
ivreghdfe d_lnwage_0614 (er_us_emp06 interaction hhi_new=er_eu cmastdoc_ehat_2 cmanuf_ehat_2 ivinteraction2_2 ivinteraction4_2) $demographic, absorb(occsoc state) endog(er_us_emp06 hhi_new interaction) cluster(state)
	
	preserve
		g b= _b[er_us_emp06] + _b[interaction]*hhi_new
		matrix v=e(V)
		g var_b=v[1,1]+hhi_new^2*v[2,2]+hhi_new*v[2,1]*2
		g se_b=sqrt(var_b)
		g lb=b-invttail(e(df_r),0.025)*se_b
		g ub=b+invttail(e(df_r),0.025)*se_b
		collapse (mean) b lb ub, by(hhi_new)
		twoway (rarea ub lb hhi_new, sort fcolor(gs10) lcolor(gs0)) (connected b hhi_new,lpattern(dash) lcolor(green) ms(i)), yline(0, lcolor(black)) ///
					title("IV set 2",size(small)) ytitle("Effects on change in log annual wages",size(small)) xtitle("HHI ({it:in 10{sup:4}})",size(small)) xline(0, lcolor(black)) ///
					legend(size(vsmall) order(2 1) r(2) label(1 "95% Confidence Interval") label(2 "TSLS estimates of robot effect on wages")) ///
					graphregion(fcolor(white) ifcolor(white) ilcolor(white)) plotregion(fcolor(white) ifcolor(white) ilcolor(white) margin(b+2))
		
		graph save "$results\graphs\result_LewbelIV2forHHI_col4.png",replace
		
	restore

	
***** results graph8 *****
use regwage_nofullhhi,clear
ivreghdfe d_lnwage_0614 (er_us_emp06 interaction hhi_new=er_eu celder_ehat_2 cmanuf_ehat_2 ivinteraction2_2 ivinteraction3_2) $demographic, absorb(occsoc state) endog(er_us_emp06 hhi_new interaction) cluster(state)

	preserve
		g b= _b[er_us_emp06] + _b[interaction]*hhi_new
		matrix v=e(V)
		g var_b=v[1,1]+hhi_new^2*v[2,2]+hhi_new*v[2,1]*2
		g se_b=sqrt(var_b)
		g lb=b-invttail(e(df_r),0.025)*se_b
		g ub=b+invttail(e(df_r),0.025)*se_b
		collapse (mean) b lb ub, by(hhi_new)
		twoway (rarea ub lb hhi_new, sort fcolor(gs10) lcolor(gs0)) (connected b hhi_new,lpattern(dash) lcolor(green) ms(i)), yline(0, lcolor(black)) ///
					title("Without fully concentrated markets",size(small)) ytitle("Effects on change in log annual wages",size(small)) xtitle("HHI ({it:in 10{sup:4}})",size(small)) xline(0, lcolor(black)) ///
					legend(size(vsmall) order(2 1) r(2) label(1 "95% Confidence Interval") label(2 "TSLS estimates of robot effect on wages")) ///
					graphregion(fcolor(white) ifcolor(white) ilcolor(white)) plotregion(fcolor(white) ifcolor(white) ilcolor(white) margin(b+2))
		
		graph save "$results\graphs\result_LewbelIV1forHHI_nofullhhi_col4.png",replace
		
	restore
	

*************** weighted ***************




***** results graph9 *****
use regemp,clear
ivreghdfe d_emp_workpop06_ratio (er_us_emp06 interaction=er_eu ivinteraction) hhi_new $demographic [weight=emp_lm06], absorb(occsoc state) endog(er_us_emp06 interaction) cluster(state)

		preserve
				g b= _b[er_us_emp06] + _b[interaction]*hhi_new
				matrix v=e(V)
				g var_b=v[1,1]+hhi_new^2*v[2,2]+hhi_new*v[2,1]*2
				g se_b=sqrt(var_b)
				g lb=b-invttail(e(df_r),0.025)*se_b
				g ub=b+invttail(e(df_r),0.025)*se_b
				collapse (mean) b lb ub, by(hhi_new)
				twoway (rarea ub lb hhi_new, sort fcolor(gs10) lcolor(gs0)) (connected b hhi_new,lpattern(dash) lcolor(green) ms(i)), yline(0, lcolor(black)) ///
							title("Weighted regression",size(small)) ytitle("Effects on change in employment-to-population ratio ({it:in 10{sup:-3}})",size(small)) xtitle("HHI ({it:in 10{sup:4}})",size(small)) xline(0, lcolor(black)) ///
							legend(size(vsmall) order(2 1) r(2) label(1 "95% Confidence Interval") label(2 "TSLS estimates of robot effect on employment")) ///
							graphregion(fcolor(white) ifcolor(white) ilcolor(white)) plotregion(fcolor(white) ifcolor(white) ilcolor(white) margin(b+2))
				
				graph save "$results\graphs\result_noIVforHHI_weighted_col2.png",replace
		restore

		
***** results graph10 *****
ivreghdfe d_emp_workpop06_ratio (er_us_emp06 interaction hhi_new=er_eu ccollprof_ehat_2 cmanuf_ehat_2 ivinteraction2_2 ivinteraction3_2) $demographic [weight=emp_lm06], absorb(occsoc state) endog(er_us_emp06 hhi_new interaction) cluster(state)


		preserve
				g b= _b[er_us_emp06] + _b[interaction]*hhi_new
				matrix v=e(V)
				g var_b=v[1,1]+hhi_new^2*v[2,2]+hhi_new*v[2,1]*2
				g se_b=sqrt(var_b)
				g lb=b-invttail(e(df_r),0.025)*se_b
				g ub=b+invttail(e(df_r),0.025)*se_b
				collapse (mean) b lb ub, by(hhi_new)
				twoway (rarea ub lb hhi_new, sort fcolor(gs10) lcolor(gs0)) (connected b hhi_new,lpattern(dash) lcolor(green) ms(i)), yline(0, lcolor(black)) ///
							title("Weighted regression",size(small)) ytitle("Effects on change in employment-to-population ratio ({it:in 10{sup:-3}})",size(small)) xtitle("HHI ({it:in 10{sup:4}})",size(small)) xline(0, lcolor(black)) ///
							legend(size(vsmall) order(2 1) r(2) label(1 "95% Confidence Interval") label(2 "TSLS estimates of robot effect on employment")) ///
							graphregion(fcolor(white) ifcolor(white) ilcolor(white)) plotregion(fcolor(white) ifcolor(white) ilcolor(white) margin(b+2))
							
				graph save "$results\graphs\result_LewbelIV1forHHI_weighted_col2.png",replace
						
		restore


		
***** results graph11 *****	
use regwage,clear
ivreghdfe d_lnwage_0614 (er_us_emp06 interaction=er_eu ivinteraction) hhi_new $demographic [weight=emp_lm06], absorb(occsoc state) endog(er_us_emp06 interaction) cluster(state)

	preserve
		g b= _b[er_us_emp06] + _b[interaction]*hhi_new
		matrix v=e(V)
		g var_b=v[1,1]+hhi_new^2*v[2,2]+hhi_new*v[2,1]*2
		g se_b=sqrt(var_b)
		g lb=b-invttail(e(df_r),0.025)*se_b
		g ub=b+invttail(e(df_r),0.025)*se_b
		collapse (mean) b lb ub, by(hhi_new)
		twoway (rarea ub lb hhi_new, sort fcolor(gs10) lcolor(gs0)) (connected b hhi_new,lpattern(dash) lcolor(green) ms(i)), yline(0, lcolor(black)) ///
					title("Weighted regression",size(small)) ytitle("Effects on change in log annual wages",size(small)) xtitle("HHI ({it:in 10{sup:4}})",size(small)) xline(0, lcolor(black)) ///
					legend(size(vsmall) order(2 1) r(2) label(1 "95% Confidence Interval") label(2 "TSLS estimates of robot effect on wages")) ///
					graphregion(fcolor(white) ifcolor(white) ilcolor(white)) plotregion(fcolor(white) ifcolor(white) ilcolor(white) margin(b+2))
		
		graph save "$results\graphs\result_noIVforHHI_weighted_col4.png",replace
		
	restore
	

	
***** results graph12 *****
ivreghdfe d_lnwage_0614 (er_us_emp06 interaction hhi_new=er_eu celder_ehat_2 cmanuf_ehat_2 ivinteraction4_2 ivinteraction5_2) $demographic [weight=emp_lm06], absorb(occsoc state) endog(er_us_emp06 hhi_new interaction) cluster(state)

	preserve
		g b= _b[er_us_emp06] + _b[interaction]*hhi_new
		matrix v=e(V)
		g var_b=v[1,1]+hhi_new^2*v[2,2]+hhi_new*v[2,1]*2
		g se_b=sqrt(var_b)
		g lb=b-invttail(e(df_r),0.025)*se_b
		g ub=b+invttail(e(df_r),0.025)*se_b
		collapse (mean) b lb ub, by(hhi_new)
		twoway (rarea ub lb hhi_new, sort fcolor(gs10) lcolor(gs0)) (connected b hhi_new,lpattern(dash) lcolor(green) ms(i)), yline(0, lcolor(black)) ///
					title("Weighted regression",size(small)) ytitle("Effects on change in log annual wages",size(small)) xtitle("HHI ({it:in 10{sup:4}})",size(small)) xline(0, lcolor(black)) ///
					legend(size(vsmall) order(2 1) r(2) label(1 "95% Confidence Interval") label(2 "TSLS estimates of robot effect on wages")) ///
					graphregion(fcolor(white) ifcolor(white) ilcolor(white)) plotregion(fcolor(white) ifcolor(white) ilcolor(white) margin(b+2))
		
		graph save "$results\graphs\result_LewbelIV1forHHI_weighted_col4.png",replace
		
	restore
		
	/*	
***** results graph8 *****
ivreghdfe d_emp_workpop06_ratio (er_us_emp06 interaction hhi_new=er_eu cmastdoc_ehat cmanuf_ehat cmale_ehat ivinteraction4 ivinteraction5 ivinteraction6) $demographic [weight=emp_lm06], absorb(occsoc state) endog(er_us_emp06 hhi_new interaction) cluster(state)
					
	preserve
		g b= _b[er_us_emp06] + _b[interaction]*hhi_new
		matrix v=e(V)
		g var_b=v[1,1]+hhi_new^2*v[2,2]+hhi_new*v[2,1]*2
		g se_b=sqrt(var_b)
		g lb=b-invttail(e(df_r),0.025)*se_b
		g ub=b+invttail(e(df_r),0.025)*se_b
		collapse (mean) b lb ub, by(hhi_new)
		twoway (rarea ub lb hhi_new, sort fcolor(gs10) lcolor(gs0)) (connected b hhi_new,lpattern(dash) lcolor(green) ms(i)), yline(0, lcolor(black)) ///
					title("Effect of Robots on Employment vs HHI in US: IV estimates 2",size(medium)) ytitle("Effect on change in employment-to-population ratio ({it:in 10{sup:-3}})",size(small)) xtitle("HHI ({it:in 10{sup:4}})",size(small)) xline(0, lcolor(black)) ///
					legend(size(vsmall) order(2 1) r(2) label(1 "95% Confidence Interval") label(2 "TSLS estimates of robot effect on employment")) ///
					graphregion(fcolor(white) ifcolor(white) ilcolor(white)) plotregion(fcolor(white) ifcolor(white) ilcolor(white) margin(b+2)) ///

		graph save "$results\graphs\tab5col4.png",replace

	restore

	
***** results graph9 *****
use regwage,clear
reghdfe d_wage_0614 er_us_emp06 interaction hhi_new $demographic cz_workpop [weight=emp_lm06], absorb(occsoc state) cluster(state)

	preserve
		g b= _b[er_us_emp06] + _b[interaction]*hhi_new
		matrix v=e(V)
		g var_b=v[1,1]+hhi_new^2*v[2,2]+hhi_new*v[2,1]*2
		g se_b=sqrt(var_b)
		g lb=b-invttail(e(df_r),0.025)*se_b
		g ub=b+invttail(e(df_r),0.025)*se_b
		collapse (mean) b lb ub, by(hhi_new)
		twoway (rarea ub lb hhi_new, sort fcolor(gs10) lcolor(gs0)) (connected b hhi_new,lpattern(dash) lcolor(green) ms(i)), yline(0, lcolor(black)) ///
					title("Effect of Robots on Wage vs HHI in US: OLS estimates",size(medium)) ytitle("Effect on change in average annual wage",size(small)) xtitle("HHI ({it:in 10{sup:4}})",size(small)) xline(0, lcolor(black)) ///
					legend(size(vsmall) order(2 1) r(2) label(1 "95% Confidence Interval") label(2 "OLS estimates of robot effect on wage")) ///
					graphregion(fcolor(white) ifcolor(white) ilcolor(white)) plotregion(fcolor(white) ifcolor(white) ilcolor(white) margin(b+2)) ///
		
		graph save "$results\graphs\tab6col4.png",replace
		
	restore
	

	
***** results graph10 *****
ivreghdfe d_wage_0614 (er_us_emp06 interaction hhi_new=er_eu cworkpop_ehat cmanuf_ehat ///
   ivinteraction1 ivinteraction4) $demographic cz_workpop [weight=emp_lm06], absorb(occsoc state) endog(er_us_emp06 hhi_new interaction) cluster(state)

	preserve
		g b= _b[er_us_emp06] + _b[interaction]*hhi_new
		matrix v=e(V)
		g var_b=v[1,1]+hhi_new^2*v[2,2]+hhi_new*v[2,1]*2
		g se_b=sqrt(var_b)
		g lb=b-invttail(e(df_r),0.025)*se_b
		g ub=b+invttail(e(df_r),0.025)*se_b
		collapse (mean) b lb ub, by(hhi_new)
		twoway (rarea ub lb hhi_new, sort fcolor(gs10) lcolor(gs0)) (connected b hhi_new,lpattern(dash) lcolor(green) ms(i)), yline(0, lcolor(black)) ///
					title("Effect of Robots on Wage vs HHI in US: IV estimates",size(medium)) ytitle("Effect on change in average annual wage",size(small)) xtitle("HHI ({it:in 10{sup:4}})",size(small)) xline(0, lcolor(black)) ///
					legend(size(vsmall) order(2 1) r(2) label(1 "95% Confidence Interval") label(2 "TSLS estimates of robot effect on wage")) ///
					graphregion(fcolor(white) ifcolor(white) ilcolor(white)) plotregion(fcolor(white) ifcolor(white) ilcolor(white) margin(b+2)) ///
		
		graph save "$results\graphs\tab7col4.png",replace
		
	restore
	
*/


use regemp,clear
sum rti1_rank


***** results graph1 *****
*ivreghdfe d_emp_workpop06_ratio (er_us_emp06 interaction=er_eu ivinteraction) hhi_new $demographic, absorb(occsoc state) endog(er_us_emp06 interaction) cluster(state)
					
*ivreghdfe d_emp_workpop06_ratio (er_us_emp06 interaction hhi_new=er_eu cmanuf_ehat cmale_ehat ivinteraction5 ivinteraction6) $demographic, absorb(occsoc state) endog(er_us_emp06 hhi_new interaction) cluster(state)

preserve
		keep if rti1_rank<148		
ivreghdfe d_emp_workpop06_ratio (er_us_emp06 interaction=er_eu ivinteraction) hhi_new $demographic, absorb(occsoc state) endog(er_us_emp06 interaction) cluster(state)
				g b= _b[er_us_emp06] + _b[interaction]*hhi_new
				matrix v=e(V)
				g var_b=v[1,1]+hhi_new^2*v[2,2]+hhi_new*v[2,1]*2
				g se_b=sqrt(var_b)
				g lb=b-invttail(e(df_r),0.025)*se_b
				g ub=b+invttail(e(df_r),0.025)*se_b
				collapse (mean) b lb ub, by(hhi_new)
				twoway (rarea ub lb hhi_new, sort fcolor(gs10) lcolor(gs0)) (connected b hhi_new,lpattern(dash) lcolor(green) ms(i)), yline(0, lcolor(black)) ///
							title("Employment effect of robots vs HHI in routine intensive markets: IV for ER",size(medium)) ytitle("Effect on change in employment-to-population ratio ({it:in 10{sup:-3}})",size(small)) xtitle("HHI ({it:in 10{sup:4}})",size(small)) xline(0, lcolor(black)) ///
							legend(size(vsmall) order(2 1) r(2) label(1 "95% Confidence Interval") label(2 "TSLS estimates of robot effect on employment")) ///
							graphregion(fcolor(white) ifcolor(white) ilcolor(white)) plotregion(fcolor(white) ifcolor(white) ilcolor(white) margin(b+2))
				
				graph save "$results\graphs\result_noIVforHHIemp_col3_routine.png",replace
restore

preserve
		keep if rti1_rank>=296		
ivreghdfe d_emp_workpop06_ratio (er_us_emp06 interaction=er_eu ivinteraction) hhi_new $demographic, absorb(occsoc state) endog(er_us_emp06 interaction) cluster(state)
				g b= _b[er_us_emp06] + _b[interaction]*hhi_new
				matrix v=e(V)
				g var_b=v[1,1]+hhi_new^2*v[2,2]+hhi_new*v[2,1]*2
				g se_b=sqrt(var_b)
				g lb=b-invttail(e(df_r),0.025)*se_b
				g ub=b+invttail(e(df_r),0.025)*se_b
				collapse (mean) b lb ub, by(hhi_new)
				twoway (rarea ub lb hhi_new, sort fcolor(gs10) lcolor(gs0)) (connected b hhi_new,lpattern(dash) lcolor(green) ms(i)), yline(0, lcolor(black)) ///
							title("Employment effect of robots vs HHI in abstract intensive markets: IV for ER",size(medium)) ytitle("Effect on change in employment-to-population ratio ({it:in 10{sup:-3}})",size(small)) xtitle("HHI ({it:in 10{sup:4}})",size(small)) xline(0, lcolor(black)) ///
							legend(size(vsmall) order(2 1) r(2) label(1 "95% Confidence Interval") label(2 "TSLS estimates of robot effect on employment")) ///
							graphregion(fcolor(white) ifcolor(white) ilcolor(white)) plotregion(fcolor(white) ifcolor(white) ilcolor(white) margin(b+2))
				
				graph save "$results\graphs\result_noIVforHHIemp_col3_abstract.png",replace
restore



use regwage,clear
sum rti1_rank
***** results graph1 *****
*ivreghdfe d_emp_workpop06_ratio (er_us_emp06 interaction=er_eu ivinteraction) hhi_new $demographic, absorb(occsoc state) endog(er_us_emp06 interaction) cluster(state)
					
*ivreghdfe d_emp_workpop06_ratio (er_us_emp06 interaction hhi_new=er_eu cmanuf_ehat cmale_ehat ivinteraction5 ivinteraction6) $demographic, absorb(occsoc state) endog(er_us_emp06 hhi_new interaction) cluster(state)

preserve
		keep if rti1_rank<148		
ivreghdfe d_lnwage_0614 (er_us_emp06 interaction=er_eu ivinteraction) hhi_new $demographic, absorb(occsoc state) endog(er_us_emp06 interaction) cluster(state)
				g b= _b[er_us_emp06] + _b[interaction]*hhi_new
				matrix v=e(V)
				g var_b=v[1,1]+hhi_new^2*v[2,2]+hhi_new*v[2,1]*2
				g se_b=sqrt(var_b)
				g lb=b-invttail(e(df_r),0.025)*se_b
				g ub=b+invttail(e(df_r),0.025)*se_b
				collapse (mean) b lb ub, by(hhi_new)
				twoway (rarea ub lb hhi_new, sort fcolor(gs10) lcolor(gs0)) (connected b hhi_new,lpattern(dash) lcolor(green) ms(i)), yline(0, lcolor(black)) ///
							title("Wage effect of robots vs HHI in routine intensive markets: IV for ER",size(medium)) ytitle("Effect on change in log annual wage",size(small)) xtitle("HHI ({it:in 10{sup:4}})",size(small)) xline(0, lcolor(black)) ///
							legend(size(vsmall) order(2 1) r(2) label(1 "95% Confidence Interval") label(2 "TSLS estimates of robot effect on wage")) ///
							graphregion(fcolor(white) ifcolor(white) ilcolor(white)) plotregion(fcolor(white) ifcolor(white) ilcolor(white) margin(b+2))
				
				graph save "$results\graphs\result_noIVforHHIwage_col3_routine.png",replace
restore

preserve
		keep if rti1_rank>=296		
ivreghdfe d_lnwage_0614 (er_us_emp06 interaction=er_eu ivinteraction) hhi_new $demographic, absorb(occsoc state) endog(er_us_emp06 interaction) cluster(state)
				g b= _b[er_us_emp06] + _b[interaction]*hhi_new
				matrix v=e(V)
				g var_b=v[1,1]+hhi_new^2*v[2,2]+hhi_new*v[2,1]*2
				g se_b=sqrt(var_b)
				g lb=b-invttail(e(df_r),0.025)*se_b
				g ub=b+invttail(e(df_r),0.025)*se_b
				collapse (mean) b lb ub, by(hhi_new)
				twoway (rarea ub lb hhi_new, sort fcolor(gs10) lcolor(gs0)) (connected b hhi_new,lpattern(dash) lcolor(green) ms(i)), yline(0, lcolor(black)) ///
							title("Wage effect of robots vs HHI in abstract intensive markets: IV for ER",size(medium)) ytitle("Effect on change in log annual wage",size(small)) xtitle("HHI ({it:in 10{sup:4}})",size(small)) xline(0, lcolor(black)) ///
							legend(size(vsmall) order(2 1) r(2) label(1 "95% Confidence Interval") label(2 "TSLS estimates of robot effect on wage")) ///
							graphregion(fcolor(white) ifcolor(white) ilcolor(white)) plotregion(fcolor(white) ifcolor(white) ilcolor(white) margin(b+2))
				
				graph save "$results\graphs\result_noIVforHHIwage_col3_abstract.png",replace
restore