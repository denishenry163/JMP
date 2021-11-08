clear all
global ipums "E:\Dropbox\Research\Ding's Proposal\WorkingFile\empirical_v2"
global tempdata "E:\Dropbox\Research\Ding's Proposal\WorkingFile\empirical_v2\temp_data"
global cw_ipums "E:\Dropbox\Research\Ding's Proposal\WorkingFile\empirical_v2\cw_ipums"
global dofiles "E:\Dropbox\Research\Ding's Proposal\WorkingFile\empirical_v2\dofiles"
global datafiles "E:\Dropbox\Research\Ding's Proposal\WorkingFile\empirical_v2\datafiles"
global results "E:\Dropbox\Research\Ding's Proposal\WorkingFile\empirical_v2\results"

cd "$datafiles"

doedit "$dofiles\gimputed.do"
doedit "$dofiles\ghhi_2016new.do"
doedit "$dofiles\gRoutiness.do"
		
		*** since all soc codes have been classified, better to check the uniformity of soc across 4 main datasets
			***check matching quality
			use imputed_census00,clear
			keep occsoc
			bys occsoc:keep if _n==1
			g row=_n
			save "$tempdata\cen00_soclist",replace
				*** 449 sococc
				*** 0 or 000000 is not applicable (kids or not in LF); 559830 is Millitary; 999920 is unemployed
			use imputed_acs06,clear
			keep occsoc
			bys occsoc:keep if _n==1
			g row=_n
			save "$tempdata\acs06_soclist",replace
				*** 449 sococc
			use imputed_acs14,clear
			keep occsoc
			bys occsoc:keep if _n==1
			g row=_n
			save "$tempdata\acs14_soclist",replace
				*** 449 soc occ
			use hhi_2016new,clear
			keep occsoc
			bys occsoc:keep if _n==1
			g row=_n
			save "$tempdata\marinew_soclist",replace
				*** 446 soc occ
				*** no 000000, 559830, and 999920
			use rti_soc,clear
				*** 443 soc occ
				*** no 000000, 55****, and 999920
			merge 1:1 occsoc using marinew_soclist
			*** all the 55**** are milliraty jobs, will be dropped from samples once rti kicks in
			
				
doedit "$dofiles\gER.do"
doedit "$dofiles\gdep.do"
doedit "$dofiles\regall.do"
doedit "$dofiles\gDiagrams.do"

