function  [out] = skyscan(in)
% SKYSCAN plots the data collected by UniMiB radiotelescope. You have to
% run filecleaner.sh BEFORE using this function.
%
%   in = skyscan returns the default setup as a struct. You have to edit
%   it to change the filename(s) you have to plot.
%
%   skyscan(in) returns the plot
%
%   [data] = skyscan(in) returns the integral of the collected data and the
%   plot if requested

narginchk(0,1)

%% set defaults

dflt.recur_over_folder=true;
dflt.filename='190416_121040_USRP.txt';
dflt.make_plot=true;
dflt.sample_module=1;
dflt.dedicated_figure_per_file=false;     %if false, one plot for all files


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

% fill short-named variables and perform some consistency check

file=in.filename;
recr=in.recur_over_folder;
plot=in.make_plot;
dfpf=in.dedicated_figure_per_file;
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

%% text files handling

if recr % Working on a directory
    [piru,~,~]=fileparts(mfilename('fullpath'));
    cd(piru);
    fprintf('All the data files in %s will be analyzed\n', piru);
    filefinder=dir('*_USRP.txt');
    flist=[filefinder.name,""];     %Weird workaround
    flist=flist(1:end-1)';
else % Working on a single file
    flist=dflt.filename;
end

nfiles=size(flist,1);

%% Moving data into MATLAB structures

data=zeros(150,8195,nfiles);
for c=1:nfiles
    data(:,:,c)=importdata(flist(c),',');
end
data(:,1:3,:)=[]; %Clean unwanted data

%% Managing X

x = 1:size(data,2);
x = x*19531;
x = x + 1300001024;
x = (x - 19531)';

%% Plot time

if plot
    
    if smpl>1
        x=x(1:smpl:end);
        data=data(:,1:smpl:end,:);
    end
    
    if dfpf
        cmap=parula(size(data,1));
        for c=1:nfiles
            figure('Name',flist(c));
            hold on
            for k=1:size(data,1)
                y=data(k,:,c);
                scatter(x,y,1,cmap(k,:));
            end
            legend(legendgenerator(size(data,1)));
            plotbrowser;
            legend('toggle')
            hold off
        end
    else
        cmap=parula(nfiles);
        figure('Name','Comparativa multifile')
        hold on
        for c=1:nfiles
            for k=1:size(data,1)
                y=data(k,:,c)';
                scatter(x,y,1,cmap(c,:));
            end
        end
        legend(legendgenerator(size(data,1)*nfiles));
        plotbrowser;
        legend('toggle')
        hold off
    end
end

function l=legendgenerator(num)
nmb=(1:num)';
str=repmat('Data',[num 1]);
l=strcat(str, {' '}, num2str(nmb));


