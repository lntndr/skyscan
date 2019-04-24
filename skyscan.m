function  [out] = skyscan(in)
% SKYSCAN plots the data collected by UniMiB radiotelescope. You have to
% run filecleaner.sh BEFORE using this function.
%
%   in = skyscan returns the default setup as a struct. You have to edit
%   it to change the filename(s) you have to plot.
%
%   skyscan(in) runs the program with options in the "in" file
%

narginchk(0,1)

%% set defaults

dflt.recur_over_folder=true;
dflt.filename='';
dflt.make_plot=true;
dflt.sample_module=1;
dflt.dedicated_figure_per_file=true;     %if false, one plot for all files
dflt.enable_browser=false;
dflt.custom_directory='';

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

% fill short-named variables + consistency checks

% file/directory reading
flist=[in.filename,""];                 % I need it to be an array
recr=in.recur_over_folder;
cudir=in.custom_directory;

% graphics
plot=in.make_plot;
dfpf=in.dedicated_figure_per_file;
brws=in.enable_browser;

% sample ratio: as it can break the function if ill defined, the function
% will always redefine it as a positive power of 2 guaranteed to be 
% well behaved

if in.sample_module <= 0
    smpl=1;
else
    smpl=pow2(floor(log2(in.sample_module)));
end

fprintf('The sample ratio has been rounded to the nearest smallest positive n^2 = %d\n',smpl);

if smpl>8192
   fprintf('The given sampling ratio is bigger than the data set: it will be changed to 512');
   smpl=512;
end

% Checks about recursion and file name

if ~recr && flist(1)==("")
    error("If you don't want to recur over a folder, you must specify a filename");
    return;
end

%% text files handling

if recr % Working on a directory
    if isempty(cudir)
        [cudir,~,~]=fileparts(mfilename('fullpath'));
    end
    cd(cudir);
    fprintf('All the data files in %s will be analyzed\n', cudir);
    try
        filefinder=dir('*_USRP.txt');
    catch
        disp("dir() has not found *_USRP.txt files in the directory");
        return;
    end
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

%At this point the function has loaded all the y data in a 3D matrix (2D if
%single file mode). It's faster than a cell but requires the memory
%allocated to be contiguos so it's probabily a bad idea to use with a lot
%of files, a lot definition depending by the RAM the computer has. The cell
%method would probably worth implementing only if it will be necessary to
%compare dozens of files. 

%% Managing X
% As provided by the lab guy, just copy-pasted.

x = 1:size(data,2);
x = x*19531;
x = x + 1300001024;
x = (x - 19531)';

%% Integral time

% To be written

%% Plot time

if plot
    
    if smpl>1
        x=x(1:smpl:end);
        data=data(:,1:smpl:end,:);
    end
    
    % This section shows some quite bad examples of using MATLAB. Be aware!
    
    sz=size(data,1);
    
    if dfpf
        cmap=jet(sz);
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
        for k=1:sz
            y=data(k,:,c);
            scatter(x,y,1,colorpicker(cmap,k,c));
        end
        hold off
        is_brws(sz*nfiles);
    end
  
    if fig_lim==1
        set(gcf,'Name','Multifile');
    end
    
end

function l=legendgenerator(num)
% LEGENDGENERATOR is useful for giving names in plotbrowser
%
%   l=legend(num) generates an array of num element in form 'Line 1' ...
nmb=(1:num)';
str=repmat('Line',[num 1]);
l=strcat(str, {' '}, num2str(nmb));

function plotlegend(num)
legend(legendgenerator(num));
plotbrowser;
legend('toggle')

function nothing(num)
return;

function color=dedi_picker(cmap,k,~)
color=cmap(k,:);

function color=multi_picker(cmap,~,c)
color=cmap(c,:);