function [out, biglist] = CleanData(action, tdata)
%
% to use call:
%
% cleaned = CleanData(rawdata);     % to clean the data without plotting
% cleaned = CleanData(rawdata,0);   % to clean the data without plotting
% cleaned = CleanData(rawdata,1);   % to clean the data with plotting
%
% rawdata is the original data of channels and time, in a 2-D matlab array.
% NOTE:	(1) a minimum of 3 channels is required
%			(2) the longer dimension of rawdata will be treated as time.
% cleaned is a 2-D array, [time,channels+2] of cleaned data. The last
% two columns returned are the first and second principal component vectors.
%
% CleanData.m will clean the data array using a principal
% component analysis to find common signal across channels
% and remove it.  Edit the initialized value of the global variables in this
% file appropriately to optimize cleaning of your data.
% Questions?  jeff@mulab.physiol.upenn.edu
%				george@mulab.physiol.upenn.edu

% to change the global values edit the values of the variables set in case('init'), 
%			a paragraph below
%
global biglist;			% internal use only
global ptitle;				% internal use only
global replacearray;		% internal use only
global orig;				% internal use only
global showData;			% internal use only
global ptspercut;			% number of points in a 'chunk' of data
global useSD;				% chooses method for spike detection 
global xsd;					% if using sd, this is the detection threshold
global highthresh;		% if not using sd, this is the high threshold
global lowthresh;			% if not using sd, this is the low threshold
global prepts;				% additional points before threshold detection to replace
global postpts;			% additional points after return under threshold to replace
global analogDisplayOffset;   % number of analog units by which to displace each trace 
										%		when displaying
global showWeights		% show weighting applied to pc vectors

% to change the global values edit the values of the variables set in case('init'), 
%				just a few lines below here

if ischar(action)
switch(action)
    
case('init')
  
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%  Edit these variables to modify the way the program cleans the data  %%%%
%%%%	Unless your conditions differ considerably, we recommend starting   %%%%
%%%%	with the values given here.                                         %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% ptspercut is the number of data points to analyze in a 'chunk'.  If the data
% passed to the program is larger than this number, the data will be analyzed
% in pieces, each of size ptspercut. If this number is very large there may be
% memory limitations which will slow down the computations. However, note also that spikes 
% falling EXACTLY on a cut may be distorted because the noise estimates and pca weights 
% may differ in the adjacent chunks. The number of spikes so affected is usually 
% negligible, but is smaller for long chunks. The problem can be completely eliminated
% by prewindowing the data around relevant stimulus or behavioral events, and doing
% a second slightly narrower windowing (by 5ms or so) after cleaning.
%
% We recommend analyzing in 1 second chunks to start; if necessary adjust the 
% ptspercut value to correspond with your sampling rate:
% ptspercut = 24414.0625;	
ptspercut = 1e64;

%useSD is a boolean to select the method by which spike events are initially
% determined.  If 'true', then the standard deviation of the analog signal will
% be used to detect putative spikes.  The calculation will be done for each chunk.
% Also if 'true', then the value of xsd will be used as the selection criterion. 
% If 'false', amplitude thresholds are used for spike detection (see below).
useSD='true';				% use sd of analog signal to detect spikes after first pass;
xsd = 2.5;  				% no of sd's that makes something a putative spike

% if useSD is 'false' (or any string but 'true') then thresholds will be used to
% detect putative spikes.  The values entered must be relative to the analog values
% of the data you pass.  For example, if the data passed is in uv, then you might
% use the threshold values below.  The values are 'or'ed, that is a putative spike
% will be selected if the analog value of a channel goes above the high threshold,
% OR below the low threshold.  You can change this logic by editing the code
% in the 'FindBigStuff' case.
highthresh = 100;			% used only if useSD is not 'true'; hi and lo are 'or'ed
lowthresh = -100;			% used only if useSD is not 'true'; hi and lo are 'or'ed

%The following two variables determine the duration of the putative spike to cut out and
% replace with a noise estimate.  Unless your sampling rate is considerably different
% than 25000/sec (or you are dealing with unusually long or short spikes) these values
% should be fine
prepts = 10;		% start point for replacement BEFORE spike detection time 
postpts = 10;		% end point for replacement AFTER RETURN UNDER (amplitude or sd) THRESHOLD

%If you choose to display the data, the program needs to know how far to offset each
% analog trace.  analogDisplayOffset is the variable that holds this value
analogDisplayOffset = 150;		% number of analog units by which to displace each trace
										%		when displaying

%showWeights prints out the weighting of the first two principal component for each
% analog channnel for each chunk analyzed.  The larger the number, the more noise has
% been removed from that channel
showWeights	='false';


%other modifications to the program are possible; the following gives you a hint of how the 
% program works:
%
%GetCleanedData contains the logic for the cleaning.  Look
%  at this case to figure out what is happening.
%
%FindBigStuff searches through the data for large events,
%  tentatively spikes.  Change the logic for what should be
%  considered a spike here.
%
%ReplaceBigStuff  Replaces the identified spikes with the 
%  noise estimate.
%
%PlotData  Displays the data and intermediates; edit this
%  code to change the way the data is displayed.
%
%ipca.m and pca2.m are two pca routines used by the program



case('GetCleanedData')
  
%%%%%%%%%%%%%%%%%% step 1: get the tdata %%%%%%%%%%%%%%%%%%%%%%
% check the tdata

if isempty(tdata)
  out = [];
  fprintf('Empty rawdata. Aborting.\n');
  return
end;  

[m,n] = size(tdata);

if n < 3
  out = [];
  fprintf('Rawdata must have at least 3 channels. Aborting.\n');
  return
end

if showData
  ptitle = 'raw';
  Neural.CleanData('PlotData',tdata);
end;


%%%%%%%%%%%%%%%%% step 2: pca the tdata %%%%%%%%%%%%%%%%%%%%%%%

pcadata = Neural.CleanData('pca2',tdata);		% get 1st cleaned estimate
pca12 = pcadata(:,[end-1 end]);			% last two columns are pca 1 and pca2
pcadata(:,[end-1 end]) = [];				% get rid of them for now
noiseEst = tdata - pcadata;				% get noise estimate
NoSpikesData = tdata;						% copy of tdata for noise replacement

if showData
  ptitle = '1st pca run';
  Neural.CleanData('PlotData', pcadata);

  ptitle = 'pca1 and pca2';
  Neural.CleanData('PlotData',pca12);
  
  ptitle = 'noise estimate';
  Neural.CleanData('PlotData',noiseEst);
end


%%%%%%%%%%%%%%%%% step 3: get list of putative spikes in tdata %%%%%%%%%%

% find spike times using pca cleaned tdata
biglist = Neural.CleanData('FindBigStuff',pcadata);   


%%%%%%%%%%%%%%%%% step 4: replace the spikes with the noise estimate %%%%%
% first use zeros to replace spikes
% to avoid cross contamination of noise estimate
% then replace spikes with noise estimate

replacearray = zeros(m,n);
NoSpikesData = Neural.CleanData('ReplaceBigStuff',tdata);
pcadata = Neural.CleanData('pca2',NoSpikesData);		% get 1st cleaned estimate
pca12 = pcadata(:,[end-1 end]);		% last two columns are pca 1 and pca2
pcadata(:,[end-1 end]) = [];		% get rid of them for now
noiseEst = NoSpikesData - pcadata;	% get noise estimate
replacearray = noiseEst;
NoSpikesData = Neural.CleanData('ReplaceBigStuff',tdata);	% now replace spikes with noise estimate


if showData
  ptitle = 'spikes removed';
  Neural.CleanData('PlotData',NoSpikesData);
end


%%%%%%%%%%%%%%%%% step 5: do second order cleaning %%%%%%
orig = tdata;
out = Neural.CleanData('itpca',NoSpikesData);

if showData
  ptitle = 'final result';
  Neural.CleanData('PlotData',out(:,1:end-2));
end





case('FindBigStuff')
% finds spikes in the tdata and outputs them in gdf format
% if you want to change the logic of what is a spike (for
% example, if you want to use a template) change this code.

% first get the sd of each channel (column)
if strcmp(useSD,'true')
  s = std(tdata);
end

% now put ones wherever the tdata falls below n sd's of 0;
spikelist = [];
[m,n] = size(tdata);
for i = 1:n
  times = [];
  
  if strcmp(useSD,'true')
    tdata(:,i) = (tdata(:,i) < -s(i)*xsd) | (tdata(:,i) > s(i)*xsd);
  else
    tdata(:,i) = (tdata(:,i) < lowthresh) | (tdata(:,i) > highthresh);
  end
  
  times = find(diff(tdata(:,i)) == 1);         % find the times of the first ones 
  times2 = find(diff(tdata(:,i)) == -1);         % find the times of the last ones 

  %if there are some save them
  if ~isempty(times)
    times(:,2) = i;
    if length(times2) == length(times(:,2))
      times(:,3) = times2;
    else
      if length(times2) == length(times(:,2))-1
        % end of tdata in the middle of a big spike
        times(1:end-1,3) = times2; 
        times(end,3) = tdata(end,i);  % last point is end of spike
      else
        % beginning of tdata in a big spike
        times(:,3) = times2(2:end);
        times = [ [ 1 times(1,2) times2(1) ]; times]; % first point is beginning of spike
      end  
      
    end
    spikelist = [spikelist; times(:,[2 1 3])]; % put stuff in the right column
    					             % and add to running total	
  end


end 


% output result
out = spikelist;
spikelist2=spikelist;
  
  
  
  
  
case('ReplaceBigStuff')
% replaces tdata at biglist with replacearray

if ~isempty(biglist)
 [m,n] = size(biglist);
 for i = 1:m  			
  atime = biglist(i,2);		% start time of big event
  btime = biglist(i,3);		% stop time of big event
  
  if (atime-prepts>0) a = prepts;	% no out of array errors
  else a = atime-1; end
  if (btime + postpts < length(tdata)) b = postpts;
  else b = length(tdata)-btime; end;
  
  % replace tdata points with replacearray estimate points
  tdata(atime-a:btime+b,biglist(i,1)) = ...
  	replacearray(atime-a:btime+b,biglist(i,1));
  	
 end
end

out = tdata;





case('PlotData')
% makes a figure with the title using tdata
% offsets each col by -100; 

figure ('Name', ptitle, 'NumberTitle', 'off');

[m,n] = size(tdata);

for i = 1:n
  tdata(:,i) = tdata(:,i) -(i-1)*analogDisplayOffset;
end
plot(tdata);
drawnow
zoom on





case('itpca')
%  tdata and orig are in columns

% subtract the mean from the tdata
ch=size(tdata,2);
M=mean(tdata);
for i=1:ch
  tdata(:,i)=tdata(:,i)-M(i);
end

C=cov(tdata);
for i=1:ch
  j=logical(ones(1,ch));
  j(i)=0;
  noti=tdata(:,j);     %subset of tdata not in channel i
  Cnoti=C(j,j);       %cov for those channels
  [v,d]=eig(Cnoti);
  [junk,k]=sort(diag(d));   % sorts according to eigenvalues
  v=v(:,k);d=d(:,k);        % rearrange v and d in this order
  v=v(:,[end end-1]);       % take principal components 1 and 2
  pc=noti*v;                % project tdata onto v
  pc=[pc,orig(:,i)];        % matrix of 2 pc's and orig ch of interest
  Cpc=cov(pc);              % the cov of this matrix
  a1(i)=Cpc(1,3)/Cpc(1,1);     
  a2(i)=Cpc(2,3)/Cpc(2,2);
    if i==1
    art=[a1(i)*pc(:,1),a2(i)*pc(:,2)];
  else 
    art=art+[a1(i)*pc(:,1),a2(i)*pc(:,2)];
  end 
  out2(:,i)=orig(:,i)-a1(i)*pc(:,1)-a2(i)*pc(:,2);
end
art=art/ch;
out = [out2,art];
if strcmp(showWeights,'true')
  fprintf('principle component weights for data columns 1 to %d\n',length(a1));
  fprintf('first pc   ');
  fprintf('%1.3f  ',a1);
  fprintf('\nsecond pc  ');
  fprintf('%1.3f  ',a2);
  fprintf('\n\n');
  %a1  % channel weights for first pc
  %a2  % channel weights for second pc
end





case('pca2')
%  out=pca(tdata)
%  tdata is in columns

% subtract the mean from the tdata
ch=size(tdata,2);
Mn=mean(tdata);
for i=1:ch
  tdata(:,i)=tdata(:,i)-Mn(i);
end

C=cov(tdata);
for i=1:ch
  j=logical(ones(1,ch));
  j(i)=0;
  noti=tdata(:,j);     %subset of tdata not in channel i
  Cnoti=C(j,j);       %cov for those channels
  [v,d]=eig(Cnoti);
  [junk,k]=sort(diag(d));   % sorts according to eigenvalues
  v=v(:,k);d=d(:,k);        % rearrange v and d in this order
  v=v(:,[end end-1]);       % take principle components 1 and 2
  pc=noti*v;                % project tdata onto v
  pc=[pc,tdata(:,i)];        % matrix of 2 pc's and ch of interest
  Cpc=cov(pc);              % the cov of this matrix
  a1(i)=Cpc(1,3)/Cpc(1,1);     
  a2(i)=Cpc(2,3)/Cpc(2,2);
  if i==1
    art=[a1(i)*pc(:,1),a2(i)*pc(:,2)];
  else 
    art=art+[a1(i)*pc(:,1),a2(i)*pc(:,2)];
  end 
  out(:,i)=tdata(:,i)-a1(i)*pc(:,1)-a2(i)*pc(:,2);
end
art=art/ch;
out=[out,art];
a1;	% channel weights for first pc
a2; % channel weights for second pc
  
end






else  

if exist('tdata')
  showData = tdata;
else
  showData = 0;		 		%don't plot data
end  
Neural.CleanData('init');
out = [];

data = action;
[m,n] = size(data);

% assume there are fewer data channels than there are time points!
if n > m
    data = data';
    [m,n] = size(data);
end
fprintf('Data contains %d channels of %d data pts.\n',n,m);

last = ceil(m/ptspercut); 	% analyze data in ptspercut pieces
dataLength = m;

for ci = 0:last-1
    if (ci+1)*ptspercut > dataLength;
        stop = dataLength;			% last piece is whatever is left
    else
        stop = (ci+1)*ptspercut;
    end
    
    cleaneddata = Neural.CleanData('GetCleanedData',data(ci*ptspercut+1:stop,:));
    
    out = [out; cleaneddata];
end

end