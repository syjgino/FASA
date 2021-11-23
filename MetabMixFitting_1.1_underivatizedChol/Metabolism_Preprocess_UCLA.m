%Moses's script
% 2016.04.12 by dylan: adding p_source, so that Joe could fix p0/1/2 for
%    VLC as same as 16:0
% 2015.06.26 by dylan: adding a lot more parameters
% 2015.08.25 by dylan: adding user_p
% 2021.11 Gino update to underivatized chol, line 149: dimention 35 to 30

function [str_Mod1_R, str_Mod1_C, str_Mod3_R, str_Mod3_C, str_MC_Stats]=Metabolism_Preprocess_UCLA(datafile,cutoff,q, MC_successes,sheets_2_compute, elongation, D_1_restriction,SaveFigs,SaveMCStats,lambda,user_p,min_lik_coefficient_LetJoeDecide, varargin)

%we ignore data below cutoff, it is a nX1 vector for the n species we are
%looking at
    StartRow=1;
 %dylan   
%dylan    dir=uigetdir('','Select Folder for Save Data');
%dylan    cd(dir);
    SaveFile1=['Results-Model1-',datafile];
    SaveFile3=['Results-Model3-',datafile];
    figdir1=[SaveFile1,' - Figures'];
    if(~exist(figdir1,'dir'))
            mkdir(figdir1);
    end

    display('Reading in data...')
    all=importdata(datafile); 
    lipids=fieldnames(all.data);  %Read in names of all sheets
    
    if(length(cutoff)<length(lipids));  %create buffer of cutoff is not enough are passed to the function
        cutoff(length(cutoff):length(lipids))=cutoff(length(cutoff));   %dylan: they will be all the same!
    end
    
    if(length(MC_successes)<length(lipids)); %create buffer of MC_successes is not enough are passed to the function
        MC_successes(length(MC_successes):length(lipids))=MC_successes(length(MC_successes));
    end
    
    if isempty(varargin)
        ENRICH=.99  %Default level % dylan they are replaced by enrich=0.99 outside, so never mind!
    else
        ENRICH=varargin{1}
    end

    
    
    %dylan: read in all the data files, identify the controls, and write 
    %the colnames and rownames to the outputfiles
    % this loop is for reading data and write blank files.
    for i= sheets_2_compute  %length(lipids) 
        eval(['temp=all.data.',lipids{i},';']); %dylan: smart way in matlab to execute sentences      
        
        %%%%% Dylan 2016.2.26 
        eval(['colnames=all.textdata.',lipids{i},'(1,:);']); %dylan: get colnames
        keep_col=find(~isnan(temp(1,:)))+1; 
        colnames=colnames(keep_col);                
        temp=temp(:,~isnan(temp(1,:))); % dylan: get rid of the columns that has no value
        
        code_col=strmatch('code',lower(colnames));
        code=temp(:,code_col);  % Dylan: get code according to header
        %%%%%%%%%%% 2016.4.12
        
        %code=temp(:,length(temp(1,:))); 
        
 
        numcontrols=sum(code==0); %
        numused=sum(code>=0);    
        %dylan: give the bothmodel function samplenames
        eval(['samplename=all.textdata.',lipids{i},';']);
        tempcode=[0;code];
        samplename=samplename(tempcode==1,1);
        %%dylan end of get samplenames
        
        temp_select=[temp(code==1,:); temp(code==0,:)];
        data=temp_select(:,1:(code_col-1));   % data is imported till the left of column of code, so you can do whatever beyond that haha
        %p_source=temp_select(:,strmatch('p_source',lower(colnames)));
        % read in p_s_e_user data %dylan 20170121
        p0_user=temp_select(:,strmatch('p0',lower(colnames)));
        p1_user=temp_select(:,strmatch('p1',lower(colnames)));
        p2_user=temp_select(:,strmatch('p2',lower(colnames)));
        s_user=temp_select(:,strmatch('s',lower(colnames)));
        e0_user=temp_select(:,strmatch('e0',lower(colnames)));
        e1_user=temp_select(:,strmatch('e1',lower(colnames)));
        e2_user=temp_select(:,strmatch('e2',lower(colnames)));
        e3_user=temp_select(:,strmatch('e3',lower(colnames)));
        e4_user=temp_select(:,strmatch('e4',lower(colnames)));
        e5_user=temp_select(:,strmatch('e5',lower(colnames)));
        if (isempty(p0_user))
           p0_user=zeros(numused,1)-1;
        end 
        if (isempty(p1_user))
           p1_user=zeros(numused,1)-1;
        end
        if (isempty(p2_user))
           p2_user=zeros(numused,1)-1;
        end
        if (isempty(s_user))
            s_user=zeros(numused,1)-1;
        end
        if (isempty(e0_user))
            e0_user=zeros(numused,1)-1;
        end
        if (isempty(e1_user))
            e1_user=zeros(numused,1)-1;
        end
        if (isempty(e2_user))
            e2_user=zeros(numused,1)-1;
        end
        if (isempty(e3_user))
            e3_user=zeros(numused,1)-1;
        end
        if (isempty(e4_user))
            e4_user=zeros(numused,1)-1;
        end
        if (isempty(e5_user))
            e5_user=zeros(numused,1)-1;
        end 
        p_s_e_user{i}=[p0_user,p1_user,p2_user,s_user,e0_user,e1_user,e2_user,e3_user,e4_user,e5_user];
        
        %if(numcontrols==0)
         %   data(numused+1,:)=binopdf(0:cols(data)-1,cols(data)-1,q);  %dylan: create a control if there is no control, use a default q value=0.0116. this is just for fatty acid! act there's no point in create a new distr
          %  numcontrols=1;
        %end
        % ok, now numcontrols can be 0
        controls{i}=numcontrols;
        datas{i}=data;
        codes{i}=code;
        samplenames{i}=samplename; %dylan 
      
        eval(['text=all.textdata.',lipids{i},';']);
        text(:,2:cols(text))=[];    %dylan:change '' to []
        text{1}=['''',text{1}]; %dylan:the corner
        plates{i}=text;
        warning('off','all');
        if ( elongation == 0 || elongation ==1 )
            xlswrite(SaveFile1,plates{i},lipids{i},['A',num2str(StartRow)]);
        end
        if (elongation>0)
            xlswrite(SaveFile3,plates{i},lipids{i},['A',num2str(StartRow)]);
        end
        warning('on','all');
    end 

    
    for i=sheets_2_compute
        %%assignin(ws, 'lipid',lipid{i} ); %dylan:  return the which lipid is being processed to the workspace
        temp=lower(lipids{i});
        display(['Computing fits for lipid: ', temp, '...'])
        if(~strcmp(temp(1:4),'chol')) %dylan: if we are looking at Fatty Acids
         %chi-chi:[Model1_results, Model1_colnames, Model3_results, Model3_colnames,MC_stats ] = BothModels(samplename,data,cutoff,num_controls,lipid,elongation,,p_s_e_user, MC_reps,min_lik_coefficient_LetJoeDecide,SaveFigs,q,varargin) % dylan added user_p parameter
         [Mod1_R, Mod1_C, Mod3_R, Mod3_C, MC_Stats] = BothModels(samplenames{i},datas{i},cutoff(i),controls{i},lipids{i},elongation,p_s_e_user{i},D_1_restriction,MC_successes(i),min_lik_coefficient_LetJoeDecide,SaveFigs,q,ENRICH); % calculate for FA data with the control in it
        else %dylan here we calculate chol, where model is slightly different
            choldat=[datas{i},zeros(rows(datas{i}),30-cols(datas{i}))]; %dylan: shit I don't have to do that much work for cholesterol! this will create a big zero matrix for that!
            % 2021.11 Gino change from 35 to 30 for underivatized chol
            [Mod1_R, Mod1_C]=Cholesterol_Automated_Batch(choldat,cutoff(i),controls{i},0,q,lambda,user_p, ENRICH); %dylan : added q to modeling function 0.99 is for testing the difference in enrichment don't d 0.99 for the screen
           %[Model_results, Model_colnames]=Cholesterol_Automated_Batch(data,cutoff,num_controls,SaveFigs,q,lambda,user_p,ENRICH)
            
            Mod3_R=[];
            Mod3_C=[];
        end
        
        %dylan: return to workspace
        %%assignin(ws, 'Mod1_R', Mod1_R);
        %%assignin(ws, 'Mod1_C', Mod1_C);
        %%assignin(ws, 'Mod3_R', Mod3_R);
        %%assignin(ws, 'Mod3_C', Mod3_C);       
        %%assignin(ws,'MC_Stats',MC_Stats);
        
        
        %%dylan
        %display('freezing the result data, hands off the computer!')
        
            
        code=codes{i};
        count=0;
        count_ctrl=0;
        clear dat_2_write1 dat_2_write3;
        temp_plates=plates{i};
        for j=1:length(code); 
            if(code(j)==1)
                count=count+1;
                if ( elongation ==0 || elongation ==1)
                  dat_2_write1(j,:)=Mod1_R(count,:);
                end 
                plates_2_use{count}=temp_plates{j+1};
                if(~isempty(Mod3_R))
                    dat_2_write3(j,:)=Mod3_R(count,:);
                end
            elseif(code(j)==0)
                count_ctrl=count_ctrl+1;
                if ( elongation ==0 || elongation ==1)
                    dat_2_write1(j,:)=Mod1_R(rows(Mod1_R)-controls{i}+count_ctrl,:);
                end
                if(~isempty(Mod3_R))
                    dat_2_write3(j,:)=Mod3_R(rows(Mod3_R)-controls{i}+count_ctrl,:);
                end
            else
                if ( elongation ==0 || elongation ==1)
                  dat_2_write1(j,:)=-1*ones(1,cols(Mod1_R));
                end
                if(~isempty(Mod3_R))
                    dat_2_write3(j,:)=-1*ones(1,cols(Mod3_R));
                end
            end
        end
        display('Writing Results...')
        Sheet=lipids{i};
        warning('off','all');
        if ( elongation ==0 || elongation ==1)
           xlswrite(SaveFile1,dat_2_write1,Sheet,['B',num2str(StartRow+1)]);
           xlswrite(SaveFile1,Mod1_C,Sheet,['B',num2str(StartRow)]);     %Write column header
        end
        
        if(~isempty(Mod3_R))
            xlswrite(SaveFile3,dat_2_write3,Sheet,['B',num2str(StartRow+1)]);
            xlswrite(SaveFile3,Mod3_C,Sheet,['B',num2str(StartRow)]);     %Write column header
           	%dylan
            if (SaveMCStats)
                   write_MCStats_tofile(['MCStats-',lipids{i},'-',datafile],MC_Stats,plates_2_use);
            end
        end
        warning('on','all');
    end
    
    display('Analysis finished!')
    
end     
    
function write_MCStats_tofile(SaveFile, MC_Stats, plates_2_use)
    colhead={'LogLik','p0','p1','p2','s','e0','e1','e2','e...'};
    rowhead={'max';'mean';'var';'Results';'...'}; 

    for i=1:length(plates_2_use)
        Sheet=plates_2_use{i};
        xlswrite(SaveFile,MC_Stats{i},Sheet,'B2');
        xlswrite(SaveFile,colhead,Sheet,'B1');     %Write column header
        xlswrite(SaveFile,rowhead,Sheet,'A2');
    end
end


