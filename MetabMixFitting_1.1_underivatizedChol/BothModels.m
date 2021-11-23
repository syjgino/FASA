function [Model1_results, Model1_colnames, Model3_results, Model3_colnames,MC_stats ] = BothModels(samplename,data,cutoff,num_controls,lipid,elongation,p_s_e_user,D_1_restriction, MC_reps,min_lik_coefficient_LetJoeDecide,SaveFigs,q,ENRICH) % dylan added user_p parameter
%Version 1.1
%This is an automated version of "Model 1" and "Model 3" for Mass-Spec Stastistical
%Fitting.  Model 1 does not include elongation effects. Model 3 does
%
%it should be called as:
% BothModels(data,cutoff,num_controls,lipid,Elongation,MC_reps,SaveFigs, enrich)
%
%
%   "data"  should be a mXn matrix of AUC data for a given lipid species (i.e.
%        14:0,16:0,18:1d9,etc), where m is the number samples measured
%       (including controls), and n = (#carbons in lipid) + 2 (to account
%       for 0 labeling, and 1 extra label from the mass spec process.
%       ****************************************************************
%       *****Control measurements MUST be the last rows of data_i*****
%       ****************************************************************

%   "cutoff" is the AUC under which we ignore data in "data", if no extra
%   knowledge is known, cutoff should be set to -1.

%   "num_controls" is the number of control runs that are present in the
%   data matrix

%   "lipid" is a string of the lipid species used (i.e. '14.0', '16.0', etc)
%   **Lipid names must NOT contain these chars ":  \  /  ?  *  [  or  ]"**

%   "elongation" is a binary indicator [0,1] determining wether or not data
%   will be fit with Models 1 (elongation=0), or both models 1&3F
%   (elongation=1)

%   "SaveFigs" is a binary 0 or 1.  When set to 1, fitting results and
%   final grid search results are saved as .fig files in a subdirectory or
%   "saveFile" - not currently implemented

%   "enrich" is an optional parameter to set the carbon enrichment of the
%   labled glucose. Default enrichment is 98.4%

%%%%%%%%%%%
maxit=2000

%%%%%%%%%%%Set Enrichment Level%%%%%%%%%%%%%%%%
%{ 
if isempty(varargin)
    enrich=.984;  %Default level % dylan they are replaced by enrich=0.99 outside, so never mind!
else
    enrich=varargin{1}  %Specified level
end
%}
enrich=ENRICH
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%Bookkeeping%%%%%%%%%%%%%%%%%%%%%
scrsz = get(0,'ScreenSize');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    fitmix=zeros(size(data));
    [runs,isops]=size(data);
    runs=runs-num_controls;

    %Fit background C13 levels
    %dylan: modified priority
    %input: control distribution, output:estimated natural occuring q
    for j=1:num_controls
        tofit=data(j+runs,:)>cutoff;
        if(q==0)
            [qs(j),ci]=binofit_jeffreys(data(j+runs,:).*tofit,.05);
        else
            qs(j)=q;
        end
        fitmix(j+runs,:)=binopdf(0:(isops-1),isops-1,qs(j));
    end
    if(num_controls==0)
        if (q>0)
            qs=q;
        else
            q=0.0116;
            qs=q;
        end        
        fitmix(runs+1,:)=binopdf(0:cols(data)-1,cols(data)-1,q);
        num_controls=1;
    end
    
    q=mean(qs);
    display(['Background C13 levels for ',lipid,':'])
    display(qs); %dylan
    fprintf('q=%.6f \n', q)

    %%%%%%%%%%%%%%%%%%%%%%%%%%%
   if (elongation ==1 || elongation ==0)
        if(~exist('h','var'))
             h=figure('name','Grid Search','Position',[scrsz(3)-scrsz(4)/2-10 scrsz(4)/2-80 scrsz(4)/2 scrsz(4)/2]);
        end
   end
    if(~exist('h2','var'))
        h2=figure('name','Mixture Fitting', 'Position',[10 scrsz(4)/2-80 scrsz(3)/2 scrsz(4)/2]);
    end
    %dylan show both fitting
    if(elongation==1)
        if(~exist('h3','var'))
            h3=figure('name','Fitting_both_models', 'Position',[10 10 scrsz(3)/2 scrsz(4)/2-80]);
        end
    end
    %%%%%%%%%%Fit all cell lines
    if( elongation == 1 || elongation ==0) % dylan 20170814 skipping model 1
        
        if(~exist('h','var'))
             h=figure('name','Grid Search','Position',[scrsz(3)-scrsz(4)/2-10 scrsz(4)/2-80 scrsz(4)/2 scrsz(4)/2]);
        end
        
        display(['Model 1 results:']);    
        for j=1:(runs)
            %%dylan


            dat=data(j,:);

            set(0, 'CurrentFigure', h);
            title([lipid,' - Plate',num2str(j)]);

            [ps(j),ss(j),liks(j),fitmix(j,:)]=fit_metab_mix_auto(dat,q,cutoff,enrich);
            display(['Sample #',num2str(j),': q=',num2str(q),';     p=',num2str(ps(j)),'; s=',num2str(ss(j)),'; likelihood=',num2str(liks(j))]);
            Results_temp=[[q*ones(1,j)]',ps',ss',liks',fitmix(1:j,:)];
            save('temp_result.mat','Results_temp')


            if(SaveFigs)
                saveas(h,[lipid,' - Plate',num2str(j),' - Grid Search.fig']);
            end

            set(0, 'CurrentFigure', h2);
            plotmix(fitmix(j,:),dat);
            title([lipid,' - Plate',num2str(j)]);
            if(SaveFigs && elongation>0)
                saveas(h2,[lipid,' - Plate',num2str(j),' - Mixture Fit.fig']);
            end
        end
       %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%Add empty entries for excel buffer%%%%%%%%%%
        ps=[ps,zeros(1,num_controls)];
        ss=[ss,zeros(1,num_controls)];
        liks=[liks,zeros(1,num_controls)];
        %%%%%%%%%collect data to write to excel%%%%%%%%%%%%
        Model1_results=[[q*ones(1,runs),qs]',ps',ss',liks',fitmix];
        col_names={'q','p','s','log_lik','M+0'};
        for j=1:(isops-1);
            col_names{length(col_names)+1}=['M+',num2str(j)];
        end
        Model1_colnames=col_names;

        close(h);
    end
    
    if (elongation ==2 )
        display(['Model 1 skipped, running Model 3 using User set up s_e_p series']);    
    end
    
    %%%%%%%%%%%%%%%%%%%%%%% Fit with Model3 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    elongs=(isops-16)/2;  %number of possible elongations
    MC_stats=[];
    if(elongation>0)  %only fit with model 3 if elongation model is chosen
        result_ps=[];
        result_es=[];
        result_liks=[];
        result_mixs=zeros(runs,cols(data));        
     
        for j=1:(runs)  %dealing with one sample now
            dat=data(j,:);
            p_s_e_user_sample=p_s_e_user(j,:); %dylan
            weights=dat>cutoff;

            set(0, 'CurrentFigure', h2)
            title(['Model3 - ',lipid,' - Plate',num2str(j)])
            display([' ']);
            display(['Now running Sample # ',num2str(j)])
            %dylan: return to ws
            %assignin(ws, 'sample', [num2str(j),'-',samplename(j)]);
            %[b,stats,lik,result_mix]=Model3_MonteCarlo(data,weights,p_s_e_user_sample, tol, maxit, q, v, trials, min_lik,min_lik_coefficient_LetJoeDecide);
            
            if (elongation ==2)
                liks = -1* ones(1,runs);
            end
            [b,stats,lik,result_mixs(j,:)]=Model3_MonteCarlo(dat,weights, p_s_e_user_sample, D_1_restriction,10^-6, maxit, q, ENRICH, .015, MC_reps, liks(j),min_lik_coefficient_LetJoeDecide);
            MC_stats{j}=stats;
            
            result_ps(j,:)=b{1};
            result_es(j,:)=b{2};
            result_liks(j)=lik;
            
            %dylan: add the figure that has results from data, model1 and  %model3
            if (elongation==2) % added 20170828
                %if(SaveFigs)
                 %   saveas(h2,['Model3 - ',lipid,' - Plate',num2str(j),' - Gradient Ascent.fig']);
                %end
               
                set(0, 'CurrentFigure', h2);
                plotmix(result_mixs(j,:),dat);
                title([lipid,' - ',samplename(j)]);
                if(SaveFigs)
                  %  name=[lipid,' - Sample',num2str(j),'-',samplename(j),' - Both models.fig']
                  %  ~ischar(name) %debug
                  %  isempty(name) %debug
                  %DYLAN 20161201  saveas(h3,[pwd,'\',lipid,'\', lipid,' - Sample',num2str(j),' - Both models.fig']);
                    saveas(h2,[pwd,'\', lipid,' - Sample',num2str(j),'Mod3.fig']);
                    % saveas(figure(1),[pwd '/subFolderName/myFig.fig']);
                    saveas(h2,[lipid,' - Sample',num2str(j),'-',' Mod3.png']);
                end
            end
            
            %dylan: add the figure that has results from data, model1 and  %model3
            if (elongation==1)
                %if(SaveFigs)
                 %   saveas(h2,['Model3 - ',lipid,' - Plate',num2str(j),' - Gradient Ascent.fig']);
                %end
               
                set(0, 'CurrentFigure', h3);
                plotmix2(fitmix(j,:),result_mixs(j,:),dat);
                title([lipid,' - ',samplename(j)]);
                if(SaveFigs)
                  %  name=[lipid,' - Sample',num2str(j),'-',samplename(j),' - Both models.fig']
                  %  ~ischar(name) %debug
                  %  isempty(name) %debug
                  %DYLAN 20161201  saveas(h3,[pwd,'\',lipid,'\', lipid,' - Sample',num2str(j),' - Both models.fig']);
                    saveas(h3,[pwd,'\', lipid,' - Sample',num2str(j),' - Both models.fig']);
                    % saveas(figure(1),[pwd '/subFolderName/myFig.fig']);
                    saveas(h3,[lipid,' - Sample',num2str(j),'-',' - Both models.png']);
                end
            end
        end
        %%%%%%%%%%%%%%%%%Set up data to write to excel%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%Add empty entries for excel buffer%%%%%%%%%%
        result_ps=[result_ps;zeros(num_controls, 3)];
        result_es=[result_es;zeros(num_controls, 2+(length(dat)-16)/2)];
        result_liks=[result_liks,zeros(1,num_controls)];
        result_mixs=[result_mixs;fitmix(runs+1:runs+num_controls,:)];
        %%%%%%%%%%%%%%%%%%%%%%%%
        Model3_results=[[q*ones(runs,1);qs'],result_ps,result_es, -1*ones(runs+num_controls,(5-elongs)),result_liks',result_mixs];
        col_names={'q','p0','p1','p2','s','e0','e1','e2','e3','e4','e5'};
        col_names{length(col_names)+1}='log_lik';
        for k=1:cols(data);
            col_names{length(col_names)+1}=['M+',num2str(k-1)];
        end
        Model3_colnames=col_names;
        
        if (elongation==1)
            close(h3)
        end
    else
        Model3_results=[];
        Model3_colnames=[];
    end
    close(h2)
    
    if (elongation ==2 )
        Model1_results=[];
        Model1_colnames=[];
    end
    
end


function plotmix(fitmix,dat)
    bar([dat'/sum(dat),fitmix']);
    legend('Real Data','Model 1.5')
    ylabel('AUC Percentage')
    xlabel('Extra Mass Units')
    set(gca,'XTick',1:length(dat))
    labels={'0'};
    for i=1:length(dat)-1
        labels{i+1}=num2str(i);
    end
    set(gca,'XTickLabel',labels)
end

function plotmix2(fitmix1,fitmix2,dat)
    bar([dat'/sum(dat),fitmix1',fitmix2']);
    legend('Real Data','Model 1.5', 'Model 3.5')
    ylabel('AUC Percentage')
    xlabel('Extra Mass Units')
    set(gca,'XTick',1:length(dat))
    labels={'0'};
    for i=1:length(dat)-1
        labels{i+1}=num2str(i);
    end
    set(gca,'XTickLabel',labels)
end


%plotmix2(fitmix(j,:),result_mixs(j,:),dat);