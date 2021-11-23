function val=fittowindow(val,window)
%window is a vector [a,b], with a<=b.  this function changes val to be in
%the closed interval [a,b] such that if val<a, val=a, and if val>b val=b;

if(val<window(1))
    val=window(1);
elseif(val>window(2))
    val=window(2);
end