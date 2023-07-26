********* CAN I WRITE A SIMPLE STATA FUNCTION FOR DOING IT (taking as input the already merged database possibly)??????
********* MAYBE I CAN PUT A "QUARTERLY" OPTION AS WELL...

******** MAIN INGEDIENTS are the CA analysis results. The code below takes for granted that a CA analysis is performed. In other words we need:

******** 1) The bootstrapped coefficients of the CA analysis (adv_regressions_all_together);
******** 2) The original coefficients from the CA analysis (original_coefficients_advcadiff);

***** These two will be merged as follows:

use "/Users/federiconutarelli/Desktop/joint_p_values/adv_regressions_all_together", clear
sort Variable
egen id = group(Variable)
merge m:1 id using "/Users/federiconutarelli/Desktop/joint_p_values/original_coefficients_advcadiff.dta"
drop _merge
bys id: egen boot = seq(), f(1) t(100)


capture program drop jp_vals
program jp_vals, rclass 

preserve
gen Z_c = Coeff- Coeff_orig

***Constructing Sigma step by step:
** Step 1: take the 75th and 25th quantiles of Z in the bootstrap draws (Z_c). Users can define whatever quantiles they desire: 

local var1 = `1'
local var2 = `2'

local p1 = `1'/100 // User specified. Here: 0.75
local p2 = `2'/100 // User specified. Here: 0.25

// Calculate the quantiles
local q1 = invnormal(`p1')
local q2 = invnormal(`p2')

// Compute the difference
local diff = `q1' - `q2'

*di "qnorm(0.75) - qnorm(0.25) = `diff'"


di "Joint p-values computed at the `var1'th and `var2'th quantiles"
	
quietly gen sig = 0
quietly sum id
quietly forval i = 1/`r(max)' {
	quietly centile Z_c if id==`i', centile(`1')
	local up_centile_Z_`i' `r(c_1)'
	di  `up_centile_Z_`i''
	quietly centile Z_c if id==`i', centile(`2')
	local low_centile_Z_`i' `r(c_1)'
	di  `low_centile_Z_`i''
	**1.34898, being: (qnorm(0.75)-qnorm(0.25)).
	replace sig = (`up_centile_Z_`i''-`low_centile_Z_`i'')/`diff' if id==`i'
	
}

** Step 2: take the 75th and 25th quantiles of standard normal distribution (denominator): 
**1.34898, being: (qnorm(0.75)-qnorm(0.25)).
*gen sig = (`up_centile_Z'-`low_centile_Z')/1.34898

quietly bys id: gen t_tilde = abs(Z_c)/sig
quietly egen t_tilde_max = max(t_tilde), by(boot)
quietly egen draws_H_mean = mean(Coeff), by(id)
quietly gen H_c = 2*Coeff_orig-draws_H_mean

*NOT bias corrected:
quietly gen stat = abs(Coeff_orig)/sig

*Bias corrected:
quietly gen stat_bc = abs(H_c)/sig
quietly bys id: gen j_pvals= cond(abs(t_tilde_max)>abs(stat),1,0)
quietly bys id: gen j_pvals_bc= cond(abs(t_tilde_max)>abs(stat_bc),1,0)
quietly egen j_pvals_final = sum(j_pvals), by(id)
quietly egen j_pvals_final_bc = sum(j_pvals_bc), by(id)
quietly replace j_pvals_final = j_pvals_final/100
quietly replace j_pvals_final_bc = j_pvals_final_bc/100

quietly collapse (first) Variable j_pvals_final Coeff_orig j_pvals_final_bc, by(id)
quietly gen significance = 1 if j_pvals_final<=0.05
quietly gen significance_bc = 1 if j_pvals_final_bc<=0.05

dataout, save(adv_annual_case_jpvals) tex replace
restore

end

*Example call of the program at the 75th and 25th quantiles:
*jp_vals 75 25 
