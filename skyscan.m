function  [out] = skyscan(in)
% SKYSCAN plots the data collected by UniMiB radiotelescope. You have to
% run filecleaner.sh BEFORE using this function.
%
%   in = skyscan returns the default setup as a struct. You have to edit
%   it to change the filename(s) you have to plot.
%
%   skyscan(in) runs the program with options in the "in" file
%
%   out = skyscan(in) returns trapz integrals on the rows
%
narginchk(0,1)

%% set defaults

%filesystem defaults
dflt.recur_over_folder=true;
dflt.filename='';
dflt.custom_directory='';

%graphic defaults
dflt.make_plot=true;
dflt.sample_module=1;
dflt.dedicated_figure_per_file=true;     %if false, one plot for all files
dflt.enable_browser=false;
dflt.silent_run=false;
dflt.export_png=true;

%% input handling and checks

if nargin == 0
    out = dflt;
    return;
end

% fill all missing fields from default
for fname = fieldnames(dflt)
    if ~isfield(in,fname)
        in.(fname) = dflt.(fname);
    end
end

% fill short-named variables

% filesystem reading
flist=[in.filename,""];                 % I need it to be an array
recr=in.recur_over_folder;
cudir=in.custom_directory;

% graphics reading
plot=in.make_plot;
dfpf=in.dedicated_figure_per_file;
brws=in.enable_browser;
smpl=in.sample_module;
slnt=in.silent_run;
epng=in.export_png;

%% Consistency checks

% Filesystem

if flist(1)==("")   % The user hasn't specified a filename
    if ~recr
        error("If you don't want to recur over a directory, you must specify a filename");
    return;
    end
else                % The user has specified a filename
    if recr
       warning("As you have specified a filename, recur will be set to false");
       recr=false;
    end
end

% Graphics (useful only if plot needed)

if plot
    
    % If only one file, rule will be autoset to dfpf=true
    
    if flist(1)~=("") && ~dfpf
       dfpf=true;
    end

    % sample ratio: as it can break the function if ill defined, the
    % function will always redefine it as a positive power of 2 guaranteed
    % to be well behaved

    if smpl <= 0
        smpl=1;
    else
        smpl=pow2(floor(log2(smpl)));
    end

    fprintf('The sample ratio has been rounded to the nearest smallest positive n^2 = %d\n',smpl);

    if smpl>8192
       disp('The given sampling ratio is bigger than the data set: it will be changed to 512');
       smpl=512;
    end

end

%% text files handling

if recr % Working on a directory
    if isempty(cudir)
        [cudir,~,~]=fileparts(mfilename('fullpath'));
        disp("You don't have specified a custom directory");
    end
    cd(cudir);
    fprintf('All the data files in %s will be analyzed\n', cudir);
    filefinder=dir('*_USRP.txt');
    flist=[filefinder.name,""];         %Weird workaround
end

% At this point i have an array of filenames

nfiles=size(flist,2)-1;
data=zeros(150,8195,nfiles);

for c=1:nfiles
        data(:,:,c)=importdata(flist(c),',');
end

% header=data(:,1:3,:); %Just in case they can prove useful
data(:,1:3,:)=[]; %Clean unwanted data

rows=size(data,1);
cols=size(data,2);

%At this point the function has loaded all the y data in a 3D matrix (2D if
%single file mode). It's faster than a cell but requires the memory
%allocated to be contiguos so it's probabily a bad idea to use with a lot
%of files, a lot definition depending by the RAM the computer has. The cell
%method would probably worth implementing only if it will be necessary to
%compare dozens of files. 

%% Managing X
% As provided by the lab guy, just copy-pasted.

x = 1:cols;
x = x*19531;
x = x + 1300001024;
x = (x - 19531);

%% Integral time

integral=zeros(nfiles,rows);
for k=1:nfiles
        integral(k,:)=trapz(data(:,:,k),2);
end
out = integral;
    
%% Plot time

if plot
    
    % ----- NEVER MOVE INTEGRAL BLOCK BELOW THIS IF -----
    if smpl>1
        x=x(1:smpl:end);
        data=data(:,1:smpl:end,:);
    end
    
    % This section shows some quite bad examples of using MATLAB. Be aware!
    
    if dfpf
        cmap=jet(rows);
        fig_lim=inf;
    else
        cmap=parula(nfiles);    
        fig_lim=1;
    end
    
    if slnt
        createfig=@silentfigure;
    else
        createfig=@loudfigure;
    end
    
    if epng
        mkdir('skyscan_png');
        addpath('skyscan_png');
        printfig=@exportpng;
    else
        printfig=@nothing2;
    end
    
    if brws
       is_brws=@plotlegend;
    else
       is_brws=@nothing3;           %Like this one
    end
    
    for c=1:nfiles
        if c<=fig_lim
            createfig(flist,c);
        end
        hold on
            y=data(:,:,c);
            l=line(x,y,'LineStyle','none','Marker','.');
            set(l, {'color'}, num2cell(cmap, 2));
        printfig(cudir,flist(c));
        is_brws(rows,flist,c);
        hold off
    end
  
    if fig_lim==1
        set(gcf,'Name','Multifile');
    end
    
end

function l=legendgenerator(sz,flist,c)
% LEGENDGENERATOR is useful for giving names in plotbrowser

flist=regexprep(flist, '_USRP.txt', '', 'lineanchors');
nmb=(1:sz)';
l=[];f
for k=1:c
    str=repmat(flist(k),[sz 1]);
    l=[l,strcat(str, {'  Line:'}, num2str(nmb))];
    %Preallocating would be better, but nevermind.
end

function plotlegend(sz,flist,c)
legend(legendgenerator(sz,flist,c));
plotbrowser;
legend('toggle')

function nothing2(~,~)
return;

function nothing3(~,~,~)
return;

function sname=silentfigure(flist,c)
figure('Name',flist(c),'Visible','off');
title(flist(c));

function loudfigure(flist,c)
figure('Name',flist(c));
title(flist(c));

function exportpng(cudir,name)
export_fig(sprintf('%s/skyscan_png/%s.png',cudir,name),'-png','-m1');