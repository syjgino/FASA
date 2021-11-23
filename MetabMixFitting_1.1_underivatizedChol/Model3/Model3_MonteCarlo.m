function [b,stats,lik,result_mix]=Model3_MonteCarlo(data,weights,p_s_e_user_sample, D_1_restriction, tol, maxit, q, ENRICH, v, trials, min_lik,min_lik_coefficient_LetJoeDecide)
%                                 Model3_MonteCarlo(dat,weights, p_s_e_user_sample,D_1_restriction,10^-6, maxit, q,ENRICH, .015, MC_reps, liks(j),min_lik_coefficient_LetJoeDecide);
% 2018.03.26 Dylan: add "ENRICH" for Joe's D and 1-D iteration
% 2017.01.21 Dylan: add p_s_e_user_sample
% 2016.02.26 revised by Dylan to fix p 
    elongs=(length(data)-16)/2;  %number of possible elongations
    success=0;
    fails=0;
    while(success<trials && fails<5)
        %%%%%%%%% Get Seed p %%%%%%%%%%% 
        p0=zeros(1,3);
        p0(1)=rand;
        p0(2)=rand*(1-p0(1));
        p0(3)=1-sum(p0);
        p0=[.425,.025,.55]; % seed p is not random, it starts with a big p2
        %%%  Dylan fixing p0,p1,p2 for Joe
        fix_p=0;
        p_user_sample=p_s_e_user_sample(1:3); 
            p_user_sample(2)=1-p_user_sample(1)-p_user_sample(3);
        if ( sum(p_user_sample<=1 & p_user_sample>=0) ==3 )   % yes fix p
            fix_p=1;
            p0=p_user_sample;
        end
        
        %%%%%%%%% Get Seed s_e series %%%%%%%%%%% 
        e0=zeros(1,elongs+2); 
        for i=1:length(e0)-1
            e0(i)=rand()*(1-sum(e0));
        end
        e0(length(e0))=1-sum(e0);
        
        %%% Dylan: fixing s_e series for Joe
        s_e_user_sample=p_s_e_user_sample(4:10);  
        s_e_user_sample=s_e_user_sample(1:length(e0));
        s_e_fix_index=find(s_e_user_sample<=1 & s_e_user_sample>=0);
       
        %%%%% just for display
        parameters={'p012';'s';'e0';'e1';'e2';'e3';'e4';'e5'};
        fix_index=s_e_fix_index+1; 
            if (fix_p)
                fix_index=[1,fix_index];
            end
        if (~isempty(fix_index))
            fix_pa_display=[];
            for i=1:length(fix_index)
                fix_pa_display=[fix_pa_display,', ',parameters{fix_index}];
            end
            display(['fixed parameters:',fix_pa_display]);
        end
        %%%% end of display
            if ( sum (s_e_user_sample(s_e_fix_index))<0) 
                s_e_fix_index=[];
            end
        if (~isempty(s_e_fix_index))
            e0=zeros(1,elongs+2);             
            e0(s_e_fix_index)=s_e_user_sample(s_e_fix_index);
            
            s_e_unfix_index=setdiff(1:length(e0),s_e_fix_index);
             for i= 1:(length(s_e_unfix_index)-1)
                 e0(s_e_unfix_index(i))=rand()*(1-sum(e0));
             end
             e0(s_e_unfix_index(length(s_e_unfix_index)))=1-sum(e0);
          
        end
        %%%%%%%%% Combine p and  s_e series %%%%%%%%%%% 
        b0={p0,e0};
        [b,its,lik,mix]=NewModel_MLEFIT(data,weights,fix_p,s_e_fix_index,b0,D_1_restriction,tol,maxit,q,ENRICH,v);%v=0.015
        if(lik(its+1)>= (min_lik* min_lik_coefficient_LetJoeDecide))  % likelyhood: the bigger the better
            success=success+1;
            display(['Success=',num2str(success)]);
            fails=0;
            ps(success,:)=b{its+1,1};
            es(success,:)=b{its+1,2};
            liks(success)=lik(its+1);
        else
            fails=fails+1;
        end
        
    end
    if(success>0)
        best=find(liks==max(liks));
        if(length(best>1))
            best=best(1);
        end
        
        p=ps(best,:);
        elong=es(best,:);
        result_mix=elongation_distribution(q,p,elong);
        lik=-sum(weights.*((data/sum(data)-result_mix).^2)); %based on linear SD growth with AUC measures
        b={p,elong};
        if(success==1)
            stats=[lik,p,elong;liks,ps,es;zeros(1,6+elongs);liks',ps,es];
        else
            stats=[lik,p,elong;mean(liks),mean(ps),mean(es);var(liks),var(ps),var(es);liks',ps,es];
        end
    else
        p=zeros(1,3);
        elong=zeros(1,length(e0));
        result_mix=zeros(1,length(data));
        lik=-inf;
        b={p,elong};
        stats={[],[]};
    end
end