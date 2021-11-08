clear all
global ipums "E:\Dropbox\Research\Ding's Proposal\WorkingFile\empirical_v2"
global tempdata "E:\Dropbox\Research\Ding's Proposal\WorkingFile\empirical_v2\temp_data"
global cw_ipums "E:\Dropbox\Research\Ding's Proposal\WorkingFile\empirical_v2\cw_ipums"
global dofiles "E:\Dropbox\Research\Ding's Proposal\WorkingFile\empirical_v2\dofiles"
global datafiles "E:\Dropbox\Research\Ding's Proposal\WorkingFile\empirical_v2\datafiles"
global results "E:\Dropbox\Research\Ding's Proposal\WorkingFile\empirical_v2\results"
global demographic share_male share_nonwhite share_elder share_nocoll share_somecoll share_collprof share_mastdoc share_emp_manuf
cd "$datafiles"


*** firstly generate a crosswalk between states and census division
import excel "$cw_ipums\state-geocodes-v2014.xls",clear
keep if _n>=7
rename (A B C) (region division state)
drop D
drop if state=="00"
keep division state
destring state,replace
destring division,replace
save "$cw_ipums\cw_state_division",replace


use dep_emp0614,clear
g interaction=er_us_emp06*hhi_new
merge m:1 czone2000 using "$cw_ipums\cw_state_cz2000"
drop if _merge!=3
drop _merge
merge m:1 state using "$cw_ipums\cw_state_division"
drop if _merge!=3
drop _merge
g ivinteraction=er_eu*hhi_new

	****check the balance of panel****
	preserve
		bys czone: gen num_occ=_N
		bys czone: keep if _n==1
		sum num_occ
	/*
		Variable |        Obs        Mean    Std. Dev.       Min        Max
	-------------+---------------------------------------------------------
		num_occ |        708    208.6483    102.2659         11        444
	*/
	restore
	preserve
		keep czone2000
		bys czone2000: keep if _n==1
		*there are 708 czones in data
	restore
	preserve
		bys occsoc:keep if _n==1
		sort occsoc
		*there are 446 occsoc
		g occsoc_2=subinstr(occsoc, "X", "0",.)
		replace occsoc_2="514099" if occsoc=="5140XX"
		replace occsoc_2="475099" if occsoc=="4750YY"
	restore
g occsoc_2=subinstr(occsoc, "X", "0",.)
replace occsoc_2="514099" if occsoc=="5140XX"
replace occsoc_2="475099" if occsoc=="4750YY"
destring occsoc_2,replace
center $demographic, prefix(c_)

			preserve

			*** drop fully concentrated markets
			drop if hhi_new==10000
			*** lewbel IV spec1 for no full HHI
			reg hhi_new c_share* i.occsoc_2 er_eu
			bpagan c_share_male
			bpagan c_share_nonwhite
			bpagan c_share_elder
			bpagan c_share_nocoll
			bpagan c_share_somecoll
			bpagan c_share_collprof
			bpagan c_share_mastdoc
			bpagan c_share_emp_manuf
				*** rank: c_share_nonwhite c_share_collprof c_share_nocoll c_share_mastdoc c_share_elder c_share_emp_manuf 
			predict ehat, residuals
			g cnonwhite_ehat=c_share_nonwhite*ehat
			g ccollprof_ehat=c_share_collprof*ehat
			g cnocoll_ehat=c_share_nocoll*ehat
			g cmastdoc_ehat=c_share_mastdoc*ehat
			g celder_ehat=c_share_elder*ehat
			g cmanuf_ehat=c_share_emp_manuf*ehat

			g ivinteraction1=cnonwhite_ehat*er_eu
			g ivinteraction2=ccollprof_ehat*er_eu
			g ivinteraction3=cnocoll_ehat*er_eu
			g ivinteraction4=cmastdoc_ehat*er_eu
			g ivinteraction5=celder_ehat*er_eu
			g ivinteraction6=cmanuf_ehat*er_eu

			*** lewbel IV spec3 for no full HHI
			reg hhi_new c_share* i.occsoc_2 i.state er_eu
			bpagan c_share_male
			bpagan c_share_nonwhite
			bpagan c_share_elder
			bpagan c_share_nocoll
			bpagan c_share_somecoll
			bpagan c_share_collprof
			bpagan c_share_mastdoc
			bpagan c_share_emp_manuf
				*** rank: c_share_nonwhite c_share_collprof c_share_nocoll c_share_elder c_share_emp_manuf c_share_male
			predict ehat2, residuals
			g cnonwhite_ehat_2=c_share_nonwhite*ehat2
			g ccollprof_ehat_2=c_share_collprof*ehat2
			g cnocoll_ehat_2=c_share_nocoll*ehat2
			g celder_ehat_2=c_share_elder*ehat2
			g cmanuf_ehat_2=c_share_emp_manuf*ehat2
			g cmale_ehat_2=c_share_male*ehat2

			g ivinteraction1_2=cnonwhite_ehat_2*er_eu
			g ivinteraction2_2=ccollprof_ehat_2*er_eu
			g ivinteraction3_2=cnocoll_ehat_2*er_eu
			g ivinteraction4_2=celder_ehat_2*er_eu
			g ivinteraction5_2=cmanuf_ehat_2*er_eu
			g ivinteraction6_2=cmale_ehat_2*er_eu

			*** scale down the hhi by 10000
			replace hhi_new=hhi_new/10000
			replace interaction=interaction/10000
			replace ivinteraction=ivinteraction/10000
			save regemp_nofullhhi,replace

			restore


*** lewbel IV spec1 
reg hhi_new c_share* i.occsoc_2 er_eu
bpagan c_share_male
bpagan c_share_nonwhite
bpagan c_share_elder
bpagan c_share_nocoll
bpagan c_share_somecoll
bpagan c_share_collprof
bpagan c_share_mastdoc
bpagan c_share_emp_manuf
	*** rank: c_share_nonwhite c_share_collprof c_share_nocoll c_share_elder c_share_emp_manuf c_share_mastdoc  
predict ehat, residuals
g cnonwhite_ehat=c_share_nonwhite*ehat
g ccollprof_ehat=c_share_collprof*ehat
g cnocoll_ehat=c_share_nocoll*ehat
g celder_ehat=c_share_elder*ehat
g cmanuf_ehat=c_share_emp_manuf*ehat
g cmastdoc_ehat=c_share_mastdoc*ehat

g ivinteraction1=cnonwhite_ehat*er_eu
g ivinteraction2=ccollprof_ehat*er_eu
g ivinteraction3=cnocoll_ehat*er_eu
g ivinteraction4=celder_ehat*er_eu
g ivinteraction5=cmanuf_ehat*er_eu
g ivinteraction6=cmastdoc_ehat*er_eu

*** lewbel IV spec3
reg hhi_new c_share* i.occsoc_2 i.state er_eu
bpagan c_share_male
bpagan c_share_nonwhite
bpagan c_share_elder
bpagan c_share_nocoll
bpagan c_share_somecoll
bpagan c_share_collprof
bpagan c_share_mastdoc
bpagan c_share_emp_manuf
bpagan er_eu
	*** rank: c_share_nonwhite c_share_collprof c_share_emp_manuf c_share_elder c_share_nocoll c_share_male
predict ehat2, residuals
g cnonwhite_ehat_2=c_share_nonwhite*ehat2
g ccollprof_ehat_2=c_share_collprof*ehat2
g cmanuf_ehat_2=c_share_emp_manuf*ehat2
g celder_ehat_2=c_share_elder*ehat2
g cnocoll_ehat_2=c_share_nocoll*ehat2
g cmale_ehat_2=c_share_male*ehat2

g ivinteraction1_2=cnonwhite_ehat_2*er_eu
g ivinteraction2_2=ccollprof_ehat_2*er_eu
g ivinteraction3_2=cmanuf_ehat_2*er_eu
g ivinteraction4_2=celder_ehat_2*er_eu
g ivinteraction5_2=cnocoll_ehat_2*er_eu
g ivinteraction6_2=cmale_ehat_2*er_eu

*** level down the hhi by 10000
replace hhi_new=hhi_new/10000
replace interaction=interaction/10000
replace ivinteraction=ivinteraction/10000

save regemp,replace




*** summarize the hhi_new ***
	sum hhi_new,detail
/*                          hhi_new
-------------------------------------------------------------
      Percentiles      Smallest
 1%     115.6217       3.550837
 5%     384.4619       7.167669
10%     725.1837       7.853821       Obs             147,723
25%     2117.553       8.710524       Sum of Wgt.     147,723

50%         5000                      Mean           5233.302
                        Largest       Std. Dev.      3367.923
75%     8333.333          10000
90%        10000          10000       Variance       1.13e+07
95%        10000          10000       Skewness       .0841943
99%        10000          10000       Kurtosis       1.648803
*/
/*
*** market employment over cz population as LHS ***
	replace d_emp_ratio_0614=d_emp_ratio_0614*100
	reg d_emp_ratio_0614 er_us_emp06, cluster(state)
	reg d_emp_ratio_0614 er_us_emp06 $demographic, cluster(state)
	ivreg d_emp_ratio_0614 (er_us_emp06=er_eu) $demographic, cluster(state)
	ivreghdfe d_emp_ratio_0614 (er_us_emp06=er_eu) $demographic, absorb(occsoc) cluster(state)
	ivreghdfe d_emp_ratio_0614 (er_us_emp06=er_eu) share_*, absorb(occsoc czone2000) cluster(state)
	reghdfe d_emp_ratio_0614 er_us_emp06 interaction hhi_new $demographic, absorb(occsoc) cluster(state) 
	reghdfe d_emp_ratio_0614 er_us_emp06 interaction hhi_new share_*, absorb(occsoc czone2000) cluster(state)
	ivreghdfe d_emp_ratio_0614 (er_us_emp06 interaction=er_eu ///
		ivinteraction) hhi_new $demographic, first absorb(occsoc) cluster(state)
	ivreghdfe d_emp_ratio_0614 (er_us_emp06 interaction hhi_new=er_eu cmanuf_ehat cnocoll_ehat ///
		ivinteraction4 ivinteraction5) share_*, absorb(occsoc) cluster(state)
	ivreghdfe d_emp_ratio_0614 (er_us_emp06 interaction hhi_new=er_eu cmanuf_ehat cnocoll_ehat ///
		ivinteraction4 ivinteraction5) $demographic, absorb(occsoc) cluster(state)
*** section ends ***

*** %change of employment as LHS ***
	g d_pct_emp=(emp_lm14-emp_lm06)/emp_lm06
	reg d_pct_emp er_us_emp06, cluster(state)
	reg d_pct_emp er_us_emp06 $demographic, cluster(state)
	ivreg d_pct_emp (er_us_emp06=er_eu) $demographic, cluster(state)
	ivreghdfe d_pct_emp (er_us_emp06=er_eu) $demographic, absorb(occsoc) cluster(state)
	ivreghdfe d_pct_emp (er_us_emp06=er_eu) share_*, absorb(occsoc czone2000) cluster(state)
	reghdfe d_pct_emp er_us_emp06 interaction hhi_new $demographic, absorb(occsoc) cluster(state) 
	reghdfe d_pct_emp er_us_emp06 interaction hhi_new share_*, absorb(occsoc czone2000) cluster(state)
	ivreghdfe d_pct_emp (er_us_emp06 interaction=er_eu ///
		ivinteraction) hhi_new $demographic, first absorb(occsoc) cluster(state)
	ivreghdfe d_pct_emp (er_us_emp06 interaction hhi_new=er_eu cmanuf_ehat cnocoll_ehat ///
		ivinteraction4 ivinteraction5) share_*, absorb(occsoc) cluster(state)
	ivreghdfe d_pct_emp (er_us_emp06 interaction hhi_new=er_eu cmanuf_ehat cnocoll_ehat ///
		ivinteraction4 ivinteraction5) $demographic, absorb(occsoc) cluster(state)
*** section ends ***
*/
*** change in employment to 2006 working age pop ratio as LHS ***
use regemp,clear
	reghdfe d_emp_workpop06_ratio er_us_emp06, absorb(division) cluster(state)
	reghdfe d_emp_workpop06_ratio er_us_emp06, absorb(occsoc division) cluster(state)
	reghdfe d_emp_workpop06_ratio er_us_emp06 $demographic, absorb(division) cluster(state)
	ivreg d_emp_workpop06_ratio (er_us_emp06=er_eu), cluster(state)
	ivreghdfe d_emp_workpop06_ratio (er_us_emp06=er_eu), absorb(division) cluster(state)
	ivreghdfe d_emp_workpop06_ratio (er_us_emp06=er_eu) $demographic, absorb(occsoc division) cluster(state)
	ivreghdfe d_emp_workpop06_ratio (er_us_emp06=er_eu) cz_workpop $demographic, absorb(occsoc division) cluster(state)
	
	ivreghdfe d_emp_workpop06_ratio (er_us_emp06=er_eu) cz_workpop $demographic if rti1_rank>200, absorb(occsoc) cluster(state)  /*experimental regression*/
	
	ivreghdfe d_emp_workpop06_ratio (er_us_emp06=er_eu) share_*, absorb(occsoc czone2000) cluster(state)
	reghdfe d_emp_workpop06_ratio er_us_emp06 interaction hhi_new cz_workpop $demographic, absorb(occsoc division) cluster(state) 
	reghdfe d_emp_workpop06_ratio er_us_emp06 interaction hhi_new share_*, absorb(occsoc czone2000) cluster(state)
	ivreghdfe d_emp_workpop06_ratio (er_us_emp06 interaction=er_eu ///
		ivinteraction) hhi_new cz_workpop $demographic, first absorb(occsoc division) cluster(state)  /*good*/
	ivreghdfe d_emp_workpop06_ratio (er_us_emp06 interaction hhi_new=er_eu cworkpop_ehat cnonwhite_ehat cmanuf_ehat ///
		ivinteraction1 ivinteraction2 ivinteraction5) cz_workpop share_*, absorb(occsoc) cluster(state)  /*not bad*/
	ivreghdfe d_emp_workpop06_ratio (er_us_emp06 interaction hhi_new=er_eu cworkpop_ehat cmastdoc_ehat cmanuf_ehat ///
		ivinteraction1 ivinteraction4 ivinteraction5) cz_workpop share_*, absorb(occsoc) cluster(state)  /*not bad*/
	ivreghdfe d_emp_workpop06_ratio (er_us_emp06 interaction hhi_new=er_eu cworkpop_ehat cmanuf_ehat cmale_ehat ///
		ivinteraction1 ivinteraction5 ivinteraction6) cz_workpop share_*, absorb(occsoc) cluster(state)  /*not bad*/
	ivreghdfe d_emp_workpop06_ratio (er_us_emp06 interaction hhi_new=er_eu cmanuf_ehat cmale_ehat ///
		ivinteraction5 ivinteraction6) cz_workpop share_*, absorb(occsoc) cluster(state)  /*good*/
	ivreghdfe d_emp_workpop06_ratio (er_us_emp06 interaction hhi_new=er_eu cmastdoc_ehat cmanuf_ehat cmale_ehat ///
		ivinteraction4 ivinteraction5 ivinteraction6) cz_workpop share_*, absorb(occsoc) cluster(state)  /*good*/
	ivreghdfe d_emp_workpop06_ratio (er_us_emp06 interaction hhi_new=er_eu cnonwhite_ehat cmanuf_ehat cmale_ehat ///
		ivinteraction2 ivinteraction5 ivinteraction6) cz_workpop share_*, absorb(occsoc) cluster(state)  /*not bad*/
	
	
	
	************************************************************************************************
	*************************************** rti1 interacted ****************************************
	************************************************************************************************
		g tripleinteraction=er_us_emp06*hhi_new*rti1
		g ivtripleinteraction=er_eu*hhi_new*rti1
		g ivtripleinteraction1=cworkpop_ehat*er_eu*rti1
		g ivtripleinteraction2=cnonwhite_ehat*er_eu*rti1
		g ivtripleinteraction3=celder_ehat*er_eu*rti1
		g ivtripleinteraction4=cmastdoc_ehat*er_eu*rti1
		g ivtripleinteraction5=cmanuf_ehat*er_eu*rti1
		g ivtripleinteraction6=cmale_ehat*er_eu*rti1
		
		ivreghdfe d_emp_workpop06_ratio (er_us_emp06 interaction tripleinteraction=er_eu ///
		ivinteraction ivtripleinteraction) hhi_new $demographic, absorb(occsoc state) endog(er_us_emp06 interaction tripleinteraction) cluster(state)
					
		ivreghdfe d_emp_workpop06_ratio (er_us_emp06 interaction hhi_new tripleinteraction=er_eu cmastdoc_ehat cmanuf_ehat cmale_ehat ///
		ivinteraction4 ivinteraction5 ivinteraction6 ivtripleinteraction4 ivtripleinteraction5 ivtripleinteraction6) $demographic, absorb(occsoc state) endog(er_us_emp06 interaction hhi_new tripleinteraction) cluster(state)
		
		
		
		***************graph of "good"****************
			*** no iv for hhi
				*** no state-effect, not weighted regression
				ivreghdfe d_emp_workpop06_ratio (er_us_emp06 interaction=er_eu ///
					ivinteraction) hhi_new cz_workpop $demographic, absorb(occsoc) cluster(state)  /*not bad*/
				*** no state-effect, weighted regression
				ivreghdfe d_emp_workpop06_ratio (er_us_emp06 interaction=er_eu ///
					ivinteraction) hhi_new cz_workpop $demographic [weight=emp_lm06], absorb(occsoc) cluster(state)  /*good*/
				*** with state-effect, not weighted regression
				ivreghdfe d_emp_workpop06_ratio (er_us_emp06 interaction=er_eu ///
					ivinteraction) hhi_new $demographic, absorb(occsoc state) cluster(state)  /*good*/
				*** with state-effect, weighted regression
				ivreghdfe d_emp_workpop06_ratio (er_us_emp06 interaction=er_eu ///
					ivinteraction) hhi_new $demographic [weight=emp_lm06], absorb(occsoc state) cluster(state)  /*bad*/
			*** lewbel iv set1 for hhi
				*** no state-effect, not weighted regression
				ivreghdfe d_emp_workpop06_ratio (er_us_emp06 interaction hhi_new=er_eu cmanuf_ehat cmale_ehat ///
					ivinteraction5 ivinteraction6) cz_workpop $demographic, absorb(occsoc) cluster(state)  /*good*/
				*** no state-effect, weighted regression
				ivreghdfe d_emp_workpop06_ratio (er_us_emp06 interaction hhi_new=er_eu cmanuf_ehat cmale_ehat ///
					ivinteraction5 ivinteraction6) cz_workpop $demographic [weight=emp_lm06], absorb(occsoc) cluster(state)  /*good*/
				*** with state-effect, not weighted regression
				ivreghdfe d_emp_workpop06_ratio (er_us_emp06 interaction hhi_new=er_eu cmanuf_ehat cmale_ehat ///
					ivinteraction5 ivinteraction6) $demographic, absorb(occsoc state) cluster(state)  /*good*/
				*** with state-effect, weighted regression
				ivreghdfe d_emp_workpop06_ratio (er_us_emp06 interaction hhi_new=er_eu cmanuf_ehat cmale_ehat ///
					ivinteraction5 ivinteraction6) $demographic [weight=emp_lm06], absorb(occsoc division) cluster(state)  /*not bad*/
			*** lewbel iv set2 for hhi
				*** no state-effect, not weighted regression
				ivreghdfe d_emp_workpop06_ratio (er_us_emp06 interaction hhi_new=er_eu cmastdoc_ehat cmanuf_ehat cmale_ehat ///
					ivinteraction4 ivinteraction5 ivinteraction6) $demographic, absorb(occsoc) cluster(state)  /*good*/
				*** no state-effect, weighted regression
				ivreghdfe d_emp_workpop06_ratio (er_us_emp06 interaction hhi_new=er_eu cmastdoc_ehat cmanuf_ehat cmale_ehat ///
					ivinteraction4 ivinteraction5 ivinteraction6) $demographic [weight=emp_lm06], absorb(occsoc) cluster(state)  /*not bad*/
				*** with state-effect, not weighted regression
				ivreghdfe d_emp_workpop06_ratio (er_us_emp06 interaction hhi_new=er_eu cmastdoc_ehat cmanuf_ehat cmale_ehat ///
					ivinteraction4 ivinteraction5 ivinteraction6) $demographic, absorb(occsoc state) cluster(state)  /*good*/
				*** with state-effect, weighted regression
				ivreghdfe d_emp_workpop06_ratio (er_us_emp06 interaction hhi_new=er_eu cmastdoc_ehat cmanuf_ehat cmale_ehat ///
					ivinteraction4 ivinteraction5 ivinteraction6) $demographic [weight=emp_lm06], absorb(occsoc state) cluster(state)  /*bad*/
		preserve
		g b= _b[er_us_emp06] + _b[interaction]*hhi_new
		matrix v=e(V)
		g var_b=v[1,1]+hhi_new^2*v[2,2]+hhi_new*v[2,1]*2
		g se_b=sqrt(var_b)
		g lb=b-invttail(e(df_r),0.025)*se_b
		g ub=b+invttail(e(df_r),0.025)*se_b
		collapse (mean) b lb ub, by(hhi_new)
		twoway (rarea ub lb hhi_new, sort fcolor(gs10) lcolor(gs0)) (connected b hhi_new,lpattern(dash) lcolor(green) ms(i)), yline(0, lcolor(black)) ///
					title("Impact of Robots vs HHI in US") subtitle("Impact of Robots on Change in emp-to-workpop vs Average HHI in 2006-2014") ytitle("Change in emp-to-workpop ratio") xtitle("HHI") xline(0, lcolor(black)) ///
					legend(size(vsmall) order(2 1) r(2) label(1 "95% Confidence Interval") label(2 "Impact of Robot on emp-to-workpop Change")) ///
					graphregion(fcolor(white) ifcolor(white) ilcolor(white)) plotregion(fcolor(white) ifcolor(white) ilcolor(white) margin(b+2)) ///
					note("Figure # - Impact of exposure to robots on empt-to-workpop of labor markets with different levels of HHI." "This figure presents the result from column # of table #. Errors are clustered in state level")
		restore
		*graph ends
*** section ends ***


reg d_emp_0614 er_us_emp06, cluster(state)
reg d_emp_0614 er_us_emp06 $demographic, cluster(state)
ivreg d_emp_0614 (er_us_emp06=er_eu) cz_workpop $demographic, cluster(state)
ivreghdfe d_emp_0614 (er_us_emp06=er_eu) cz_workpop $demographic, absorb(occsoc) cluster(state)
   ****good****
reghdfe d_emp_0614 er_us_emp06 interaction hhi_new $demographic, absorb(occsoc) cluster(state)
   ****good**** 
reghdfe d_emp_0614 er_us_emp06 interaction hhi_new share_*, absorb(occsoc czone2000) cluster(state)
   ****good**** 

   
***************************************************************************
*********** the following section is for drawing the graphs ***************
***************************************************************************

reghdfe d_emp_0614 er_us_emp06 interaction hhi_new share_*, absorb(occsoc czone2000) cluster(state)
   ****good****   
	****graph*****
	preserve
	g b= _b[er_us_emp06] + _b[interaction]*hhi_new
    matrix v=e(V)
    g var_b=v[1,1]+hhi_new^2*v[2,2]+hhi_new*v[2,1]*2
    g se_b=sqrt(var_b)
    g lb=b-invttail(e(df_r),0.025)*se_b
    g ub=b+invttail(e(df_r),0.025)*se_b
	collapse (mean) b lb ub, by(hhi_new)

	twoway (rarea ub lb hhi_new, sort fcolor(gs10) lcolor(gs0)) (connected b hhi_new,lpattern(dash) lcolor(green) ms(i)), yline(0, lcolor(black)) ///
					title("Impact of Robots vs HHI in US") subtitle("Impact of Robots on Change in Employment vs Average HHI in 2006-2014") ytitle("Change in Employment") xtitle("HHI") xline(0, lcolor(black)) ///
					legend(size(vsmall) order(2 1) r(2) label(1 "95% Confidence Interval") label(2 "Impact of Robot on Employment Change")) ///
					graphregion(fcolor(white) ifcolor(white) ilcolor(white)) plotregion(fcolor(white) ifcolor(white) ilcolor(white) margin(b+2)) ///
					note("Figure # - Impact of exposure to robots on employment of labor markets with different levels of HHI." "This figure presents the result from column # of table #. Errors are clustered in state level")
			graph export "E:\Dropbox\Research\Ding's Proposal\WorkingFile\IPUMS\results\Graphs\d_emp_noiv.png", as(png) replace		
	restore

/*	
*** an attempt running without using generated interaction terms
ivreghdfe d_emp_0614 (er_us_emp06 c.er_us_emp06#c.hhi_new=er_eu ///
	c.er_eu#c.hhi_new) hhi_new $demographic, first absorb(occsoc) cluster(state)   leg(size(vsmall) order(1 3 5 7 9) r(5) rowg(*.1))
*** section ends
*/

***** only one of the following two regression should be selected since they are almost identical on setting but too far away on results.

ivreghdfe d_emp_0614 (er_us_emp06 interaction=er_eu ///
   ivinteraction) hhi_new cz_workpop $demographic, absorb(occsoc) cluster(state)
   ****good****
   ****graph*****
	preserve
	g b= _b[er_us_emp06] + _b[interaction]*hhi_new
    matrix v=e(V)
    g var_b=v[1,1]+hhi_new^2*v[2,2]+hhi_new*v[2,1]*2
    g se_b=sqrt(var_b)
    g lb=b-invttail(e(df_r),0.025)*se_b
    g ub=b+invttail(e(df_r),0.025)*se_b
	collapse (mean) b lb ub, by(hhi_new)

	twoway (rarea ub lb hhi_new, sort fcolor(gs10) lcolor(gs0)) (connected b hhi_new,lpattern(dash) lcolor(green) ms(i)), yline(0, lcolor(black)) ///
					title("Impact of Robots vs HHI in US") subtitle("Impact of Robots on Change in Employment vs Average HHI in 2006-2014") ytitle("Change in Employment") xtitle("HHI") xline(0, lcolor(black)) ///
					legend(size(vsmall) order(2 1) r(2) label(1 "95% Confidence Interval") label(2 "Impact of Robot on Employment Change")) ///
					graphregion(fcolor(white) ifcolor(white) ilcolor(white)) plotregion(fcolor(white) ifcolor(white) ilcolor(white) margin(b+2)) ///
					note("Figure # - Impact of exposure to robots on employment of labor markets with different levels of HHI." "This figure presents the result from column # of table #. US exposure to robot is instrumented" "by europe-5-country-based exposure to robot. Errors are clustered in state level")
			graph export "E:\Dropbox\Research\Ding's Proposal\WorkingFile\IPUMS\results\Graphs\d_emp_iv.png", as(png) replace		
	restore


   ****once I put czone fixed effect in regression, ln_cz_pop is unnecessary
ivreghdfe d_emp_0614 (er_us_emp06 interaction=er_eu ///
   ivinteraction) hhi_new share_*, absorb(occsoc czone2000) cluster(state)
   ****good****
	****graph****
	preserve
	g b= _b[er_us_emp06] + _b[interaction]*hhi_new
    matrix v=e(V)
    g var_b=v[1,1]+hhi_new^2*v[2,2]+hhi_new*v[2,1]*2
    g se_b=sqrt(var_b)
    g lb=b-invttail(e(df_r),0.025)*se_b
    g ub=b+invttail(e(df_r),0.025)*se_b
	collapse (mean) b lb ub, by(hhi_new)

	twoway (rarea ub lb hhi_new, sort fcolor(gs10) lcolor(gs0)) (connected b hhi_new,lpattern(dash) lcolor(green) ms(i)), yline(0, lcolor(black)) ///
					title("Impact of Robots vs HHI in US") subtitle("Impact of Robots on Change in Employment vs Average HHI in 2006-2014") ytitle("Change in Employment") xtitle("HHI") xline(0, lcolor(black)) ///
					legend(size(vsmall) order(2 1) r(2) label(1 "95% Confidence Interval") label(2 "Impact of Robot on Employment Change")) ///
					graphregion(fcolor(white) ifcolor(white) ilcolor(white)) plotregion(fcolor(white) ifcolor(white) ilcolor(white) margin(b+2)) ///
					note("Figure # - Impact of exposure to robots on employment of labor markets with different levels of HHI." "This figure presents the result from column # of table #. US exposure to robot is instrumented" "by europe-5-country-based exposure to robot. Errors are clustered in state level")
			*graph export "E:\Dropbox\Research\Ding's Proposal\WorkingFile\IPUMS\results\Graphs\d_emp_iv_czfe.png", as(png) replace		
	restore

ivreghdfe d_emp_0614 (er_us_emp06 interaction hhi_new=er_eu cnonwhite_ehat cmanuf_ehat ///
   ivinteraction2 ivinteraction5) cz_workpop $demographic, absorb(occsoc) cluster(state)
   ****good****
   ****graph****
	preserve
	g b= _b[er_us_emp06] + _b[interaction]*hhi_new
    matrix v=e(V)
    g var_b=v[1,1]+hhi_new^2*v[2,2]+hhi_new*v[2,1]*2
    g se_b=sqrt(var_b)
    g lb=b-invttail(e(df_r),0.025)*se_b
    g ub=b+invttail(e(df_r),0.025)*se_b
	collapse (mean) b lb ub, by(hhi_new)

	twoway (rarea ub lb hhi_new, sort fcolor(gs10) lcolor(gs0)) (connected b hhi_new,lpattern(dash) lcolor(green) ms(i)), yline(0, lcolor(black)) ///
					title("Impact of Robots vs HHI in US") subtitle("Impact of Robots on Change in Employment vs Average HHI in 2006-2014") ytitle("Change in Employment") xtitle("HHI") xline(0, lcolor(black)) ///
					legend(size(vsmall) order(2 1) r(2) label(1 "95% Confidence Interval") label(2 "Impact of Robot on Employment Change")) ///
					graphregion(fcolor(white) ifcolor(white) ilcolor(white)) plotregion(fcolor(white) ifcolor(white) ilcolor(white) margin(b+2)) ///
					note("Figure # - Impact of exposure to robots on employment of labor markets with different levels of HHI." "This figure presents the result from column # of table #. US exposure to robot is instrumented" "by europe-5-country-based exposure to robot. HHI is instrumented by heteroscedasticity-based" "IV. Errors are clustered in state level")
			graph export "E:\Dropbox\Research\Ding's Proposal\WorkingFile\IPUMS\results\Graphs\d_emp_hetiv.png", as(png) replace		
	restore

*********************graph section ends *********************

***********the following section is for comparing resutls from top-routined market sample with whole sample*******
log using "$results\compare_whole.log",replace
ivreghdfe d_emp_0614 (er_us_emp06=er_eu) share_*, absorb(czone2000) cluster(state)

ivreghdfe d_emp_0614 (er_us_emp06 interaction=er_eu ///
   ivinteraction) hhi_new share_*, absorb(czone2000) cluster(state)

ivreghdfe d_emp_0614 (er_us_emp06 interaction hhi_new=er_eu cmanuf_ehat cnocoll_ehat ///
   ivinteraction4 ivinteraction5) share_*, absorb(czone2000) cluster(state)
log close
**********section end**********


**********make a result table*********
ivreghdfe d_emp_0614 (er_us_emp06 interaction=er_eu ///
   ivinteraction) hhi_new share_*, absorb(occsoc czone2000) cluster(state) savefirst
estimates table _ivreg2_er_us_emp06,se
matrix b1=r(coef)
estadd scalar first_stage_coef=b[1,1]
estimates store e1


estout e1 using "$results\table\table.tex", style(tex) ///
varlabels(er_us_emp06 "US exposure to robots") ///
		  cells(b(nostar fmt(%9.3f)) se(par)) stats(N first_stage_coef widstat, fmt(%7.0f %7.2f %7.2f %7.1f %7.3f) ///
		  labels("Observations" "First-stage coefficient" "First-stage F-statistic" )) nolabel replace mlabels(none) ///
		  collabels(none) starlevels(\$^{*}\$ .1 \$^{**}\$ .05 \$^{***}\$ .01) ///
keep(er_us_emp06) ///
order(er_us_emp06)
*************************************

   
log using "$results\result_emp0614_euIV.log",replace
ivreghdfe d_emp_0614 (er_us_emp06=er_eu) $demographic, absorb(occsoc) cluster(state)
ivreghdfe d_emp_0614 (er_us_emp06 interaction=er_eu ///
   ivinteraction) hhi_new $demographic, absorb(occsoc) cluster(state)
 
ivreghdfe d_emp_0614 (er_us_emp06 interaction=er_eu ///
   ivinteraction) hhi_new share_*, absorb(occsoc czone2000) cluster(state)

ivreghdfe d_emp_0614 (er_us_emp06 interaction hhi_new=er_eu cmanuf_ehat cnocoll_ehat ///
   ivinteraction4 ivinteraction5) $demographic, absorb(occsoc) cluster(state)
log close

log using "$results\result_emptopop_euIV.log",replace
ivreghdfe d_emp_ratio_0614 (er_us_emp06=er_eu) $demographic, absorb(occsoc) cluster(state)
ivreghdfe d_emp_ratio_0614 (er_us_emp06 interaction=er_eu ///
   ivinteraction) hhi_new $demographic, absorb(occsoc) cluster(state)
 
ivreghdfe d_emp_ratio_0614 (er_us_emp06 interaction=er_eu ///
   ivinteraction) hhi_new share_*, absorb(occsoc czone2000) cluster(state)

ivreghdfe d_emp_ratio_0614 (er_us_emp06 interaction hhi_new=er_eu cmanuf_ehat cnocoll_ehat ///
   ivinteraction4 ivinteraction5) $demographic, absorb(occsoc) cluster(state)
ivreghdfe d_emp_ratio_0614 (er_us_emp06 interaction hhi_new=er_eu cmanuf_ehat cnocoll_ehat ///
   ivinteraction4 ivinteraction5) share_*, absorb(occsoc czone2000) cluster(state)
log close





***** wage *****
use dep_wage0614,clear
merge 1:1 occsoc czone2000 using lm_demographic
drop if _merge!=3
drop _merge
merge 1:1 occsoc czone2000 using hhi_2016new

sum lm_pop if _merge==3
/*
    Variable |        Obs        Mean    Std. Dev.       Min        Max
-------------+---------------------------------------------------------
      lm_pop |    115,024    1458.039    5131.113   .0175204   293815.2
*/
drop if _merge!=3
drop _merge
merge 1:1 occsoc czone2000 using er_us_emp06
drop if _merge!=3
drop _merge
merge 1:1 occsoc czone2000 using er_eu
drop if _merge!=3
drop _merge
g interaction=er_us_emp06*hhi_new
global demographic share_*
merge m:1 czone2000 using "$cw_ipums\cw_state_cz2000"
drop if _merge!=3
drop _merge
merge m:1 state using "$cw_ipums\cw_state_division"
drop if _merge!=3
drop _merge
g ivinteraction=er_eu*hhi_new

g occsoc_2=subinstr(occsoc, "X", "0",.)
replace occsoc_2="514099" if occsoc=="5140XX"
replace occsoc_2="475099" if occsoc=="4750YY"
destring occsoc_2,replace
center $demographic, prefix(c_)

			preserve
			*** drop fully concentrated markets
			drop if hhi_new==10000
			************************* lewbel IV spec1 for no full HHI *********************
			reg hhi_new c_share* i.occsoc_2 er_eu
			bpagan c_share_male
			bpagan c_share_nonwhite
			bpagan c_share_elder
			bpagan c_share_nocoll
			bpagan c_share_somecoll
			bpagan c_share_collprof
			bpagan c_share_mastdoc
			bpagan c_share_emp_manuf
				*** rank: c_share_nonwhite c_share_collprof c_share_nocoll c_share_elder c_share_emp_manuf c_share_mastdoc
			predict ehat, residuals
			g cnonwhite_ehat=c_share_nonwhite*ehat
			g ccollprof_ehat=c_share_collprof*ehat
			g cnocoll_ehat=c_share_nocoll*ehat
			g celder_ehat=c_share_elder*ehat
			g cmanuf_ehat=c_share_emp_manuf*ehat
			g cmastdoc_ehat=c_share_mastdoc*ehat

			g ivinteraction1=cnonwhite_ehat*er_eu
			g ivinteraction2=ccollprof_ehat*er_eu
			g ivinteraction3=cnocoll_ehat*er_eu
			g ivinteraction4=celder_ehat*er_eu
			g ivinteraction5=cmanuf_ehat*er_eu
			g ivinteraction6=cmastdoc_ehat*er_eu

			***************** lewbel IV spec3 for no full HHI ******************
			reg hhi_new c_share* i.occsoc_2 i.state er_eu
			bpagan c_share_male
			bpagan c_share_nonwhite
			bpagan c_share_elder
			bpagan c_share_nocoll
			bpagan c_share_somecoll
			bpagan c_share_collprof
			bpagan c_share_mastdoc
			bpagan c_share_emp_manuf
				*** rank: c_share_nonwhite c_share_elder c_share_emp_manuf c_share_male c_share_collprof c_share_nocoll
			predict ehat2, residuals
			g cnonwhite_ehat_2=c_share_nonwhite*ehat2
			g celder_ehat_2=c_share_elder*ehat2
			g cmanuf_ehat_2=c_share_emp_manuf*ehat2
			g cmale_ehat_2=c_share_male*ehat2
			g ccollprof_ehat_2=c_share_collprof*ehat2
			g cnocoll_ehat_2=c_share_nocoll*ehat2

			g ivinteraction1_2=cnonwhite_ehat_2*er_eu
			g ivinteraction2_2=celder_ehat_2*er_eu
			g ivinteraction3_2=cmanuf_ehat_2*er_eu
			g ivinteraction4_2=cmale_ehat_2*er_eu
			g ivinteraction5_2=ccollprof_ehat_2*er_eu
			g ivinteraction6_2=cnocoll_ehat_2*er_eu

			*** scale down the hhi by 10000
			replace hhi_new=hhi_new/10000
			replace interaction=interaction/10000
			replace ivinteraction=ivinteraction/10000
			save regwage_nofullhhi,replace

			restore


************************** lewbel IV spec1 **********************************
reg hhi_new c_share* i.occsoc_2 er_eu
bpagan c_share_male
bpagan c_share_nonwhite
bpagan c_share_elder
bpagan c_share_nocoll
bpagan c_share_somecoll
bpagan c_share_collprof
bpagan c_share_mastdoc
bpagan c_share_emp_manuf
	*** rank: c_share_nonwhite c_share_collprof c_share_elder c_share_emp_manuf c_share_male c_share_mastdoc
predict ehat, residuals
g cnonwhite_ehat=c_share_nonwhite*ehat
g ccollprof_ehat=c_share_collprof*ehat
g celder_ehat=c_share_elder*ehat
g cmanuf_ehat=c_share_emp_manuf*ehat
g cmale_ehat=c_share_male*ehat
g cmastdoc_ehat=c_share_mastdoc*ehat

g ivinteraction1=cnonwhite_ehat*er_eu
g ivinteraction2=ccollprof_ehat*er_eu
g ivinteraction3=celder_ehat*er_eu
g ivinteraction4=cmanuf_ehat*er_eu
g ivinteraction5=cmale_ehat*er_eu
g ivinteraction6=cmastdoc_ehat*er_eu

**************************** lewbel IV spec3 **************************************
reg hhi_new c_share* i.occsoc_2 i.state er_eu
bpagan c_share_male
bpagan c_share_nonwhite
bpagan c_share_elder
bpagan c_share_nocoll
bpagan c_share_somecoll
bpagan c_share_collprof
bpagan c_share_mastdoc
bpagan c_share_emp_manuf
	*** rank: c_share_nonwhite c_share_mastdoc c_share_male c_share_emp_manuf c_share_elder
predict ehat2, residuals
g cnonwhite_ehat_2=c_share_nonwhite*ehat2
g cmastdoc_ehat_2=c_share_mastdoc*ehat2
g cmale_ehat_2=c_share_male*ehat2
g cmanuf_ehat_2=c_share_emp_manuf*ehat2
g celder_ehat_2=c_share_elder*ehat2

g ivinteraction1_2=cnonwhite_ehat_2*er_eu
g ivinteraction2_2=cmastdoc_ehat_2*er_eu
g ivinteraction3_2=cmale_ehat_2*er_eu
g ivinteraction4_2=cmanuf_ehat_2*er_eu
g ivinteraction5_2=celder_ehat_2*er_eu


*** scale down the hhi by 10000
replace hhi_new=hhi_new/10000
replace interaction=interaction/10000
replace ivinteraction=ivinteraction/10000

save regwage,replace







use regwage,clear

ivreghdfe d_lnwage_0614 er_us_emp06, absorb(division) cluster(state)
ivreghdfe d_lnwage_0614 (er_us_emp06=er_eu) $demographic, absorb(division) cluster(state)

reghdfe d_lnwage_0614 er_us_emp06 interaction hhi_new $demographic, absorb(occsoc) cluster(state)
      

ivreghdfe d_lnwage_0614 (er_us_emp06 interaction=er_eu ///
   ivinteraction) hhi_new $demographic, absorb(occsoc state) cluster(state)
   *** very good ***
	preserve
		g b= _b[er_us_emp06] + _b[interaction]*hhi_new
		matrix v=e(V)
		g var_b=v[1,1]+hhi_new^2*v[2,2]+hhi_new*v[2,1]*2
		g se_b=sqrt(var_b)
		g lb=b-invttail(e(df_r),0.025)*se_b
		g ub=b+invttail(e(df_r),0.025)*se_b
		collapse (mean) b lb ub, by(hhi_new)
		twoway (rarea ub lb hhi_new, sort fcolor(gs10) lcolor(gs0)) (connected b hhi_new,lpattern(dash) lcolor(green) ms(i)), yline(0, lcolor(black)) ///
					title("Impact of Robots vs HHI in US") subtitle("Impact of Robots on Change in wage vs Average HHI in 2006-2014") ytitle("Change in emp-to-workpop ratio") xtitle("HHI") xline(0, lcolor(black)) ///
					legend(size(vsmall) order(2 1) r(2) label(1 "95% Confidence Interval") label(2 "Impact of Robot on emp-to-workpop Change")) ///
					graphregion(fcolor(white) ifcolor(white) ilcolor(white)) plotregion(fcolor(white) ifcolor(white) ilcolor(white) margin(b+2)) ///
					note("Figure # - Impact of exposure to robots on wage of labor markets with different levels of HHI." "This figure presents the result from column # of table #. Errors are clustered in state level")
	restore
	
	
ivreghdfe d_lnwage_0614 (er_us_emp06 interaction hhi_new=er_eu cworkpop_ehat cmastdoc_ehat celder_ehat cmanuf_ehat cnocoll_ehat ivinteraction1 ivinteraction2 ivinteraction3 ivinteraction4 ivinteraction5) $demographic cz_workpop, absorb(occsoc) cluster(state)
   
   
ivreghdfe d_lnwage_0614 (er_us_emp06 interaction hhi_new=er_eu cworkpop_ehat cmastdoc_ehat ivinteraction1 ivinteraction2) $demographic, absorb(occsoc) cluster(state)

ivreghdfe d_lnwage_0614 (er_us_emp06 interaction hhi_new=er_eu cworkpop_ehat celder_ehat ivinteraction1 ivinteraction3) $demographic, absorb(occsoc) cluster(state)
   
ivreghdfe d_lnwage_0614 (er_us_emp06 interaction hhi_new=er_eu cworkpop_ehat cmanuf_ehat ivinteraction1 ivinteraction4) $demographic, absorb(occsoc) cluster(state)

ivreghdfe d_lnwage_0614 (er_us_emp06 interaction hhi_new=er_eu cworkpop_ehat cnocoll_ehat ivinteraction1 ivinteraction5) $demographic, absorb(occsoc) cluster(state)

ivreghdfe d_lnwage_0614 (er_us_emp06 interaction hhi_new=er_eu cmastdoc_ehat celder_ehat ivinteraction2 ivinteraction3) $demographic, absorb(occsoc) cluster(state) /*bad*/

ivreghdfe d_lnwage_0614 (er_us_emp06 interaction hhi_new=er_eu cmastdoc_ehat cmanuf_ehat ivinteraction2 ivinteraction4) $demographic, absorb(occsoc) cluster(state)

ivreghdfe d_lnwage_0614 (er_us_emp06 interaction hhi_new=er_eu cmastdoc_ehat cnocoll_ehat ivinteraction2 ivinteraction5) $demographic, absorb(occsoc) cluster(state)

ivreghdfe d_lnwage_0614 (er_us_emp06 interaction hhi_new=er_eu celder_ehat  cnocoll_ehat ivinteraction3 ivinteraction5) $demographic, absorb(occsoc) cluster(state)

ivreghdfe d_lnwage_0614 (er_us_emp06 interaction hhi_new=er_eu cmanuf_ehat cnocoll_ehat ivinteraction4 ivinteraction5) $demographic, absorb(occsoc) cluster(state)

ivreghdfe d_lnwage_0614 (er_us_emp06 interaction hhi_new=er_eu cworkpop_ehat cmanuf_ehat cnocoll_ehat ivinteraction1 ivinteraction4 ivinteraction5) $demographic, absorb(occsoc) cluster(state)


ivreghdfe d_lnwage_0614 (er_us_emp06 interaction hhi_new=er_eu cmastdoc_ehat celder_ehat cnocoll_ehat ivinteraction2 ivinteraction3 ivinteraction5) $demographic, absorb(occsoc) cluster(state)

ivreghdfe d_lnwage_0614 (er_us_emp06 interaction hhi_new=er_eu cmastdoc_ehat cmanuf_ehat cnocoll_ehat ivinteraction2 ivinteraction4 ivinteraction5) $demographic, absorb(occsoc) cluster(state)



ivreghdfe d_lnwage_0614 (er_us_emp06 interaction hhi_new=er_eu celder_ehat  cnocoll_ehat ivinteraction3 ivinteraction5) $demographic, absorb(occsoc) cluster(state)




ivreghdfe d_lnwage_0614 (er_us_emp06 interaction hhi_new=er_eu celder_ehat cmanuf_ehat ivinteraction3 ivinteraction4) $demographic, absorb(occsoc) cluster(state)
ivreghdfe d_lnwage_0614 (er_us_emp06 interaction hhi_new=er_eu celder_ehat cmanuf_ehat ivinteraction3 ivinteraction4) $demographic, absorb(occsoc state) cluster(state)
ivreghdfe d_lnwage_0614 (er_us_emp06 interaction hhi_new=er_eu celder_ehat cmanuf_ehat ivinteraction3 ivinteraction4) $demographic [weight=emp_lm06], absorb(occsoc) cluster(state)
ivreghdfe d_lnwage_0614 (er_us_emp06 interaction hhi_new=er_eu celder_ehat cmanuf_ehat ivinteraction3 ivinteraction4) $demographic [weight=emp_lm06], absorb(occsoc state) cluster(state)

   

