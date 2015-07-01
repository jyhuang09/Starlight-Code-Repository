function varargout = Valve_Control(varargin)
% VALVE_CONTROL MATLAB code for Valve_Control.fig
%      VALVE_CONTROL, by itself, creates a new VALVE_CONTROL or raises the existing
%      singleton*.
%
%      H = VALVE_CONTROL returns the handle to a new VALVE_CONTROL or the handle to
%      the existing singleton*.
%
%      VALVE_CONTROL('CALLBACK',hObject,eventData,handl es,...) calls the local
%      function named CALLBACK in VALVE_CONTROL.M with the given input arguments.
%
%      VALVE_CONTROL('Property','Value',...) creates a new VALVE_CONTROL or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Valve_Control_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Valve_Control_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Valve_Control

% Last Modified by GUIDE v2.5 24-Feb-2015 22:11:44

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Valve_Control_OpeningFcn, ...
                   'gui_OutputFcn',  @Valve_Control_OutputFcn, ...
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
% --- Executes just before Valve_Control is made visible.
function Valve_Control_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to Valve_Control (see VARARGIN)

% Choose default command line output for Valve_Control
handles.output = hObject;
% Create video object
%   Putting the object into manual trigger mode and then
%   starting the object will make GETSNAPSHOT return faster
%   since the connection to the camera will already have
%   been established.

    global IA DeviceID Format  CAM
    global hImage VidObj
    IAHI=imaqhwinfo;
    IA=(IAHI.InstalledAdaptors);
    D=menu('Select Video Input Device:',IA);
    if isempty(IA)||D==0
        return
    end
    IA=char(IA);
    IA=IA(D,:);
    IA(IA==' ')=[];
    x=imaqhwinfo(IA);

    try
    DeviceID=menu('Select Device ID',x.DeviceIDs);
    F=x.DeviceInfo(DeviceID).SupportedFormats;
    nF=menu('Select FORMAT',F);
    Format=F{nF};
    catch e
        return
    end
    try
    VidObj = videoinput(IA, DeviceID, Format);
    handles.VidObj=VidObj;CAM=1;
    vidRes = get(handles.VidObj, 'VideoResolution');
    nBands = get(handles.VidObj, 'NumberOfBands');
    hImage = image( zeros(vidRes(2), vidRes(1), nBands) );
    
    preview(handles.VidObj, hImage)
    catch E
        msgbox({'Configure The Cam Correctly!',' ',E.message},'CAM INFO')
    end
handle.VidObj.FramesPerTrigger = Inf; % Capture frames until we manually stop it
% Update handles structure
guidata(hObject, handles);

% UIWAIT makes Valve_Control wait for user response (see UIRESUME)
uiwait(handles.figure1);
% --- Outputs from this function are returned to the command line.
function varargout = Valve_Control_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
handles.output = hObject;
varargout{1} = handles.output;


% Hello
function saveLocation()
    global loc_Database;
    global loc_Counter;
    global sObj;
    global numSites;
    if loc_Counter < numSites
        pos = sObj.readPosition();
        pos
        loc_Counter = loc_Counter + 1;
        loc_Database(:,loc_Counter) = pos;
        
    end
    loc_Database
    
function goToLocation(a)
    global sObj;
    global numSites;
    global loc_Database;
    if a<numSites
        sObj.moveToXY(loc_Database(1,a), loc_Database(2,a));
    end
    loc_Database(1,a)
    loc_Database(2,a)
    pause(1);
        
function resetLocation()
    global loc_Database;
    global loc_Counter;
    global numSites;
    numSites = 32;
    loc_Database = zeros(3,numSites);
    loc_Counter = 0;
    
    

%Over-arching Valve on/off function
function Valve_Switch(valve_id, handle)
    global wObj;
    if wObj.getValves(valve_id) == 0                %IF OFF TURN ON
        set(handle,'BackgroundColor',[0 1 0]);
        wObj.setValves(valve_id, 1);
    else
        set(handle,'BackgroundColor',[1 0 0]);
        wObj.setValves(valve_id, 0);
    end
    
% --- Executes on button press in Valve_0.
% --- Manual Control Layer
function Valve_0_Callback(hObject, eventdata, handles)
    Valve_Switch(0,handles.Valve_0)
function Valve_11_Callback(hObject, eventdata, handles)
    Valve_Switch(11,handles.Valve_11);
function Valve_12_Callback(hObject, eventdata, handles)
    Valve_Switch(12,handles.Valve_12);
function Valve_13_Callback(hObject, eventdata, handles)
    Valve_Switch(13,handles.Valve_13);
function Valve_14_Callback(hObject, eventdata, handles)
    Valve_Switch(14,handles.Valve_14);
    
% --- Override Control Layer
function Valve_1_Callback(hObject, eventdata, handles)
    Valve_Switch(1,handles.Valve_1)
function Valve_2_Callback(hObject, eventdata, handles)
    Valve_Switch(2,handles.Valve_2)
function Valve_3_Callback(hObject, eventdata, handles)
    Valve_Switch(3,handles.Valve_3)
function Valve_4_Callback(hObject, eventdata, handles)
    Valve_Switch(4,handles.Valve_4)
function Valve_5_Callback(hObject, eventdata, handles)
    Valve_Switch(5,handles.Valve_5)
function Valve_6_Callback(hObject, eventdata, handles)
    Valve_Switch(6,handles.Valve_6)
function Valve_7_Callback(hObject, eventdata, handles)
    Valve_Switch(7,handles.Valve_7)
function Valve_8_Callback(hObject, eventdata, handles)
    Valve_Switch(8,handles.Valve_8)
function Valve_9_Callback(hObject, eventdata, handles)
    Valve_Switch(9,handles.Valve_9)
function Valve_10_Callback(hObject, eventdata, handles)
    Valve_Switch(10,handles.Valve_10)

% --- Background Control Layer ---
function edit1_Callback(hObject, eventdata, handles)
% --- Executes during object creation, after setting all properties.
function edit1_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
delete(hObject);
delete(imaqfind);
% --- Executes on button press in startStopCamera.
function startStopCamera_Callback(hObject, eventdata, handles)
% hObject    handle to startStopCamera (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if strcmp(get(handles.startStopCamera,'String'),'Start Camera')
    % Camera is off. Change button string and start camera.
    set(handles.startStopCamera,'String','Stop Camera')
    preview(handles.VidObj);
    set(handles.startAcquisition,'Enable','on');
    set(handles.captureImage,'Enable','on');
else
         % Camera is on. Stop camera and change button string.
      set(handles.startStopCamera,'String','Start Camera');
      stoppreview(handles.VidObj);
      set(handles.startAcquisition,'Enable','off');
      set(handles.captureImage,'Enable','off');
end

%%%%%%%%%%%%%%%%% OVERARCHING FUNCTIONALITY WAGO %%%%%%%%%%%%%%%%%%%%%%%%%
    % --- Executes on button press in captureImage.
    % --- Executes on button press in Wago_Power.  &Note hardcoded
function Wago_Power_Callback(hObject, eventdata, handles)
    global numValves;
    global numSites;
    global wObj;
    global sObj;
    global n;
    global a;
    global valve_state_array;
    global loc_Database;
    global loc_Counter;
   
    a = 0;
    valve_state_array = zeros(2, n-1);
    if isempty(wObj)                        %Works
        disp(handles.Wago_Power)
        set(handles.Wago_Power,'BackgroundColor',[0 1 0]);
        set(handles.Wago_Power,'String','Wago ON');
        wObj = wagoNModbus('192.168.1.100', ones(1, 16));
        sObj = priorStage('COM3');
        numValves = 16;
        numSites = 16;
        n = log2(numSites);
        if floor(n) ~= n
            disp('Wrong number of sites, must be 2^n ... TERMINATING Function %n');
            quit();
        end
    else
        set(handles.Wago_Power,'BackgroundColor',[1 0 0]);
        set(handles.Wago_Power,'String','Wago OFF');
        for i=0:(numValves-1)
            if wObj.getValves(i) == 1       
                Valve_Switch(i,handles)
            end
        end
        wObj.close();
        clear all;
    end   
    loc_Database = zeros(3,numSites);
    loc_Counter = 0;
function captureImage_Callback(hObject, eventdata, handles)
function startAcquisition_Callback(hObject, eventdata, handles)
% hObject    handle to startAcquisition (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
if strcmp(get(handles.startAcquisition,'String'),'Start Acquisition')
      % Camera is not acquiring. Change button string and start acquisition.
      set(handles.startAcquisition,'String','Stop Acquisition');
      start(handles.VidObj);
else
      % Camera is acquiring. Stop acquisition, save video data,
      % and change button string.
      set(handles.startStopCamera,'String','Start Camera');
      stoppreview(handles.VidObj);
      set(handles.startAcquisition,'Enable','off');
      set(handles.captureImage,'Enable','off');
      stop(handles.VidObj);
      disp('Saving captured video...');
      videodata = getdata(handles.VidObj);
      save('testvideo.mat', 'videodata');
      disp('Video saved to file ''testvideo.mat''');
      start(handles.VidObj); % Restart the camera
      set(handles.startAcquisition,'String','Start Acquisition');
end
% --- Executes on button press in InitializeWago.
function InitializeWago_Callback(hObject, eventdata, handles)
% hObject    handle to InitializeWago (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    set(handles.InitializeWago,'BackgroundColor',[0 1 0]);
    set(handles.counter_update,'String', num2str(1));
    initializeTest(handles);
% --- Executes on button press in AdvanceWago.
function AdvanceWago_Callback(hObject, eventdata, handles)
% hObject    handle to AdvanceWago (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    set(handles.AdvanceWago,'BackgroundColor',[0 1 0]);
    currentCounterValue = str2double(get(handles.counter_update, 'String'));
    newString = sprintf('%d', int32(currentCounterValue + 1));
    set(handles.counter_update,'String', newString);
    advanceTest(handles);
% --- Executes on button press in ResetWago.

% --- Executes on button press in regressTest.
function regressTest_Callback(hObject, eventdata, handles)
% hObject    handle to regressTest (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    set(handles.regressTest,'BackgroundColor',[0 1 0]);
    regressTest(handles);
    currentCounterValue = str2double(get(handles.counter_update, 'String'));
    newString = sprintf('%d', int32(currentCounterValue - 1));
    set(handles.counter_update,'String', newString);
   
function ResetWago_Callback(hObject, eventdata, handles)
% hObject    handle to ResetWago (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    set(handles.InitializeWago,'BackgroundColor',[1 0 0]);
    set(handles.AdvanceWago,'BackgroundColor',[1 0 0]);
    set(handles.counter_update,'String', num2str(0));
    set(handles.all_close,'BackgroundColor', [1 0 0]);
    set(handles.regressTest,'BackgroundColor',[1 0 0]);
    reset(handles);
%%%%%%%%%%%%%%%%    
   
function updateStatus(handles)
    global valve_state_array;
    valve_state_array
    length(valve_state_array);
    for x = 1:2
        for y = 1:length(valve_state_array)
            if valve_state_array(x,y)==1
                set(handles.(strcat('Valve_',num2str(x * y))),'BackgroundColor', [0 1 0]);
            else
                set(handles.(strcat('Valve_',num2str(x * y))),'BackgroundColor', [1 0 0]);
            end
        end
    end  
function initializeTest(handles)
% Will initialize a as a global variable    
    global a;
    global wObj;
    global n;
    global valve_state_array;
    goToLocation(a+1);
    wObj.setValves([1:10], zeros(1,10));
    %%%%%%%%%%% Starting Cycle   %%%%%%%%%%%%%%
    % Set a 0 01 01 01 set Initial.
    for x = 1:n
        valve_state_array(2, x) = 1;
        wObj.setValves((2 * x), 1);
    end
    updateStatus(handles);
    a = a+1;   
    % Update Counter&&&&&&&&&&&&&&&&&&&&&&&&&
function advanceTest(handles)
    global a;
    global wObj;
    global n;
    global valve_state_array;
    % Switching Post Test. assume valve 1, 2, 3 ....
    % Havent implemented failsafe for beyond 10
    goToLocation(a+1);
    for b = 1:n                         % 1 - 3   b is pairs
        if floor(a / 2^(b-1)) == (a/2^(b-1))       %switch
           if valve_state_array(1, b) == 0

               valve_state_array(1, b) = 1;
               valve_state_array(2, b) = 0;

               wObj.setValves(2 * b - 1, 1);
               pause(.2);
               wObj.setValves(2 * b, 0);

           else
               valve_state_array(1, b) = 0;
               valve_state_array(2, b) = 1;

               wObj.setValves(2 * b - 1, 0);
               pause(1);
               wObj.setValves(2 * b, 1);
           end
        end
    end
    updateStatus(handles);
    a = a+1;

function regressTest(handles)
    global a;
    global wObj;
    global n;
    global valve_state_array;
    % Switching Post Test. assume valve 1, 2, 3 ....
    % Havent implemented failsafe for beyond 10
    a = a-1;
    goToLocation(a-1);
    for b = 1:n                         % 1 - 3   b is pairs
        if floor(a / 2^(b-1)) == (a/2^(b-1))       %switch
           if valve_state_array(1, b) == 0

               valve_state_array(1, b) = 1;
               valve_state_array(2, b) = 0;

               wObj.setValves(2 * b - 1, 1);
               pause(.2);
               wObj.setValves(2 * b, 0);

           else
               valve_state_array(1, b) = 0;
               valve_state_array(2, b) = 1;

               wObj.setValves(2 * b - 1, 0);
               pause(1);
               wObj.setValves(2 * b, 1);
           end
        end
    end
    updateStatus(handles);
    
function reset(handles)
    global wObj;
    global n;
    global valve_state_array;
    global a;
    valve_state_array = zeros(2,5)
    wObj.setValves([1:10], zeros(1,10));
    a = 0;
    updateStatus(handles);
    pause(1);  
% all close
function allClose()
    global wObj;
    global n;
    global valve_state_array;
    global a;
    wObj.setValves([1:10], ones(1,10));
    updateStatus(handles);    

function startIter()
    global a;
    numIter = 12*5*2;
    for x = 1:numIter
        for y = 1:3
            goToLocation(a+y);
            pause(3.965);
        end
    end


%%%%%%%%%%%%%%%%% OVERARCHING FUNCTIONALITY COUNTER %%%%%%%%%%%%%%%%%%%%%%%
function counter_update_Callback(hObject, eventdata, handles)
% --- Executes during object creation, after setting all properties.
function counter_update_CreateFcn(hObject, eventdata, handles)
% hObject    handle to counter_update (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in Exit_button.
function Exit_button_Callback(hObject, eventdata, handles)
    selection = questdlg('Are you sure you want to close the GUI?', 'Close Request', 'Yes', 'No', 'Yes');
    switch selection
        case 'Yes'
            global numValves;
            global wObj;
            for i=0:(numValves-1)
                    if wObj.getValves(i) == 1       
                        Valve_Switch(i,handles)
                    end
            end
            if isempty(wObj)
            else
                wObj.close();
            end
            clear all;
            close(Valve_Control);
        case 'No'
            return
    end
    
% --- Executes on button press in all_close.
function all_close_Callback(hObject, eventdata, handles)
% hObject    handle to all_close (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    allClose();
    set(handles.all_close,'BackgroundColor', [0 1 0]);
% --- Executes on button press in Save_Position.
function Save_Position_Callback(hObject, eventdata, handles)
    saveLocation();
    set(handles.Save_Position,'BackgroundColor', [0 0 1]);
    currentCounterValue = str2double(get(handles.loc_Counter, 'String'));
    newString = sprintf('%d', int32(currentCounterValue + 1));
    set(handles.loc_Counter,'String', newString);

function loc_Counter_Callback(hObject, eventdata, handles)
% --- Executes during object creation, after setting all properties.
function loc_Counter_CreateFcn(hObject, eventdata, handles)
% hObject    handle to loc_Counter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
% --- Executes on button press in Reset_Positions.
function Reset_Positions_Callback(hObject, eventdata, handles)
% hObject    handle to Reset_Positions (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
    currentCounterValue = str2double(get(handles.loc_Counter, 'String'));
    newString = sprintf('%d', int32(0));
    set(handles.loc_Counter,'String', newString);
    resetLocation();


% --- Executes on button press in Valve_15.
function Valve_15_Callback(hObject, eventdata, handles)
    Valve_Switch(15,handles.Valve_15);
% --- Executes on button press in Start_Iter_3.
function Start_Iter_3_Callback(hObject, eventdata, handles)
    startIter();
% hObject    handle to Start_Iter_3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

