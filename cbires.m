function varargout = cbires(varargin)
% CBIRES MATLAB code for cbires.fig
%      CBIRES, by itself, creates a new CBIRES or raises the existing
%      singleton*.
%
%      H = CBIRES returns the handle to a new CBIRES or the handle to
%      the existing singleton*.
%
%      CBIRES('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in CBIRES.M with the given input arguments.
%
%      CBIRES('Property','Value',...) creates a new CBIRES or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before cbires_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to cbires_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help cbires

% Last Modified by GUIDE v2.5 03-Jun-2020 11:39:09

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @cbires_OpeningFcn, ...
    'gui_OutputFcn',  @cbires_OutputFcn, ...
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


% --- Executes just before cbires is made visible.
function cbires_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to cbires (see VARARGIN)

% Choose default command line output for cbires
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes cbires wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = cbires_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in btn_BrowseImage.
function btn_BrowseImage_Callback(hObject, eventdata, handles)
% hObject    handle to btn_BrowseImage (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

[query_fname, query_pathname] = uigetfile('*.jpg', 'Select query image');

if (query_fname ~= 0)
    query_fullpath = strcat(query_pathname, query_fname);
    imgInfo = imfinfo(query_fullpath);
    [pathstr, name, ext] = fileparts(query_fullpath); % fiparts returns char type
        
    queryImage = imread( fullfile( pathstr, strcat(name, ext) ) );
    %         handles.queryImage = queryImage;
    %         guidata(hObject, handles);
    
    % extract query image features
    featureVector = [];
    queryImage = imresize(queryImage, [50 50]);
    %Convert into Lab
    C = makecform('srgb2lab');
    queryImage = applycform(queryImage,C);

    %Normalize between 0 and 1
    queryImage = double(queryImage);
    queryImage = queryImage/255;

    [rows cols channels] = size(queryImage);

    %Load fuzzy system
    %10 bins for FCH and 27 rules
    fismat = readfis('C:\Users\siddharth\Desktop\CBIR_projectfinal\59710\FuzzyHistogramLinking.fis');

    %Compute fuzzy-coloured image
    I_F = zeros(rows, cols);
    for r = 1:rows
        for c = 1:cols
            I_F(r,c) = evalfis(fismat,queryImage(r,c));
        end
    end
    featureVector = hist(reshape(I_F,1,rows*cols),10)/(rows*cols);
    featureVector=[featureVector str2num(name)];
    % update handles
    handles.queryImageFeature = featureVector;
    handles.img_ext = ext;
    handles.folder_name = pathstr;
    guidata(hObject, handles);
    helpdlg('Proceed with the query by executing the green button!');
    
    % Clear workspace
    clear('query_fname', 'query_pathname', 'query_fullpath', 'pathstr', ...
        'name', 'ext', 'queryImage', 'img', 'queryImageFeature', 'imgInfo');
else
    errordlg('You have not selected the correct file type');
end


% --- Executes on selection change in popupmenu_NumOfReturnedImages.
function popupmenu_NumOfReturnedImages_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu_NumOfReturnedImages (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu_NumOfReturnedImages contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu_NumOfReturnedImages

handles.numOfReturnedImages = get(handles.popupmenu_NumOfReturnedImages, 'Value');
guidata(hObject, handles);


% --- Executes during object creation, after setting all properties.
function popupmenu_NumOfReturnedImages_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu_NumOfReturnedImages (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in btnExecuteQuery.
function btnExecuteQuery_Callback(hObject, eventdata, handles)
% hObject    handle to btnExecuteQuery (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% check for image query
if (~isfield(handles, 'queryImageFeature'))
    errordlg('Please select an image first, then choose your similarity metric and num of returned images!');
    return;
end

% check for dataset existence
if (~isfield(handles, 'imageDataset'))
    errordlg('Please load a dataset first. If you dont have one then you should consider creating one!');
    return;
end

% set variables
if (~isfield(handles, 'numOfReturnedImages'))
    numOfReturnedImgs = get(handles.popupmenu_NumOfReturnedImages, 'Value');
else
    numOfReturnedImgs = handles.numOfReturnedImages;
end

simal(numOfReturnedImgs, handles.queryImageFeature, handles.imageDataset.dataset, handles.folder_name, handles.img_ext);


% --- Executes on button press in btnSelectImageDirectory.
function btnSelectImageDirectory_Callback(hObject, eventdata, handles)
% hObject    handle to btnSelectImageDirectory (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% select image directory
folder_name = uigetdir(pwd, 'Select the directory of images');
if ( folder_name ~= 0 )
    handles.folder_name = folder_name;
    guidata(hObject, handles);
else
    return;
end


% --- Executes on button press in btnCreateDB.
function btnCreateDB_Callback(hObject, eventdata, handles)
% hObject    handle to btnCreateDB (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if (~isfield(handles, 'folder_name'))
    errordlg('Please select an image directory first!');
    return;
end

% construct folder name foreach image type
jpgImagesDir = fullfile(handles.folder_name, '*.jpg');

% calculate total number of images
num_of_jpg_images = numel( dir(jpgImagesDir) );
totalImages = num_of_jpg_images;

jpg_files = dir(jpgImagesDir);

if ( ~isempty( jpg_files ) )
    % read jpg images from stored folder name
    % directory and construct the feature dataset
    jpg_counter = 0;
    for k = 1:totalImages
        
        if ( (num_of_jpg_images - jpg_counter) > 0)
            imgInfoJPG = imfinfo( fullfile( handles.folder_name, jpg_files(jpg_counter+1).name ) );
            if ( strcmp( lower(imgInfoJPG.Format), 'jpg') == 1 )
                % read images
                sprintf('%s \n', jpg_files(jpg_counter+1).name)
                % extract features
                image = imread( fullfile( handles.folder_name, jpg_files(jpg_counter+1).name ) );
                [pathstr, name, ext] = fileparts( fullfile( handles.folder_name, jpg_files(jpg_counter+1).name ) );
                image = imresize(image, [50 50]);
            end
            
            jpg_counter = jpg_counter + 1;
            
        end
        
        switch (ext)
            case '.jpg'
                imgInfo = imgInfoJPG;
        end
        
        if (strcmp(imgInfo.ColorType, 'truecolor') == 1)
            featureVector1=[];
            C1 = makecform('srgb2lab');
            image = applycform(image,C1);
            
            %Normalize between 0 and 1
            image = double(image);
            image = image/255;
            
            [rows1 cols1 channels1] = size(image);
            fismat = readfis('C:\Users\siddharth\Desktop\CBIR_projectfinal\59710\FuzzyHistogramLinking.fis');
            %Compute fuzzy-coloured image
            I_F1 = zeros(rows1, cols1);
            for r = 1:rows1
                for c = 1:cols1
                    I_F1(r,c) = evalfis(fismat,image(r,c));
                end
            end
            %imshow(I_F1)
            featureVector1 = hist(reshape(I_F1,1,rows1*cols1),10)/(rows1*cols1);
            set = featureVector1;
        end

        % add to the last column the name of image file we are processing at
        % the moment
        dataset(k, :) = [set str2num(name)];
        
        % clear workspace
        clear('image', 'img', 'set', 'imgInfoJPG', 'imgInfo');
    end
    
    % prompt to save dataset
    uisave('dataset', 'dataset1');
    save('dataset.mat', 'dataset', '-mat');
    clear('dataset', 'jpg_counter');
end


% --- Executes on button press in btn_LoadDataset.
function btn_LoadDataset_Callback(hObject, eventdata, handles)
% hObject    handle to btn_LoadDataset (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[fname, pthname] = uigetfile('*.mat', 'Select the Dataset');
if (fname ~= 0)
    dataset_fullpath = strcat(pthname, fname);
    [pathstr, name, ext] = fileparts(dataset_fullpath);
    
    if ( strcmp(lower(ext), '.mat') == 1)
        filename = fullfile( pathstr, strcat(name, ext) );
        handles.imageDataset = load(filename);
        guidata(hObject, handles);
        % make dataset visible from workspace
        % assignin('base', 'database', handles.imageDataset.dataset);
        helpdlg('Dataset loaded successfuly!');
    else
        errordlg('You have not selected the correct file type');
    end
else
    return;
end
