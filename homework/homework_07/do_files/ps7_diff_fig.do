*==============================================================
* ps7_diff_fig.do -- Card-Krueger DiD figure for Problem 2(d)
* Plots mean FTE employment for NJ (treatment) and
* Eastern PA (control) at t=1 (before) and t=2 (after),
* with the counterfactual extrapolation used to read off
* beta_1^{DID}.
*==============================================================
clear all
set more off
capture log close
* Resolve the project root portably: allow launch from homework_07/ or do_files/.
capture confirm file "homework_07.tex"
if _rc {
    capture confirm file "../homework_07.tex"
    if _rc {
        di as err "Could not find homework_07.tex. Run from homework_07 or homework_07/do_files."
        exit 601
    }
    cd ..
}
capture mkdir "output"
capture mkdir "output/figures"
log using "do_files/ps7_diff_fig.log", replace text

input state    time    y       label_str
1        1       23.33   1
1        2       21.17   2
2        1       20.44   3
2        2       21.03   4
end
label define st 1 "PA (control)" 2 "NJ (treatment)"
label values state st

* Counterfactual NJ-after = NJ-before + PA change
scalar delta_pa = 21.17 - 23.33
scalar nj_cf    = 20.44 + delta_pa
scalar did_hat  = 21.03 - nj_cf
local did_label : display %4.2f did_hat
local nj_cf_label : display %4.2f nj_cf

twoway ///
    (line y time if state==1, sort lcolor(gs5) lwidth(medthick) lpattern(solid)) ///
    (line y time if state==2, sort lcolor(navy) lwidth(medthick) lpattern(solid)) ///
    (scatter y time if state==1, mcolor(gs5) msymbol(O) msize(medlarge)) ///
    (scatter y time if state==2, mcolor(navy) msymbol(D) msize(medlarge)) ///
    (pcarrowi 20.44 2 `=nj_cf' 2 , lcolor(red) lpattern(dash) msymbol(none)) ///
    (scatteri `=nj_cf' 2, mcolor(red) msymbol(X) msize(medlarge)), ///
    legend(order(1 "PA (control)" 2 "NJ (treatment)" 6 "NJ counterfactual") ///
           position(6) cols(3) size(small)) ///
    xlabel(1 "t=1 (Feb 1992, pre-MW)" 2 "t=2 (Nov 1992, post-MW)", labsize(small)) ///
    ylabel(18(1)24, labsize(small) angle(0)) ///
    xtitle("Time period (minimum-wage hike = 1992-04-01 in NJ)", size(small)) ///
    xscale(range(0.8 2.2)) ///
    ytitle("Average FTE employment per restaurant", size(small)) ///
    title("Card--Krueger (1994) diff-in-diff", size(medium)) ///
    note("{stSerif:{it:Y-bar-control,before}} = 23.33, {stSerif:{it:Y-bar-control,after}} = 21.17;" ///
         "{stSerif:{it:Y-bar-treatment,before}} = 20.44, {stSerif:{it:Y-bar-treatment,after}} = 21.03." ///
         "{&beta}{sub:1}{sup:DID} = (21.03 {&minus} 20.44) {&minus} (21.17 {&minus} 23.33) = `did_label'.", ///
         size(vsmall)) ///
    text(20.44 1.03 "Y-bar{sub:treatment,before} = 20.44", place(e) size(vsmall)) ///
    text(21.03 1.97 "Y-bar{sub:treatment,after} = 21.03", place(w) size(vsmall)) ///
    text(23.33 1.03 "Y-bar{sub:control,before} = 23.33", place(e) size(vsmall)) ///
    text(21.17 1.97 "Y-bar{sub:control,after} = 21.17", place(w) size(vsmall)) ///
    text(`=nj_cf+0.3' 1.97 "NJ counterfactual = `nj_cf_label'", place(w) size(vsmall) color(red)) ///
    graphregion(color(white)) plotregion(color(white)) bgcolor(white)

graph export "output/figures/prob2_did_fig.pdf", replace

display "delta_pa = "   %6.3f delta_pa
display "NJ counterfactual = " %6.3f nj_cf
display "beta_1^{DID}  = "  %6.3f did_hat
log close
