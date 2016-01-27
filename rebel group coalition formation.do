* Leslie Huang
* New York University Department of Politics
* 12/2015

capture log close
clear *
cd /* change to your working directory */

log using mergerlog.log, replace
use "nsa data converted.dta", clear /* Gleditsch et. al's Non State Actor data is the 
foundation of this project and is found on Gleditsch's website: 
http://privatewww.essex.ac.uk/~ksg/eacd.html 
Note: you will need to convert from ASCII to a CSV or Stata file to continue. */

* Recode fighting capacity variable as categorical var and fix incorrectly coded missing data.
replace fightcap = "999999" if fightcap=="NA"
replace fightcap = "999999" if fightcap=="no"
replace fightcap = "0" if fightcap=="low"
replace fightcap = "1" if fightcap=="moderate"
replace fightcap= "2" if fightcap=="high"
destring fightcap, replace
replace fightcap = . if fightcap == 999999
label var fightcap "Relative Fighting Capacity"

* Recode arms procurement variable as categorical var and fix incorrectly coded missing data.
replace armsproc = "999999" if armsproc=="NA"
replace armsproc = "999999" if armsproc=="no"
replace armsproc = "0" if armsproc=="low"
replace armsproc = "1" if armsproc=="moderate"
replace armsproc= "2" if armsproc=="high"
destring armsproc, replace
replace armsproc = . if armsproc == 999999
label var armsproc "Relative Ability to Procure Arms"

* Recode mobilization capacity variable as categorical var and fix incorrectly coded missing data.
replace mobcap = "999999" if mobcap=="NA"
replace mobcap = "999999" if mobcap=="no"
replace mobcap = "0" if mobcap=="low"
replace mobcap = "1" if mobcap=="moderate"
replace mobcap= "2" if mobcap=="high"
destring mobcap, replace
replace mobcap = . if mobcap == 999999
label var mobcap "Relative Mobilization Capacity"

* Recode centralized control as indicator variable.
replace centcontrol = "999999" if centcontrol=="NA"
replace centcontrol = "0" if centcontrol=="no"
replace centcontrol = "1" if centcontrol=="yes"
destring centcontrol, replace
replace centcontrol = . if centcontrol == 999999
label var centcontrol "Rebel Centralized Control Indicator"

* Transform "rebstrength" variable into a categorical variable ranging from much weaker (0) to much stronger (4), with parity=2.
replace rebstrength = "999999" if rebstrength=="NA"
replace rebstrength = "4" if rebstrength=="much stronger"
replace rebstrength = "3" if rebstrength=="stronger"
replace rebstrength = "2" if rebstrength=="parity"
replace rebstrength = "1" if rebstrength=="weaker"
replace rebstrength = "0" if rebstrength=="much weaker"
destring rebstrength, replace
replace rebstrength = . if rebstrength == 999999
label var rebstrength "Relative Rebel Strength"
label define rebstrengthlabels 0 "Much Weaker" 1 "Weaker" 2 "Parity" 3 "Stronger" 4 "Much Stronger"
label values rebstrength rebstrengthlabels

* Recoding rebel strength estimates as floats, and properly coding missing values.
replace rebestimate = "999999" if rebestimate == "NA"
destring rebestimate, replace
replace rebestimate = . if rebstrength == 999999

replace rebestlow = "999999" if rebestlow == "NA"
destring rebestlow, replace
replace rebestlow = . if rebestlow == 999999

replace rebesthigh = "999999" if rebesthigh == "NA"
destring rebesthigh, replace
replace rebesthigh = . if rebesthigh == 999999

* Create dummy var for ethnic conflict.
gen ethnic = 0
replace ethnic = 1 if conflicttype=="ethnic conflict"
replace ethnic = . if conflicttype=="NA"

* Recode territorial control var as dummy var.
replace terrcont = "999999" if terrcont == "NA"
replace terrcont = "0" if terrcont == "no"
replace terrcont = "1" if terrcont == "yes"
destring terrcont, replace
replace terrcont = . if terrcont == 999999

* Create dummy var for rebel group merger.
gen merger = 0
replace merger = 1 if typeoftermination == "6.1"
replace merger = . if typeoftermination == "NA"
label var merger "Rebel Group Merger Indicator"

* Recode rebel political wing var as an indicator var.
replace rebpolwing = "0" if rebpolwing == "no"
replace rebpolwing = "999999" if rebpolwing == "NA"
replace rebpolwing = "1" if rebpolwing == "acknowledged link"
replace rebpolwing = "1" if rebpolwing == "alleged link"
replace rebpolwing = "1" if rebpolwing == "explicit link"
destring rebpolwing, replace
replace rebpolwing = . if rebpolwing == 999999

* Recode rebelsupport as indicator var.
replace rebelsupport = "0" if rebelsupport == "no"
replace rebelsupport = "1" if rebelsupport == "alleged"
replace rebelsupport = "1" if rebelsupport == "explicit"
replace rebelsupport = "999999" if rebelsupport == "NA"
destring rebelsupport, replace
replace rebelsupport = . if rebelsupport == 999999

* Fix some unlabeled variables.
label var rebpolwing "Rebel Political Wing Indicator"
label var terrcon "Rebel Territorial Control"
label var ethnic "Ethnic Conflict"

* Fix victoryside var
label var victoryside "Winning Side if Military Victory"
replace victoryside = "999999" if victoryside == "NA"
destring victoryside, replace
replace victoryside = . if victoryside == 999999
label define vsidelabels 1 "Government" 2 "Rebels"
label values victoryside vsidelabels

* Rebel strength and victory crosstab:
tab victoryside rebstrength, all col
tabout victoryside rebstrength using victoryside_crosstab.xls, cell(freq col) format(0 1) stats(chi2) layout(row) show(all) replace

********** Regression analysis of rebel mergers

* Focus on the dyads where a merger was possible mathematically
drop if atleast2dyads == 0

* Spearman rank correlation matrix for suspected collinear dependent variables
spearman rebstrength mobcap fightcap armsproc , star(0.05) matrix
matrix S = r(Rho)
mat2txt2 matrix(S) using mat.xls, label format(%8.3f) title("Spearman Rank Correlation") note("*** p<0.01, ** p<0.05, * p<0.1") replace

* The model with control variables
probit merger rebstrength mobcap fightcap armsproc terrcon centcon ethnic rebpolwing , vce(cluster acr)

* Output table
outreg2 using probit1.doc, title("Rebel Strength and Mergers") drop(merger) label sideway parenthesis(se) stats(coef se pval) coefastr symb(***,**,*) rdec(2) bdec(2) ctitle("Coefficient"; "Robust SE"; "P>|z|") nocons r2 addstat(Pseudo R2, e(r2_p), chi2, e(N)) nonotes addnote("Robust standard errors clustered by country in parentheses", "*** p<0.01, ** p<0.05, * p<0.1") replace

* Output marginal effects graphs for all vars
probit merger rebstrength mobcap fightcap armsproc terrcon centcon ethnic rebpolwing , vce(cluster acr)
margins, dydx(*) post
outreg2 using margins1.doc, ctitle("Marginal Effects") label replace

probit merger rebstrength mobcap fightcap armsproc terrcon centcon ethnic rebpolwing , vce(cluster acr)
margins, dydx(*)
marginsplot, allxlabels xlabel(1 "Rebel Strength" 2 "Mobilization Capacity" 3 "Fighting Capacity" 4 "Ability to Procure Arms" 5 "Territorial Control" 6 "Centralized Control" 7 "Ethnic Conflict" 8 "Political Wing", angle(45) labsize(small)) ylabel(, labsize(small)) xtitle("Effects with Respect to" "Military Strength Variables and Controls")
graph export marginsgraph1.png, replace

* Output marginalfx graphs for rebstrength
probit merger rebstrength mobcap fightcap armsproc terrcon centcon ethnic rebpolwing , vce(cluster acr)
margins, dydx(rebstrength) at(rebstrength=(0(1)4)) 
marginsplot, allxlabels yline(0) xlabel(, angle(45) labsize(small)) ylabel(, labsize(small)) title("Average Marginal Effect of Rebel Strength Level" "on Rebel Merger Likelihood", size(medlarge))
graph export rebmargins.png, replace

* Adjusted for collinear independent variables
probit merger rebstrength mobcap terrcon centcon ethnic rebpolwing , vce(cluster acr)
margins, dydx(*)

outreg2 using probit2.doc, title("Rebel Strength and Mergers (Corrected)") drop(merger) label sideway parenthesis(se) stats(coef se pval) coefastr symb(***,**,*) rdec(2) bdec(2) ctitle("Coefficient"; "Robust SE"; "P>|z|") nocons r2 addstat(Pseudo R2, e(r2_p), chi2, e(N)) nonotes addnote("Robust standard errors clustered by country in parentheses", "*** p<0.01, ** p<0.05, * p<0.1") replace
