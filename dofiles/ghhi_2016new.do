clear all
global empirical_v2 "E:\Dropbox\Research\Ding's Proposal\WorkingFile\empirical_v2"
global tempdata "E:\Dropbox\Research\Ding's Proposal\WorkingFile\empirical_v2\temp_data"
global cw_ipums "E:\Dropbox\Research\Ding's Proposal\WorkingFile\empirical_v2\cw_ipums"
global datafiles "E:\Dropbox\Research\Ding's Proposal\WorkingFile\empirical_v2\datafiles"

cd "$datafiles"

/*
use "$cw_ipums\cw_occ10_soc",clear
keep if substr(soc,7,1)=="0" & substr(soc,6,1)!="0"
g soc5=substr(soc,1,6)
keep soc5
save soc5,replace
   *** identifies occ with soc5-level in cw ***

use hhi_2016,clear
g soc_new=soc
g soc5=substr(soc,1,6)
mmerge soc5 using soc5, type(n:1)
   ****all merge obs are occupations with soc5-level in cw table and soc6-level in Marinescu*****
replace soc_new=soc5+"0" if _merge==3
   ************match with cw_occ10_soc and occ2010 table*************
replace soc_new="15-113X" if soc=="15-1132" | soc=="15-1133"
replace soc_new="21-109X" if soc=="21-1091" | soc=="21-1094" | soc=="21-1099"
replace soc_new="25-90XX" if soc=="25-9011" | soc=="25-9021" | soc=="25-9031" | soc=="25-9099"
replace soc_new="31-909X" if soc=="31-9093" | soc=="31-9099"
replace soc_new="33-909X" if soc=="33-9092" | soc=="33-9099"
replace soc_new="37-201X" if soc=="37-2011" | soc=="37-2019"
replace soc_new="39-40XX" if soc=="39-4011" | soc=="39-4021"
replace soc_new="47-50XX" if soc=="47-5051" | soc=="47-5099"
replace soc_new="49-209X" if soc=="49-2094" | soc=="49-2095"
replace soc_new="49-904X" if soc=="49-9041" | soc=="49-9045"
replace soc_new="49-909X" if soc=="49-9093" | soc=="49-9099"
replace soc_new="53-40XX" if soc=="53-4041" | soc=="53-4099"
replace soc_new="53-60XX" if soc=="53-6041" | soc=="53-6099"
replace soc_new="25-1000" if substr(soc,1,4)=="25-1"
replace soc_new="25-3000" if substr(soc,1,4)=="25-3"
replace soc_new="29-9000" if substr(soc,1,4)=="29-9"
replace soc_new="53-1000" if substr(soc,1,4)=="53-1"

replace soc_new="11-31XX" if soc_new=="11-3111" | soc_new=="11-3121" | soc_new=="11-3131"
replace soc_new="13-107X" if soc_new=="13-1070" | soc_new=="13-1141" | soc_new=="13-1151"
replace soc_new="15-11XX" if soc_new=="15-1111" | soc_new=="15-1121" | soc_new=="15-1122"
replace soc_new="15-114X" if soc_new=="15-1142" | soc_new=="15-1143" | soc_new=="15-1199"
replace soc_new="51-511X" if soc_new=="51-5112" | soc_new=="51-5113"
replace soc_new="53-30XX" if soc_new=="53-3011" | soc_new=="53-3020"
drop _merge soc5
g weight_temp=1/ranking_size
bys czone2000 soc_new: egen total_weight=total(weight_temp)
g weight=weight_temp/total_weight
bys czone2000 soc_new: egen hhi_new=total(weight*hhi2016)
bys czone2000 soc_new: keep if _n==1
keep czone2000 soc_new hhi_new
save hhi_2016new,replace
*/

use hhi_2016,clear
g soc_new=soc
replace soc_new=substr(soc_new,1,2)+substr(soc_new,4,4)
	* recategorize to my own soc system in order to
	* set 2000 census, 2006 ACS, 2014 ACS and Marinescu data in the same occupation system
	* see notes
replace soc_new="112020" if soc_new=="112021" | soc_new=="112022"
replace soc_new="113040" if soc_new=="113111" | soc_new=="113121" | soc_new=="113131"
replace soc_new="119030" if soc_new=="119031" | soc_new=="119032" | soc_new=="119033" | soc_new=="119039"
replace soc_new="119199" if soc_new=="119061" | soc_new=="119131" | soc_new=="119161"
replace soc_new="131030" if soc_new=="131031" | soc_new=="131032"
replace soc_new="131070" if soc_new=="131071" | soc_new=="131074" | soc_new=="131075"
replace soc_new="1311XX" if soc_new=="131131" | soc_new=="131141" | soc_new=="131151" | soc_new=="131161" | soc_new=="131199"
replace soc_new="132070" if soc_new=="132071" | soc_new=="132072"
replace soc_new="1510XX" if soc_new=="151111" | soc_new=="151121" | soc_new=="151122"
replace soc_new="151021" if soc_new=="151131"
replace soc_new="151030" if soc_new=="151132" | soc_new=="151133" | soc_new=="151134"
replace soc_new="151041" if soc_new=="151151" | soc_new=="151152"
replace soc_new="151061" if soc_new=="151141"
replace soc_new="151071" if soc_new=="151142"
replace soc_new="151081" if soc_new=="151143" | soc_new=="151199"
replace soc_new="1520XX" if soc_new=="152021" | soc_new=="152041" | soc_new=="152091" | soc_new=="152099"
replace soc_new="171010" if soc_new=="171011" | soc_new=="171012"
replace soc_new="171020" if soc_new=="171021" | soc_new=="171022"
replace soc_new="172XXX" if soc_new=="172021" | soc_new=="172031" | soc_new=="172161" | soc_new=="172199"
replace soc_new="1721XX" if soc_new=="172151" | soc_new=="172171"
replace soc_new="172070" if soc_new=="172071" | soc_new=="172072"
replace soc_new="172110" if soc_new=="172111" | soc_new=="172112" 
replace soc_new="173010" if soc_new=="173011" | soc_new=="173012" | soc_new=="173013" | soc_new=="173019" 
replace soc_new="173020" if soc_new=="173021" | soc_new=="173022" | soc_new=="173023" | soc_new=="173024" | soc_new=="173025" | soc_new=="173026" | soc_new=="173027" | soc_new=="173029"
replace soc_new="191010" if soc_new=="191011" | soc_new=="191012" | soc_new=="191013"
replace soc_new="191020" if soc_new=="191021" | soc_new=="191022" | soc_new=="191023" | soc_new=="191029"
replace soc_new="191030" if soc_new=="191031" | soc_new=="191032"
replace soc_new="191040" if soc_new=="191041" | soc_new=="191042" | soc_new=="191099"
replace soc_new="192010" if soc_new=="192011" | soc_new=="192012"
replace soc_new="192030" if soc_new=="192031" | soc_new=="192032"
replace soc_new="192040" if soc_new=="192041" | soc_new=="192042" | soc_new=="192043"
replace soc_new="1930XX" if soc_new=="193022" | soc_new=="193041" | soc_new=="193091" | soc_new=="193092" | soc_new=="193093" | soc_new=="193094" | soc_new=="193099"
replace soc_new="193030" if soc_new=="193031" | soc_new=="193032" | soc_new=="193039"
replace soc_new="1940XX" if soc_new=="194041" | soc_new=="194051" | soc_new=="194061" | soc_new=="194091" | soc_new=="194092" | soc_new=="194093" | soc_new=="194099"
replace soc_new="211010" if substr(soc_new,1,5)=="21101"
replace soc_new="211020" if substr(soc_new,1,5)=="21102"
replace soc_new="211090" if substr(soc_new,1,5)=="21109"
replace soc_new="2310XX" if substr(soc_new,1,4)=="2310"
replace soc_new="232090" if substr(soc_new,1,5)=="23209"
replace soc_new="251000" if substr(soc_new,1,3)=="251"
replace soc_new="252010" if substr(soc_new,1,5)=="25201"
replace soc_new="252020" if substr(soc_new,1,5)=="25202"
replace soc_new="252030" if substr(soc_new,1,5)=="25203"
replace soc_new="252040" if substr(soc_new,1,5)=="25205"
replace soc_new="253000" if substr(soc_new,1,3)=="253"
replace soc_new="254010" if substr(soc_new,1,5)=="25401"
replace soc_new="2590XX" if soc_new=="259011" | soc_new=="259021" | soc_new=="259031" | soc_new=="259099"
replace soc_new="271010" if substr(soc_new,1,5)=="27101"
replace soc_new="271020" if substr(soc_new,1,5)=="27102"
replace soc_new="272020" if substr(soc_new,1,5)=="27202"
replace soc_new="272030" if substr(soc_new,1,5)=="27203"
replace soc_new="272040" if substr(soc_new,1,5)=="27204"
replace soc_new="273010" if substr(soc_new,1,5)=="27301"
replace soc_new="273020" if substr(soc_new,1,5)=="27302"
replace soc_new="273090" if substr(soc_new,1,5)=="27309"
replace soc_new="2740XX" if substr(soc_new,1,5)=="27401" | soc_new=="274099"
replace soc_new="274030" if substr(soc_new,1,5)=="27403"
replace soc_new="291020" if substr(soc_new,1,5)=="29102"
replace soc_new="291060" if substr(soc_new,1,5)=="29106"
replace soc_new="291111" if soc_new=="291141" | soc_new=="291151" | soc_new=="291161" | soc_new=="291171"
replace soc_new="291121" if soc_new=="291181"
replace soc_new="291129" if soc_new=="291128"
replace soc_new="292010" if substr(soc_new,1,5)=="29201"
replace soc_new="292030" if substr(soc_new,1,5)=="29203"
replace soc_new="292050" if substr(soc_new,1,5)=="29205"
replace soc_new="292090" if substr(soc_new,1,5)=="29209"
replace soc_new="299000" if substr(soc_new,1,3)=="299"
replace soc_new="311010" if substr(soc_new,1,5)=="31101"
replace soc_new="312010" if substr(soc_new,1,5)=="31201"
replace soc_new="312020" if substr(soc_new,1,5)=="31202"
replace soc_new="31909X" if soc_new=="319092" | soc_new=="319093" | soc_new=="319094" | soc_new=="319095" | soc_new=="319096" | soc_new=="319097" | soc_new=="319099"
replace soc_new="332020" if substr(soc_new,1,5)=="33202"
replace soc_new="333010" if substr(soc_new,1,5)=="33301"
replace soc_new="3330XX" if soc_new=="333031" | soc_new=="333041"
replace soc_new="333050" if substr(soc_new,1,5)=="33305"
replace soc_new="339030" if substr(soc_new,1,5)=="33903"
replace soc_new="33909X" if soc_new=="339092" | soc_new=="339093" | soc_new=="339099"
replace soc_new="352010" if substr(soc_new,1,5)=="35201"
replace soc_new="3590XX" if soc_new=="359011" | soc_new=="359099"
replace soc_new="37201X" if soc_new=="372011" | soc_new=="372019"
replace soc_new="373010" if substr(soc_new,1,5)=="37301"
replace soc_new="391010" if substr(soc_new,1,5)=="39101"
replace soc_new="393010" if substr(soc_new,1,5)=="39301"
replace soc_new="393090" if substr(soc_new,1,5)=="39309"
replace soc_new="394000" if substr(soc_new,1,3)=="394"
replace soc_new="395090" if substr(soc_new,1,5)=="39509"
replace soc_new="396010" if substr(soc_new,1,5)=="39601"
replace soc_new="397010" if substr(soc_new,1,5)=="39701"
replace soc_new="399030" if substr(soc_new,1,5)=="39903"
replace soc_new="412010" if substr(soc_new,1,5)=="41201"
replace soc_new="414010" if substr(soc_new,1,5)=="41401"
replace soc_new="419010" if substr(soc_new,1,5)=="41901"
replace soc_new="419020" if substr(soc_new,1,5)=="41902"
replace soc_new="434XXX" if soc_new=="434021" | soc_new=="434151"
replace soc_new="435030" if substr(soc_new,1,5)=="43503"
replace soc_new="436010" if substr(soc_new,1,5)=="43601"
replace soc_new="439XXX" if soc_new=="439031" | soc_new=="439199"
replace soc_new="451010" if soc_new=="451011"
replace soc_new="4520XX" if soc_new=="452021" | substr(soc_new,1,5)=="45209"
replace soc_new="453000" if substr(soc_new,1,3)=="453"
replace soc_new="454020" if substr(soc_new,1,5)=="45402"
replace soc_new="472020" if substr(soc_new,1,5)=="47202" | soc_new=="472171"
replace soc_new="472040" if substr(soc_new,1,5)=="47204"
replace soc_new="472050" if substr(soc_new,1,5)=="47205"
replace soc_new="47207X" if soc_new=="472072" | soc_new=="472073"
replace soc_new="472080" if substr(soc_new,1,5)=="47208"
replace soc_new="472130" if substr(soc_new,1,5)=="47213"
replace soc_new="472140" if substr(soc_new,1,5)=="47214"
replace soc_new="472150" if substr(soc_new,1,5)=="47215"
replace soc_new="47XXXX" if soc_new=="472231" | soc_new=="474071" | substr(soc_new,1,5)=="47409"
replace soc_new="473010" if substr(soc_new,1,5)=="47301"
replace soc_new="4750YY" if substr(soc_new,1,5)=="47501"
replace soc_new="475040" if substr(soc_new,1,5)=="47504"
replace soc_new="4750XX" if soc_new=="475051" | soc_new=="475061" | soc_new=="475071" | soc_new=="475081" | soc_new=="475099"
replace soc_new="492020" if substr(soc_new,1,5)=="49202"
replace soc_new="49209X" if soc_new=="492093" | soc_new=="492094" | soc_new=="492095"
replace soc_new="493040" if substr(soc_new,1,5)=="49304"
replace soc_new="493050" if substr(soc_new,1,5)=="49305"
replace soc_new="493090" if substr(soc_new,1,5)=="49309"
replace soc_new="499010" if substr(soc_new,1,5)=="49901"
replace soc_new="499042" if soc_new=="499071"
replace soc_new="49904X" if soc_new=="499041" | soc_new=="499045"
replace soc_new="499060" if substr(soc_new,1,5)=="49906"
drop if soc_new=="499081"
replace soc_new="49909X" if soc_new=="499092" | soc_new=="499093" | soc_new=="499095" | soc_new=="499097" | soc_new=="499099"
replace soc_new="512020" if substr(soc_new,1,5)=="51202"
replace soc_new="512090" if substr(soc_new,1,5)=="51209"
replace soc_new="513020" if substr(soc_new,1,5)=="51302"
drop if soc_new=="513099"
replace soc_new="514010" if substr(soc_new,1,5)=="51401"
replace soc_new="514030" if substr(soc_new,1,5)=="51403"
replace soc_new="514050" if substr(soc_new,1,5)=="51405"
replace soc_new="5140XX" if soc_new=="514081" | substr(soc_new,1,5)=="51406" | substr(soc_new,1,5)=="51407"
replace soc_new="514120" if substr(soc_new,1,5)=="51412"
replace soc_new="514XXX" if substr(soc_new,1,5)=="51419"
replace soc_new="515023" if soc_new=="515112" | soc_new=="515113"
replace soc_new="516040" if substr(soc_new,1,5)=="51604"
replace soc_new="516050" if substr(soc_new,1,5)=="51605"
replace soc_new="51606X" if soc_new=="516061" | soc_new=="516062"
replace soc_new="51609X" if soc_new=="516091" | soc_new=="516092" | soc_new=="516099"
replace soc_new="5170XX" if soc_new=="517099" | soc_new=="517031" | soc_new=="517032"
replace soc_new="518010" if substr(soc_new,1,5)=="51801"
replace soc_new="518090" if substr(soc_new,1,5)=="51809"
replace soc_new="519010" if substr(soc_new,1,5)=="51901"
replace soc_new="519020" if substr(soc_new,1,5)=="51902"
replace soc_new="519030" if substr(soc_new,1,5)=="51903"
replace soc_new="519080" if substr(soc_new,1,5)=="51908"
replace soc_new="519120" if substr(soc_new,1,5)=="51912"
replace soc_new="5191XX" if soc_new=="519141" | soc_new=="519192" | soc_new=="519193" | soc_new=="519199"
replace soc_new="531000" if substr(soc_new,1,3)=="531"
replace soc_new="532010" if substr(soc_new,1,5)=="53201"
replace soc_new="532020" if substr(soc_new,1,5)=="53202"
drop if soc_new=="532031" | soc_new=="533011"
replace soc_new="533020" if substr(soc_new,1,5)=="53302"
replace soc_new="533030" if substr(soc_new,1,5)=="53303"
replace soc_new="534010" if substr(soc_new,1,5)=="53401"
replace soc_new="5340XX" if soc_new=="534041" | soc_new=="534099"
replace soc_new="534031" if soc_new=="534021"
replace soc_new="5350XX" if soc_new=="535011" | soc_new=="535031"
replace soc_new="535020" if substr(soc_new,1,5)=="53502"
replace soc_new="5360XX" if soc_new=="536011" | soc_new=="536041" | soc_new=="536061" | soc_new=="536099"
replace soc_new="537030" if substr(soc_new,1,5)=="53703"
replace soc_new="537041" if soc_new=="537011" | soc_new=="5370XX"
replace soc_new="537070" if substr(soc_new,1,5)=="53707"
replace soc_new="5371XX" if substr(soc_new,1,4)=="5371"
replace soc_new="551010" if substr(soc_new,1,5)=="55101"
replace soc_new="552010" if substr(soc_new,1,5)=="55201"
replace soc_new="553010" if substr(soc_new,1,5)=="55301"
replace soc_new="559830" if substr(soc_new,1,5)=="55983"

g weight_temp=1/ranking_size
bys czone2000 soc_new: egen total_weight=total(weight_temp)
g weight=weight_temp/total_weight
bys czone2000 soc_new: egen hhi_new=total(weight*hhi2016)
bys czone2000 soc_new: keep if _n==1
keep czone2000 soc_new hhi_new
rename soc_new occsoc
save hhi_2016new,replace
	*** 186560 obs
	*** make it a balanced panel
	use "$cw_ipums\cw_cty_cz2000",clear
	drop FIPS
	bys czone2000: keep if _n==1
	expand 446
	bys czone2000: g row=_n
	merge m:1 row using "$tempdata\marinew_soclist"
	drop _merge row
	merge 1:1 czone2000 occsoc using hhi_2016new
	*** 129652 missing markets
	*replace emp_lm06=0 if missing(emp_lm06)
	*replace emp_lm06_ratio=0 if missing(emp_lm06_ratio)
	*replace wage_lm06=0 if missing(wage_lm06)
	drop _merge
save hhi_2016new,replace
