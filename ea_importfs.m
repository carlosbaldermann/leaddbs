function ea_importfs(varargin)
% This function imports freesurfer cortical reconstruction files into 
% patient directory, and converts .pial files to cortex.mat
%
% External Dependencies:
%       mri_convert (Freesurfer)
% 
% Function:
% 1) Locate freesurfer directory
% 2) Save cortex.mat to patientdirectory
% __________________________________________________________________________________
% Copyright (C) 2017 University of Pittsburgh (UPMC), Brain Modulation Lab
% Ari Kappel

if isfield(varargin{1},'patdir_choosebox')
    
    handles = varargin{1};
    
    if strcmp(handles.patdir_choosebox.String,'Choose Patient Directory')
        ea_error('Please Choose Patient Directory');
    else
        ptdir = handles.patdir_choosebox.String;
    end
    
    tmp = strsplit(handles.patdir_choosebox.String,'/');
    patientname = tmp{end}; clear tmp

elseif isfield(varargin{1},'uipatdirs')
    
    options = varargin{1};
    
    ptdir = options.uipatdirs{1};
    patientname = options.patientname;

end

% Check if cortex.mat already exists
overwrite = '';
if exist([ptdir '/cortex/CortexHiRes.mat'],'file')
    overwrite = questdlg([{'Warning: There is already a cortex defined for this subject.'},
            {'Are you sure you want to overwrite the previous cortex?'}],'Import FreeSurfer folder');
end
if strcmp(overwrite,'No') || strcmp(overwrite,'Cancel')
    disp(['No cortex created in Patient Directory: ' ptdir '/cortex'])
    if ~exist([ptdir 'cortex/CortElecs.mat'],'file')
    qst = {'Do you have subdural electrode coordinates'; 'that you would like to import now?'};
    ImportElecsOption = questdlg(qst,'Import FS'); clear qst
    if strcmp(ImportElecsOption,'Yes')
        load([ptdir '/cortex/CortexHiRes.mat'])
        options.patientname = CortexHiRes.patientname;
        options.uipatdirs = CortexHiRes.ptdir;
        options.fsdir = CortexHiRes.fsdir;
        ea_importcorticalels(options)
    elseif strcmp(ImportElecsOption,'No') || strcmp(ImportElecsOption,'Cancel')
        return
    end
    end
return
end

% Choose Freesurfer Directory
FsDir = ea_uigetdir(ptdir,['Choose Freesurfer Folder for ' patientname]);
if iscell(FsDir) && length(FsDir)==1
    FsDir = char(FsDir);
else
    ea_error('Please choose one FS folder at a time')
end

%% Parse Freesurfer Folder
MriFile  = [FsDir '/mri/T1.mgz'];
LhPial   = [FsDir '/surf/lh.pial'];
RhPial   = [FsDir '/surf/rh.pial'];
AsegFile = [FsDir '/mri/aseg.mgz'];
AnnotLH  = [FsDir '/label/lh.aparc.a2009s.annot'];
AnnotRH  = [FsDir '/label/rh.aparc.a2009s.annot'];
% sAtlas.Name = 'Destrieux';

if ~exist(MriFile,'file')
    msg = ['Choose Freesurfer Folder for ' patientname ' (Missing ' patientname '_FS/mri/T1.mgz)...'];
    FsDir = ea_uigetdir(ptdir,msg); end
if ~exist(AsegFile,'file')
    msg = ['Choose Freesurfer Folder for ' patientname ' (Missing ' patientname '_FS/mri/aseg.mgz)...'];
    FsDir = ea_uigetdir(ptdir,msg); end
if ~exist(LhPial,'file')
    msg = ['Choose Freesurfer Folder for ' patientname ' (Missing ' patientname '_FS/surf/lh.pial)...'];
    FsDir = ea_uigetdir(ptdir,msg); end
if ~exist(RhPial,'file')
    msg = ['Choose Freesurfer Folder for ' patientname ' (Missing ' patientname '_FS/surf/rh.pial)...'];
    FsDir = ea_uigetdir(ptdir,msg); end
if ~exist(AnnotLH,'file')
    msg = ['Choose Freesurfer Folder for ' patientname ' (Missing ' patientname '_FS/label/lh.aparc.a2009s.annot)...'];
    FsDir = ea_uigetdir(ptdir,msg); end
if ~exist(AnnotRH,'file')
    msg = ['Choose Freesurfer Folder for ' patientname ' (Missing ' patientname '_FS/label/rh.aparc.a2009s.annot)...'];
    FsDir = ea_uigetdir(ptdir,msg); 
end

% Convert T1.mgz to T1.nii (Freesurfer Dependent)
if ~exist([FsDir '/mri/T1.nii'],'file')
    system(['mri_convert -i ' FsDir '/mri/T1.mgz ' -o ' FsDir '/mri/T1.nii -it mgz -ot nii'])
end
    % Notes: need to add PC functionality
    % Notes: need to add ea_libs_helper for Freesurfer compatibility

% Read Annotation Files
% external/freesurfer/read_annotation.m
 [vertices.lh, label.lh, colortable.lh] = read_annotation(AnnotLH);
 [vertices.rh, label.rh, colortable.rh] = read_annotation(AnnotRH);
    
%     AnnotLhFiles = {file_find(FsDir, 'lh.pRF.annot', 2), file_find(FsDir, 'lh.aparc.a2009s.annot', 2), file_find(FsDir, 'lh.aparc.annot', 2), file_find(FsDir, 'lh.BA.annot', 2), file_find(FsDir, 'lh.BA.thresh.annot', 2), file_find(FsDir, 'lh.aparc.DKTatlas40.annot', 2), ...
%                 file_find(FsDir, 'lh.PALS_B12_Brodmann.annot', 2), file_find(FsDir, 'lh.PALS_B12_Lobes.annot', 2), file_find(FsDir, 'lh.PALS_B12_OrbitoFrontal.annot', 2), file_find(FsDir, 'lh.PALS_B12_Visuotopic.annot', 2), file_find(FsDir, 'lh.Yeo2011_7Networks_N1000.annot', 2), file_find(FsDir, 'lh.Yeo2011_17Networks_N1000.annot', 2)};
% AnnotRhFiles = {file_find(FsDir, 'rh.pRF.annot', 2), file_find(FsDir, 'rh.aparc.a2009s.annot', 2), file_find(FsDir, 'rh.aparc.annot', 2), file_find(FsDir, 'rh.BA.annot', 2), file_find(FsDir, 'rh.BA.thresh.annot', 2), file_find(FsDir, 'rh.aparc.DKTatlas40.annot', 2), ...
%                 file_find(FsDir, 'rh.PALS_B12_Brodmann.annot', 2), file_find(FsDir, 'rh.PALS_B12_Lobes.annot', 2), file_find(FsDir, 'rh.PALS_B12_OrbitoFrontal.annot', 2), file_find(FsDir, 'rh.PALS_B12_Visuotopic.annot', 2), file_find(FsDir, 'rh.Yeo2011_7Networks_N1000.annot', 2), file_find(FsDir, 'rh.Yeo2011_17Networks_N1000.annot', 2)};
% AnnotLhFiles(cellfun(@isempty, AnnotLhFiles)) = [];
% AnnotRhFiles(cellfun(@isempty, AnnotRhFiles)) = [];

%% Create Hi Resolution Cortex
CortexHiRes.patientname = patientname;
CortexHiRes.ptdir = ptdir;
CortexHiRes.fsdir = FsDir;
   
disp('Loading reconstruction...')
% Read surface files
[CortexHiRes.Vertices_lh,CortexHiRes.Faces_lh]= read_surf(LhPial); % Reading left side pial surface
[CortexHiRes.Vertices_rh,CortexHiRes.Faces_rh]= read_surf(RhPial); % Reading right side pial surface

% Generate entire cortex
CortexHiRes.Vertices = [CortexHiRes.Vertices_lh; CortexHiRes.Vertices_rh]; % Combining both hemispheres
CortexHiRes.Faces = [CortexHiRes.Faces_lh; (CortexHiRes.Faces_rh + length(CortexHiRes.Vertices_lh))]; % Combining Faces

% freesurfer starts at 0 for indexing
CortexHiRes.Faces_lh=CortexHiRes.Faces_lh+1; 
CortexHiRes.Faces_rh=CortexHiRes.Faces_rh+1;
CortexHiRes.Faces=CortexHiRes.Faces+1;

% Reading in MRI parameters
f=MRIread(fullfile(FsDir,'mri/T1.nii'));

% Translating into the appropriate space
for k=1:size(CortexHiRes.Vertices,1)
    a=f.vox2ras/f.tkrvox2ras*[CortexHiRes.Vertices(k,:) 1]';
    CortexHiRes.Vertices(k,:)=a(1:3)';
end
%% Save Output to PatientDirectory/cortex/
if ~exist(fullfile(ptdir,'cortex'),'dir')
    mkdir(fullfile(ptdir,'cortex'))
end
    disp(['Saving to ' fullfile(ptdir,'cortex/CortexHiRes.mat') '...'])
    save(fullfile(ptdir,'cortex/CortexHiRes.mat'),'CortexHiRes')

%% Option to Downsample CortexHiRes
% newNbVertices = '15000';
qst = {'Would you like to downsample the high '; sprintf('resolution cortex with %d vertices?',size(CortexHiRes.Vertices,1))};
DownsampleOption = questdlg(qst,'Import FreeSurfer');

if strcmp(DownsampleOption,'Yes')
    
    newNbVertices = inputdlg({'Enter the number of vertices for low resolution cortex surface:'},...
        'Import FreeSurfer folder',1,{'15000'});
    newNbVertices = str2double(newNbVertices);
    oldNbVertices = size(CortexHiRes.Vertices,1);
    
    if isempty(newNbVertices) || isnan(newNbVertices) || newNbVertices==0
        disp(sprintf('Cortex not resampled, Hi Resolution only %d Vertices',size(CortexHiRes.Vertices,1)))
    else
        
        if (newNbVertices >= oldNbVertices)
            CortexLowRes = CortexHiRes;
            disp(sprintf('Cortex> Surface has %d vertices, cannot downsample to %d vertices.', oldNbVertices, newNbVertices));
            return;
        end
        
        nVertHemi = newNbVertices/2;
        CortexLowRes.patientname = CortexHiRes.patientname;
        CortexLowRes.ptdir = CortexHiRes.ptdir;
        CortexLowRes.fsdir = CortexHiRes.fsdir;
        
        disp(sprintf('Downsampling Cortex From %d Vertices to %d Vertices...',oldNbVertices,newNbVertices))
        [CortexLowRes.Vertices_lh, CortexLowRes.Faces_lh] = ea_downsamplecortex(CortexHiRes.Vertices_lh, CortexHiRes.Faces_lh, nVertHemi, 'reducepath');
        [CortexLowRes.Vertices_rh, CortexLowRes.Faces_rh] = ea_downsamplecortex(CortexHiRes.Vertices_rh, CortexHiRes.Faces_rh, nVertHemi, 'reducepath');
        [CortexLowRes.Vertices, CortexLowRes.Faces] = ea_downsamplecortex(CortexHiRes.Vertices, CortexHiRes.Faces, newNbVertices, 'reducepath');
        
    end
    disp(['Saving to ' fullfile(ptdir,'cortex/CortexLowRes.mat') '...'])
    save(fullfile(ptdir,'cortex/CortexLowRes.mat'),'CortexLowRes')
end

%% Import Cortical Electrodes
% Guarantee Options
options.patientname = patientname;
options.uipatdirs = ptdir;
options.fsdir = fsdir;

qst = {'Do you have subdural electrode coordinates'; 'that you would like to import now?'};
ImportElecsOption = questdlg(qst,'Import FS'); clear qst
if strcmp(ImportElecsOption,'Yes')
    ea_importcorticalels(options)
end

disp('Done')