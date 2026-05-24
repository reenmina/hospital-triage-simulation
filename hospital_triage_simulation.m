function hospital_triage_simulation()
clc;
clear;
close all;

% =========================
% INITIAL SYSTEM SETTINGS
% =========================

ICU_capacity = 2;
ER_capacity = 4;
FT_capacity = 5;

ICU_service_rate = 2;
ER_service_rate = 3;
FT_service_rate = 5;

ICU_queue = 0;
ER_queue = 0;
FT_queue = 0;

patientHistory = {};

% =========================
% GUI
% =========================

f = figure('Position',[100 100 1000 650],...
'Name','Emergency Department Simulation',...
'NumberTitle','off');

uicontrol(f,'Style','text',...
'Position',[30 590 200 30],...
'String','Patient Name',...
'FontSize',11);

nameBox = uicontrol(f,'Style','edit',...
'Position',[220 590 150 30]);

uicontrol(f,'Style','text',...
'Position',[30 540 200 30],...
'String','Severity Score (0-10)',...
'FontSize',11);

severityBox = uicontrol(f,'Style','edit',...
'Position',[220 540 150 30]);

uicontrol(f,'Style','text',...
'Position',[30 490 200 30],...
'String','Arrival Rate',...
'FontSize',11);

arrivalBox = uicontrol(f,'Style','edit',...
'Position',[220 490 150 30],...
'String','3');

uicontrol(f,'Style','pushbutton',...
'Position',[80 420 180 50],...
'String','Add Patient',...
'FontSize',12,...
'Callback',@addPatient);

uicontrol(f,'Style','pushbutton',...
'Position',[280 420 180 50],...
'String','Run Simulation',...
'FontSize',12,...
'Callback',@runSimulation);

patientTable = uitable(f,...
'Position',[30 120 420 260],...
'ColumnName',...
{'Patient','Severity','ESI'},...
'Data',{});

resultBox = uicontrol(f,'Style','listbox',...
'Position',[500 120 450 500],...
'FontSize',10);

% =========================
% ADD PATIENT
% =========================

function addPatient(~,~)

patientName = get(nameBox,'String');

severity = str2double(get(severityBox,'String'));

if isnan(severity)

errordlg('Invalid severity');

return;

end

if severity>=8
ESI=1;

elseif severity>=6
ESI=2;

elseif severity>=4
ESI=3;

elseif severity>=2
ESI=4;

else
ESI=5;

end

patientHistory(end+1,:)={...

patientName,...
severity,...
ESI};

set(patientTable,'Data',patientHistory);

set(nameBox,'String','');

set(severityBox,'String','');

end

% =========================
% RUN SIMULATION
% =========================

function runSimulation(~,~)

arrival_rate = str2double(get(arrivalBox,'String'));

rows=size(patientHistory,1);

if rows==0

errordlg('Add patients first');

return;

end

output={};

for i=1:rows

patientName=patientHistory{i,1};

severity=patientHistory{i,2};

ESI=patientHistory{i,3};

% =========================
% CONGESTION
% =========================

ICU_congestion = ICU_queue/ICU_capacity;

ER_congestion = ER_queue/ER_capacity;

FT_congestion = FT_queue/FT_capacity;

% FIXED: arrival rate now used

ICU_wait=(ICU_queue+arrival_rate)/ICU_service_rate;

ER_wait=(ER_queue+arrival_rate)/ER_service_rate;

FT_wait=(FT_queue+arrival_rate)/FT_service_rate;

% =========================
% UTILITY
% =========================

a = 0.7;
b = 0.2;
c = 0.1;

if severity >= 8

ICU_base = 10;
ER_base = 5;
FT_base = 1;

elseif severity >= 6

ICU_base = 7;
ER_base = 9;
FT_base = 2;

elseif severity >= 4

ICU_base = 3;
ER_base = 10;
FT_base = 5;

elseif severity >= 2

ICU_base = 1;
ER_base = 4;
FT_base = 9;

else

ICU_base = 1;
ER_base = 2;
FT_base = 10;

end

ICU_utility = ...
a*ICU_base ...
-b*ICU_wait ...
-c*ICU_congestion;

ER_utility = ...
a*ER_base ...
-b*ER_wait ...
-c*ER_congestion;

FT_utility = ...
a*FT_base ...
-b*FT_wait ...
-c*FT_congestion;

% =========================
% SOFTMAX
% =========================

expICU=exp(ICU_utility);

expER=exp(ER_utility);

expFT=exp(FT_utility);

total=expICU+expER+expFT;

P_ICU=expICU/total;

P_ER=expER/total;

P_FT=expFT/total;

probs=[P_ICU P_ER P_FT];

[~,idx]=max(probs);

if idx==1

assignedUnit='ICU';

ICU_queue=ICU_queue+1;

waitingTime=ICU_wait;

elseif idx==2

assignedUnit='ER';

ER_queue=ER_queue+1;

waitingTime=ER_wait;

else

assignedUnit='Fast Track';

FT_queue=FT_queue+1;

waitingTime=FT_wait;

end

% =========================
% DETERIORATION
% =========================

newSeverity=severity;

if waitingTime>2

newSeverity=severity+1;

end

if newSeverity>10

newSeverity=10;

end

% =========================
% UPDATED ESI
% =========================

if newSeverity>=8

updatedESI=1;

elseif newSeverity>=6

updatedESI=2;

elseif newSeverity>=4

updatedESI=3;

elseif newSeverity>=2

updatedESI=4;

else

updatedESI=5;

end

output=[output;

{['Patient : ' patientName]}

{['Severity : ' num2str(severity)]}

{['ESI : ' num2str(ESI)]}

{['Assigned : ' assignedUnit]}

{['Waiting : ' num2str(waitingTime)]}

{['Updated Severity : ' num2str(newSeverity)]}

{['Updated ESI : ' num2str(updatedESI)]}

{'----------------'}];

end

set(resultBox,'String',output);

figure('Name','Queue Status');

bar([ICU_queue ER_queue FT_queue]);

set(gca,...
'XTickLabel',...
{'ICU','ER','Fast Track'});

ylabel('Patients');

title('Queue Distribution');

end

end
