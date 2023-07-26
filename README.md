# joint_pvalues_chern
This program computes the joint p-values for CADiffs from the paper The Sorted Effects Method: Discovering Heterogeneous Effects Beyond Their Averages by Chernuzokov et al. (2018).

# Documentation and ratio
See the file in the pdf folder

# Input data
1) The bootstrapped coefficients of the CA analysis (see adv_regressions_all_together.dta for an example);
2) The original coefficients from the CA analysis (see original_coefficients_advcadiff.dta for an example);
The jpv_program.do file merges the two internally. 

# Usage
To call the program, simply run the jpv_program.do file substituting the input data with your own data. Once the jp_vals program is stored in stata simply call jp_vals first_quantile second_quantile where first_quantile and second_quantile can be changed by the user. Remember that every time you close STATA you have to run the jpv_program.do file again to save the jp_vals program (unless you decide to store it permanently into STATA).
