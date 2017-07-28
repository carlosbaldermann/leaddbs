function varargout = ea_imageclassifier(varargin)
% EA_IMAGECLASSIFIER MATLAB code for ea_imageclassifier.fig
%      EA_IMAGECLASSIFIER, by itself, creates a new EA_IMAGECLASSIFIER or raises the existing
%      singleton*.
%
%      H = EA_IMAGECLASSIFIER returns the handle to a new EA_IMAGECLASSIFIER or the handle to
%      the existing singleton*.
%
%      EA_IMAGECLASSIFIER('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in EA_IMAGECLASSIFIER.M with the given input arguments.
%
%      EA_IMAGECLASSIFIER('Property','Value',...) creates a new EA_IMAGECLASSIFIER or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ea_imageclassifier_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ea_imageclassifier_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help ea_imageclassifier

% Last Modified by GUIDE v2.5 28-Jul-2017 11:05:06

% Begin initialization code - DO NOT EDIT
gui_Singleton = 0;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ea_imageclassifier_OpeningFcn, ...
                   'gui_OutputFcn',  @ea_imageclassifier_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
               
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before ea_imageclassifier is made visible.
function ea_imageclassifier_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ea_imageclassifier (see VARARGIN)

% Choose default command line output for ea_imageclassifier
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

set(hObject,'name','Please specify image type');


tmpoutdir=fileparts(varargin{1}{:});

setappdata(hObject,'dcfilename',varargin{1}{:});
setappdata(hObject,'tmpoutdir',tmpoutdir);

[~,dcfn]=fileparts(getappdata(handles.imclassf,'dcfilename'));
% check for already classified images:
for append=[0,2:15] % check for duplicates, too.
    [base_lead_fis,all_lead_fis]=ea_getbasefilenames('',append);
    % Check if file is an already sorted file:
    if ismember([dcfn,'.nii'],base_lead_fis)
        finishandclose(handles,'');
        return
    end
    
    if ismember([dcfn,'.nii'],all_lead_fis)
        finishandclose(handles,'');
        return
    end
    
    [pth,fi,ext]=fileparts([dcfn,'.nii']);
    if strcmp(fi(1:5),'anat_') && strcmp(ext,'.nii')
        finishandclose(handles,'');
        return
    end

    if append
        append=num2str(append);
    else
        append='';
    end
    
    if strcmp([dcfn,'.nii'],['ignore',append,'.nii'])
        finishandclose(handles,'');
        return
    end
    
    if strcmp([dcfn,'.nii'],['corrupt_data',append,'.nii'])
        finishandclose(handles,'');
        return
    end
    
    if strcmp([dcfn,'.nii'],['auto_ignore',append,'.nii'])
        finishandclose(handles,'');
        return
    end
end

try
    nii=ea_load_nii(getappdata(handles.imclassf,'dcfilename'));
catch
    finishandclose(handles,'corrupt_data');
    return
end

if any(nii.dim<25)
    finishandclose(handles,'auto_ignore');
    return
end

hdrtext=genhdrtext(nii);

nii.img=double(nii.img)/double(max(nii.img(:)));
try
    set(0,'CurrentFigure',handles.imclassf);
catch
    keyboard
end

%try
%     x=slice(double(squeeze(nii.img(:,:,:,1))),round(size(nii.img,1)/2),...
%     round(size(nii.img,2)/2),...
%     round(size(nii.img,3)/2));
    xsliceplot=slice3i(hObject,nii.img,nii.mat,1,round(size(nii.img,1)/2));
    ysliceplot=slice3i(hObject,nii.img,nii.mat,2,round(size(nii.img,2)/2));
    zsliceplot=slice3i(hObject,nii.img,nii.mat,3,round(size(nii.img,3)/2));
    
setappdata(hObject,'xsliceplot',xsliceplot);
setappdata(hObject,'ysliceplot',ysliceplot);
setappdata(hObject,'zsliceplot',zsliceplot);

%     set(xsliceplot,'FaceColor','interp',...
%         'EdgeColor','none',...
%         'DiffuseStrength',.8)
ht=uitoolbar(hObject);


% add custom rotator:
uibjs.rotate3dtog=uitoggletool(ht, 'CData', ea_get_icn('rotate'),...
    'TooltipString', 'Rotate 3D', 'OnCallback', {@ea_rotate,'on'},...
    'OffCallback', {@ea_rotate,'off'}, 'State', 'on');
uibjs.slide3dtog=uitoggletool(ht, 'CData', ea_get_icn('quiver'),...
    'TooltipString', 'Slide Slices', 'OnCallback', {@ea_slideslices,'on'},...
    'OffCallback', {@ea_slideslices,'off'}, 'State', 'off');
uibjs.magnifyplus=uitoggletool(ht,'CData',ea_get_icn('magnplus'),...
    'TooltipString', 'Zoom In', 'OnCallback', {@ea_zoomin,'on'},...
    'OffCallback', {@ea_zoomin,'off'}, 'State', 'off');
uibjs.magnifyminus=uitoggletool(ht, 'CData', ea_get_icn('magnminus'),...
    'TooltipString', 'Zoom Out', 'OnCallback', {@ea_zoomout,'on'},...
    'OffCallback', {@ea_zoomout,'off'}, 'State', 'off');
uibjs.handtog=uitoggletool(ht, 'CData', ea_get_icn('hand'),...
    'TooltipString', 'Pan Scene', 'OnCallback', {@ea_pan,'on'},...
    'OffCallback', {@ea_pan,'off'}, 'State', 'off');
setappdata(hObject,'uibjs',uibjs);


h = rotate3d;
h.RotateStyle = 'orbit';
h.Enable = 'on';

colormap gray
set(hObject, 'menubar', 'none' )
set(hObject, 'toolbar', 'none' )
warning('off')
set(hObject,'KeyPressFcn',{@ea_keystr,handles});
warning('on');
set(hObject,'Visible','off');
view(45,40)

axis equal
axis off

set(handles.imghdrinfo,'String',hdrtext);
set(handles.xres,'String',[num2str(nii.voxsize(1))]);
set(handles.xres,'ForegroundColor',res2col(nii.voxsize(1)));
set(handles.yres,'String',[num2str(nii.voxsize(2))]);
set(handles.yres,'ForegroundColor',res2col(nii.voxsize(2)));
set(handles.zres,'String',[num2str(nii.voxsize(3))]);
set(handles.zres,'ForegroundColor',res2col(nii.voxsize(3)));

if max(nii.voxsize)>4
    set(handles.recommendation,'String',['This volume seems not ideally suited for Lead-DBS  (=> Consider clicking "Ignore").']);
    set(handles.recommendation,'ForegroundColor',res2col(max(nii.voxsize)));
elseif max(nii.voxsize)>2
    set(handles.recommendation,'String',['This volume seems borderline suited for Lead-DBS (=> Consider ignoring if better acquisitions are available).']);
    set(handles.recommendation,'ForegroundColor',res2col(max(nii.voxsize)));
elseif max(nii.voxsize)>1
    set(handles.recommendation,'String',['This volume seems suited for Lead-DBS (=> Please assign the type of acquisition using the buttons below).']);
    set(handles.recommendation,'ForegroundColor',res2col(max(nii.voxsize)));
else
    set(handles.recommendation,'String',['This volume seems ideally suited for Lead-DBS (=> Please assign the type of acquisition using the buttons below).']);
    set(handles.recommendation,'ForegroundColor',res2col(max(nii.voxsize)));
end
% UIWAIT makes ea_imageclassifier wait for user response (see UIRESUME)
%uiwait(handles.imclassf);

function col=res2col(res)
if res>4
    col=[0.8,0.2,0.2];
elseif res>2
    col=[0.8,0.8,0.2];
elseif res>1
    col=[0.4,0.8,0.1];
else
    col=[0.2,0.8,0.2];
end

% --- Outputs from this function are returned to the command line.
function varargout = ea_imageclassifier_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
%uiwait(handles.imclassf);


% --- Executes on button press in trapush.
function trapush_Callback(hObject, eventdata, handles)
% hObject    handle to trapush (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
tmpoutdir=getappdata(handles.imclassf,'tmpoutdir');
[~,pt]=fileparts(tmpoutdir);
prefs=ea_prefs(pt);
finishandclose(handles,prefs.tranii_unnormalized);


% --- Executes on button press in pretrapush.
function pretrapush_Callback(hObject, eventdata, handles)
% hObject    handle to pretrapush (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
tmpoutdir=getappdata(handles.imclassf,'tmpoutdir');
[~,pt]=fileparts(tmpoutdir);
prefs=ea_prefs(pt);
finishandclose(handles,prefs.prenii_unnormalized);


% --- Executes on button press in corpush.
function corpush_Callback(hObject, eventdata, handles)
% hObject    handle to corpush (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
tmpoutdir=getappdata(handles.imclassf,'tmpoutdir');
[~,pt]=fileparts(tmpoutdir);
prefs=ea_prefs(pt);
finishandclose(handles,prefs.cornii_unnormalized);


% --- Executes on button press in sagpush.
function sagpush_Callback(hObject, eventdata, handles)
% hObject    handle to sagpush (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
tmpoutdir=getappdata(handles.imclassf,'tmpoutdir');
[~,pt]=fileparts(tmpoutdir);
prefs=ea_prefs(pt);
finishandclose(handles,prefs.sagnii_unnormalized);


% --- Executes on button press in ctpush.
function ctpush_Callback(hObject, eventdata, handles)
% hObject    handle to ctpush (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
tmpoutdir=getappdata(handles.imclassf,'tmpoutdir');

[~,pt]=fileparts(tmpoutdir);
prefs=ea_prefs(pt);
finishandclose(handles,prefs.rawctnii_unnormalized);


% --- Executes on button press in unknownpush.
function unknownpush_Callback(hObject, eventdata, handles)
% hObject    handle to unknownpush (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
finishandclose(handles,'ignore');


function ea_keystr(icfig,event,handles)
% pause
%commnd=get (handles.imclassf, 'CurrentKey');

% global current_imclass
%% get vars
eltog=getappdata(handles.imclassf,'eltog');
elplot=getappdata(handles.imclassf,'elplot');
coords_mm=getappdata(handles.imclassf,'coords_mm');

commnd=lower(event.Character);
switch commnd
    case 't'
        tmpoutdir=getappdata(handles.imclassf,'tmpoutdir');
        [~,pt]=fileparts(tmpoutdir);
        prefs=ea_prefs(pt);
        finishandclose(handles,prefs.tranii_unnormalized);
    case 'p'
        tmpoutdir=getappdata(handles.imclassf,'tmpoutdir');
        [~,pt]=fileparts(tmpoutdir);
        prefs=ea_prefs(pt);
        finishandclose(handles,prefs.prenii_unnormalized);
    case 's'
        tmpoutdir=getappdata(handles.imclassf,'tmpoutdir');
        [~,pt]=fileparts(tmpoutdir);
        prefs=ea_prefs(pt);
        finishandclose(handles,prefs.sagnii_unnormalized);
    case 'c'
        tmpoutdir=getappdata(handles.imclassf,'tmpoutdir');
        [~,pt]=fileparts(tmpoutdir);
        prefs=ea_prefs(pt);
        finishandclose(handles,prefs.cornii_unnormalized);
    case 'a'
        tmpoutdir=getappdata(handles.imclassf,'tmpoutdir');
        [~,pt]=fileparts(tmpoutdir);
        prefs=ea_prefs(pt);
        finishandclose(handles,prefs.rawctnii_unnormalized);
    case 'i'
        finishandclose(handles,'ignore');
    case 'd'
        tmpoutdir=getappdata(handles.imclassf,'tmpoutdir');
        [~,pt]=fileparts(tmpoutdir);
        prefs=ea_prefs(pt);
        finishandclose(handles,prefs.dti);
    case 'f'
        tmpoutdir=getappdata(handles.imclassf,'tmpoutdir');
        [~,pt]=fileparts(tmpoutdir);
        prefs=ea_prefs(pt);
        finishandclose(handles,prefs.rest_default);
    case '1'
        finishandclose(handles,'anat_t1.nii');
    case '2'
        finishandclose(handles,'anat_t2.nii');
    case '3'
        finishandclose(handles,'anat_pd.nii');
    case '4'
        finishandclose(handles,'anat_swi.nii');
    case '5'
        finishandclose(handles,'anat_flair.nii');
    case '6'
        finishandclose(handles,'anat_t2star.nii');
    case '7'
        finishandclose(handles,ea_getaltanatname);
    otherwise
        return
end

function name=ea_getaltanatname
name=inputdlg('Please enter a name for this acquisition (matching the anat_*.nii pattern)','Please enter name for alternative preoperative acquisition',1,{'anat_*.nii'});

function finishandclose(handles,current_imclass)
if ~isempty(current_imclass)
    [~,current_imclass]=fileparts(current_imclass); % remove potential file extension
    tmpoutdir=getappdata(handles.imclassf,'tmpoutdir');
    
    [~,pt]=fileparts(tmpoutdir);
    prefs=ea_prefs(pt);
    
    append='';
    while exist([tmpoutdir,filesep,current_imclass,append,'.nii'],'file')
        if isempty(append)
            append='2';
        else
            app=str2double(append);
            append=num2str(app+1);
        end
    end
    if ~isempty(append) && ~strcmp(current_imclass,'ignore');
       warndlg(['You have selected an image type that has already been assigned for this patient. This is not recommended and for now, Lead-DBS will store this file ',...
           'under the name "',current_imclass,append,'.nii". Please manually revise the files in the patient folder and decide which of the competing files is most suited. ',...
           'Then rename the best one of them to ',...
           '"',current_imclass,'.nii". Hint: The file with the largest file-size often has the best resolution.']);
    end
    movefile(getappdata(handles.imclassf,'dcfilename'),[getappdata(handles.imclassf,'tmpoutdir'),filesep,current_imclass,append,'.nii']);
    
    [~,dti]=fileparts(prefs.dti);
    if strcmp(dti,current_imclass)
        
        fufn=getappdata(handles.imclassf,'dcfilename');
        [pth,fn,ext]=fileparts(fufn);
        if exist([pth,filesep,fn,'.bval'],'file')
            movefile([pth,filesep,fn,'.bval'],[pth,filesep,prefs.bval]);
        else
            warning('No .bval file found for dMRI image.');
        end
        
        if exist([pth,filesep,fn,'.bvec'],'file')
            movefile([pth,filesep,fn,'.bvec'],[pth,filesep,prefs.bvec]);
        else
            warning('No .bvec file found for dMRI image.');
        end   
    end 
end

close(handles.imclassf)
        

% --- Executes on button press in restpush.
function restpush_Callback(hObject, eventdata, handles)
% hObject    handle to restpush (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
tmpoutdir=getappdata(handles.imclassf,'tmpoutdir');

[~,pt]=fileparts(tmpoutdir);
prefs=ea_prefs(pt);
finishandclose(handles,prefs.rest_default);


% --- Executes on button press in dtipush.
function dtipush_Callback(hObject, eventdata, handles)
% hObject    handle to dtipush (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
tmpoutdir=getappdata(handles.imclassf,'tmpoutdir');

[~,pt]=fileparts(tmpoutdir);
prefs=ea_prefs(pt);
finishandclose(handles,prefs.dti);


function hdrtxt=genhdrtext(nii)

[~,fn,ext]=fileparts(nii.fname);

hdrtxt = '';
hdrtxt = sprintf('%sFile: \n', hdrtxt);
hdrtxt = sprintf('%s%s\n', hdrtxt, [fn,ext]);
hdrtxt = sprintf('%s----------------------------------\n', hdrtxt);
hdrtxt = sprintf('%sDimension: %d x %d x %d\n', hdrtxt, nii.dim(1),nii.dim(2),nii.dim(3));
hdrtxt = sprintf('%sIntensity Range: %d - %d\n', hdrtxt, ea_nanmin(nii.img(:)),ea_nanmax(nii.img(:)));
hdrtxt = sprintf('%sNumber of Components: %d\n', hdrtxt, size(nii.img,4));
hdrtxt = sprintf('%sVox2mm:\n', hdrtxt);
hdrtxt = sprintf('%s %.2f %.2f %.2f %.2f\n', hdrtxt,nii.mat(1,1),nii.mat(1,2),nii.mat(1,3),nii.mat(1,4));
hdrtxt = sprintf('%s %.2f %.2f %.2f %.2f\n', hdrtxt,nii.mat(2,1),nii.mat(2,2),nii.mat(2,3),nii.mat(2,4));
hdrtxt = sprintf('%s %.2f %.2f %.2f %.2f\n', hdrtxt,nii.mat(3,1),nii.mat(3,2),nii.mat(3,3),nii.mat(3,4));
hdrtxt = sprintf('%s %.2f %.2f %.2f %.2f\n', hdrtxt,nii.mat(4,1),nii.mat(4,2),nii.mat(4,3),nii.mat(4,4));


% --- Executes on button press in pretrat1push.
function pretrat1push_Callback(hObject, eventdata, handles)
% hObject    handle to pretrat1push (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
tmpoutdir=getappdata(handles.imclassf,'tmpoutdir');

[~,pt]=fileparts(tmpoutdir);
prefs=ea_prefs(pt);
finishandclose(handles,prefs.prenii_unnormalized_t1);

% --- Executes on button press in pretrapdpush.
function pretrapdpush_Callback(hObject, eventdata, handles)
% hObject    handle to pretrapdpush (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

tmpoutdir=getappdata(handles.imclassf,'tmpoutdir');

[~,pt]=fileparts(tmpoutdir);
prefs=ea_prefs(pt);
finishandclose(handles,prefs.prenii_unnormalized_pd);


% --- Executes on button press in pretraswipush.
function pretraswipush_Callback(hObject, eventdata, handles)
% hObject    handle to pretraswipush (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
        finishandclose(handles,'anat_swi.nii');


% --- Executes on button press in pretraflairpush.
function pretraflairpush_Callback(hObject, eventdata, handles)
% hObject    handle to pretraflairpush (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
        finishandclose(handles,'anat_flair.nii');


% --- Executes on button press in pretrat2starpush.
function pretrat2starpush_Callback(hObject, eventdata, handles)
% hObject    handle to pretrat2starpush (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
        finishandclose(handles,'anat_t2star.nii');


% --- Executes on button press in pretraotherpush.
function pretraotherpush_Callback(hObject, eventdata, handles)
% hObject    handle to pretraotherpush (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
        finishandclose(handles,ea_getaltanatname);
