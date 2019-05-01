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
dflt.filenames="";
dflt.custom_directory="";

%graphic defaults
dflt.make_plot=true;
dflt.dedicated_figure_per_file=true;     %if false, one plot for all files
%dflt.browser=false;
dflt.silent_run=false;
dflt.export_png=true;
dflt.output_dir="";

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
flst=[in.filenames,""];                 % I need it to be an array
recr=in.recur_over_folder;
cdir=in.custom_directory;

% graphics reading
plot=in.make_plot;
dfpf=in.dedicated_figure_per_file;
%brws=in.browser;
slnt=in.silent_run;
epng=in.export_png;
odir=in.output_dir;

%% Consistency checks
% Filesystem

if flst(1)==("")   % The user hasn't specified a filename
    if ~recr
        error("If you don't want to recur over a directory, you must specify a filename");
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
    
    if flst(1)~=("") && ~dfpf
       dfpf=true;
    end

end

%% text files handling

if recr % Working on a directory
    if cdir==("")
        [cdir,~,~]=fileparts(mfilename('fullpath'));
        disp("You don't have specified a custom data directory");
    end
    cd(cdir);
    fprintf('All the data files in %s will be analyzed\n', cdir);
    filefinder=dir('*_USRP.txt');
    flst=[filefinder.name,""];         %Weird workaround
end

% At this point I have an array of filenames

nfiles=size(flst,2)-1;
% ?Ask the user if sure about running verbose if nfiles>10?
data=zeros(150,8195,nfiles);
tic;
for c=1:nfiles
        try
            data(:,:,c)=importdata(flst(c),',');
        catch
            fprintf("%s can't be read. Probabily has less than 150 sloc\n",flst(c));
        end
end
% header=data(:,1:3,:); %Just in case they can prove useful
data(:,1:3,:)=[]; %Clean unwanted data
fprintf('Data correctly retrieved in %d s\n',toc);

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
tic;
integral=zeros(nfiles,rows);
for k=1:nfiles
        integral(k,:)=trapz(data(:,:,k),2);
end
out = integral;
fprintf('Integrals evaluated in %d s\n',toc);
%% Plot time

if plot
    
    % This section shows some quite bad examples of using MATLAB. Be aware!
    
    %% plot checks
    
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
        if odir==("")
            disp("You don't have specified a custom output folder");
            odir=cdir;
        end
        subf=strcat('skyscan_png_',datestr(datetime,'yy-mm-dd_HH-MM-SS'));
        mkdir(subf);
        printfig=@exportpng;
    else
        printfig=@nothing3;         %Like this one
    end
    
%     if brws
%        is_brws=@plotlegend;
%     else
%        is_brws=@nothingN;           %Like this one
%     end
    
    %% main plot
    
    for c=1:nfiles
        
        if c<=fig_lim
            createfig(flst,c);
            title(flst(c),'Interpreter','none');
            % labels
        end
        
        y=data(:,:,c);
        
        hold on;
        
        l=line(x,y,'LineStyle','none','Marker','.');
        
        if dfpf         %I have to find a better way
            set(l, {'color'}, num2cell(cmap, 2));
        else
            set(l, 'color', cmap(c,:));
        end
        
        xlim([x(1),x(end)]);
        % ?Add ylim?
        printfig(odir,flst(c),subf);
        %is_brws(rows,flst,c,dfpf); %<<<BROWSER
        hold off
    end
  
    if fig_lim==1
        set(gcf,'Name','Multifile');
        title('Multifile');
    end
    
    % Return to .m directory
    %[cdir,~,~]=fileparts(mfilename('fullpath'));
    %cd(cdir);
    
end

function nothing3(~,~,~)
return;

function silentfigure(flist,c)
figure('Name',flist(c),'Visible','off');

function loudfigure(flist,c)
figure('Name',flist(c));

function exportpng(cudir,name,subf)
[~,name,~]=fileparts(name);
saveas(gcf,strcat(cudir,'/',subf,'/',name,'.png'));