%%% Function of this script: 
%% This script calculates % of synthesis, elongation and % contribution of




%%%%% User Interface %%%%%%%
%%% most important:
sheets_2_compute=1:1; % the sheets you want to run. e.g: =1:13 for all 13 sheets, [1,3,4,7] for these sheets
cutoff=50;   %this is the minimum AUC that will be used for fitting the data.  Any points for which AUC < cutoff will not contribute to the cost function or the fitting.
               % and if you want different cutoff for different fatty acid, set cutoff=[50,100,200], which means 50 for the 1st FA, 100 for the 2nd, 200 for the rest              
%%% usually not changed
q=0.011;    % the natural occuring 13C percentage, =0 the script will calclute q from control, if set =0.112, then this is the value that will be used in the fitting
lambda=0.023; % percentage of fragmentation for cholesterol data. nonsenese for fatty acid. if lambda=0, scripts will either calculate from unlabel controls or use default=0.023
user_p=[0,1];  % this is the user handle for range of percentage contribution of glucose

%%% For Model 3 only %%%%%%%%%%%
elongation=0; % 0 only runs model 1, 1 run both model 1 & 3
D_1_restriction=0; % 20180326 new handle for model 3; % D_1_restriction=1, then Model 3 will restrict D_1 according to D_0 and D_2
MC_successes=10; % only apply when elongation=1. the bigger the more accurate, but significantly slower, =5 if you have no idea
    %[str_Mod1_R, str_Mod1_C, str_Mod3_R, str_Mod3_C, str_MC_Stats]=Metabolism_Preprocess_UCLA(datafile,cutoff,q, MC_successes,sheets_2_compute, elongation,SaveFigs,SaveMCStats,lambda,user_p,min_lik_coefficient_LetJoeDecide)
min_lik_coefficient_LetJoeDecide=2;  % 2016.6.14when running Model 3, only when the new likelihood > 1.02*likelihood from Model 1 is called a success. otherwise it's marked "fail", and only 5 times of fails are allowed.
SaveFigs=0; % if =1 will save all the fancy images in the folder
SaveMCStats=0; % ignore this
%%%%% END User Interface %%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[datafiles,dir]=uigetfile('*.xls','select AUC data file','MultiSelect','on');
if (class(datafiles)=='char')
    temp={[]};
    temp{1}=datafiles;
    datafiles=temp;
end
%dir=uigetdir('','Select Folder for Save Data');
cd(dir);


for i=1:length(datafiles)
   
    datafile=datafiles{i}
    
    starting_time=clock();
    display(['starting time: ',num2str(starting_time)])
    Metabolism_Preprocess_UCLA(datafile,cutoff,q, MC_successes,sheets_2_compute, elongation,D_1_restriction, SaveFigs,SaveMCStats,lambda,user_p,min_lik_coefficient_LetJoeDecide);
    finishing_time=clock();
    display(['finishing_time: ',num2str(finishing_time)])
end












