
  Attached you will find a .rar file that contains the folders/subfolders for the matlab code you will need to run the fitting/automated fitting.  Just extract the rar, put the folder in the "...Matlab/work" directory and add the new folder to the matlab Path, so it knows where to look for the code.

The main function you will want to use is "Metabolism_Preprocess_UCLA.m" Which calls "Both_Models.m"  These functions call all the back-end functions that do the fitting in an automated fashion and writes results to an .xls file.

Joe can show you how the data needs to be formatted to work with the current form of the automation code.

The general function call will be as follows:

Metabolism_Preprocess_UCLA(datafile,cutoff,q, MC_successes,sheets_2_compute, elongation)

datafile is a string that is the name of the .xls file, formatted for automation.  (IMPORTANT:  For some reason the code was balking at .xlsx files, so if that is your native format, simply save as a .xls before sending it to the program).

cutoff - this is the minimum AUC that will be used for fitting the data.  Any points for which AUC < cutoff will not contribute to the cost function or the fitting.  We have generally chosen this at 100 or 200 based on Joe's limit of linearity measurements (you can ask him more about this).

q - This can either be set to "0" in which case the background c13 percentage is computed independatly for each lipid in the xls, or it can be set to any other number for a pre-set value.  Because this is usually more accurate with larger AUCs, we generally fit this a priori using 18:0 background plates, and apply those results to all fittings.  (See the function binofit_jeffreys.m below).

MC_successes - this is an integer to give the number of times we replicate the random starting point for the elongation model (as it is fit with a gradient ascent algorithm, and the concavity of the cost-function space is unclear).  This is generally set to 5.  If there is an especially hard fit, it can be increased to 20.

sheets_2_comute -  this is simply a vector of which sheets in the excel file to do the automated fitting for (if you want to skip one for some reason).  If there are 13 lipids and you want to fit them all simply set it to [1:13]

elongation - this is a binary variable for whether or not to fit using model3.  If set to "0"  it will only fit using Model1, if it is set to "1" it will fit using both.



binofit_jeffreys.m - This function can be found in the "tools" subdirectory of the files I sent.  It gives a MLE for the success rate (phat) of a binomial process, with the CI based on a specified alpha.  It is called as follows:

[phat, ci]=binofit_jeffreys(x,alpha)

here x is a vector of the observed successes.  In this context x(1) = percent M+0, x(2) = percent M+1, etc.

It is assumed that all possible success observations are contained in x.  This is important, if you are looking to fit q for an 18:0 species, x must be a 20X1 vector.  (1 for no label, 18 for all possible other labels, and 1 for the possible addition of another label during methylation).

For our purposes ci and alpha are not important, but you can set alpha to .05.