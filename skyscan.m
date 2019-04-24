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

%% Consistency checks

% Filesystem

if ~recr && flist(1)==("")
    error("If you don't want to recur over a directory, you must specify a filename");
    return;
end

if recr && flist(1)~=("")
    warning("As you have specified a filename, recur will be set to false");
    recr=false;
end    

% Graphics (useful only if plot needed)

if plot 

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
x = (x - 19531)';

%% Integral time

integral = zeros(rows,nfiles);
for k=1:nfiles
    for n=1:rows
        integral(n,k)=trapz(data(n,:));
    end
end
out = integral;
    
%% Plot time

if plot
    
    if smpl>1
        x=x(1:smpl:end);
        data=data(:,1:smpl:end,:);
    end
    
    % This section shows some quite bad examples of using MATLAB. Be aware!
    
    if dfpf
        cmap=jet(rows);
        colorpicker=@dedi_picker;
        fig_lim=inf;
    else
        cmap=parula(nfiles);    
        colorpicker=@multi_picker;
        fig_lim=1;
    end
    
    if brws
       is_brws=@plotlegend;
    else
       is_brws=@nothing;           %Like this one
    end
    
    for c=1:nfiles
        if c<=fig_lim
            figure('Name',flist(c));
        end
        hold on
        for k=1:rows
            y=data(k,:,c);
            scatter(x,y,1,colorpicker(cmap,k,c));
        end
        hold off
        is_brws(rows,flist,c);
    end
  
    if fig_lim==1
        set(gcf,'Name','Multifile');
    end
    
end

function l=legendgenerator(sz,flist,c)
% LEGENDGENERATOR is useful for giving names in plotbrowser

flist=regexprep(flist, '_USRP.txt', '', 'lineanchors');
nmb=(1:sz)';
l=[];
for k=1:c
    str=repmat(flist(k),[sz 1]);
    l=[l,strcat(str, {'  Line:'}, num2str(nmb))];
    %Preallocating would be better, but nevermind.
end

function plotlegend(sz,flist,c)
legend(legendgenerator(sz,flist,c));
plotbrowser;
legend('toggle')

function nothing(~,~,~)
return;

function color=dedi_picker(cmap,k,~)
color=cmap(k,:);

function color=multi_picker(cmap,~,c)
color=cmap(c,:);