%Moses's script
% last update 2015.06.26 by dylan

function [str_Mod1_R, str_Mod1_C, str_Mod3_R, str_Mod3_C, str_MC_Stats]=Metabolism_Preprocess_UCLA(datafile,cutoff,q, MC_successes,sheets_2_compute, elongation,SaveFigs,SaveMCStats,lambda)

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

    %dylan: read in all the data files, identify the controls, and write
    %the colnames and rownames to the outputfiles
    for i=1:length(lipids)
        eval(['temp=all.data.',lipids{i},';']); %dylan: smart way in matlab to execute sentences
        temp=temp(:,~isnan(temp(1,:))); % dylan: get rid of the columns that has no value
        code=temp(:,length(temp(1,:)));
        
 
        numcontrols=sum(code==0); %
        numused=sum(code>=0);    
        %dylan: give the bothmodel function samplenames
        eval(['samplename=all.textdata.',lipids{i},';']);
        tempcode=[0;code];
        samplename=samplename(tempcode==1,1);
        %%dylan end of get samplenames
        
        data=[temp(code==1,1:length(temp(1,:))-1);temp(code==0,1:length(temp(1,:))-1)]; % dylan: rearrage the temp order, put the controls at the bottom of the matrix,get rid of the samples that was exluded
        
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
        xlswrite(SaveFile1,plates{i},lipids{i},['A',num2str(StartRow)]);
        if (elongation==1)
            xlswrite(SaveFile3,plates{i},lipids{i},['A',num2str(StartRow)]);
        end
        warning('on','all');
    end

    
    for i=sheets_2_compute
        %%assignin(ws, 'lipid',lipid{i} ); %dylan:  return the which lipid is being processed to the workspace
        display('Computing fits...')
        temp=lower(lipids{i});
        if(~strcmp(temp(1:4),'chol')) %dylan: this is for fatty acids
            [Mod1_R, Mod1_C, Mod3_R, Mod3_C, MC_Stats] = BothModels(samplenames{i},datas{i},cutoff(i),controls{i},lipids{i},elongation,MC_successes(i),SaveFigs,q,.99); % calculate for FA data with the control in it
        else %dylan here we calculate chol, where model is slightly different
            choldat=[datas{i},zeros(rows(datas{i}),35-cols(datas{i}))]; %dylan: shit I don't have to do that much work for cholesterol! this will create a big zero matrix for that!
            [Mod1_R, Mod1_C]=Cholesterol_Automated_Batch(choldat,cutoff(i),controls{i},0,q,lambda); %dylan : added q to modeling function
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
                dat_2_write1(j,:)=Mod1_R(count,:);
                plates_2_use{count}=temp_plates{j+1};
                if(~isempty(Mod3_R))
                    dat_2_write3(j,:)=Mod3_R(count,:);
                end
            elseif(code(j)==0)
                count_ctrl=count_ctrl+1;
                dat_2_write1(j,:)=Mod1_R(rows(Mod1_R)-controls{i}+count_ctrl,:);
                if(~isempty(Mod3_R))
                    dat_2_write3(j,:)=Mod3_R(rows(Mod3_R)-controls{i}+count_ctrl,:);
                end
            else
                dat_2_write1(j,:)=-1*ones(1,cols(Mod1_R));
                if(~isempty(Mod3_R))
                    dat_2_write3(j,:)=-1*ones(1,cols(Mod3_R));
                end
            end
        end
        display('Writing Results...')
        Sheet=lipids{i};
        warning('off','all');
        xlswrite(SaveFile1,dat_2_write1,Sheet,['B',num2str(StartRow+1)]);
        xlswrite(SaveFile1,Mod1_C,Sheet,['B',num2str(StartRow)]);     %Write column header
        

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





