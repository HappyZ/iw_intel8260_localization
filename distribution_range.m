files0b = {}; files1f = {};
targets0b = []; targets1f = [];

% dataset A
folder = 'calibration_data/02222018_outdoor_500/';
files = dir(folder); files = files(3:end);  % remove . and ..
for i = length(files):-1:1
    if (~contains(files(i).name, 'result') ||...
            ~contains(files(i).name, 'extract') ||...
            contains(files(i).name, 'locs'))
        
    elseif contains(files(i).name, '34-f6-4b-5e-69-1f')
        files1f = [files1f, [folder, files(i).name]];
        loc = sscanf(files(i).name, 'result_static_%f_%f_extract.txt');
        targets1f = [targets1f, sqrt(sum((loc - [5;0]).^2)) * 100];
    else
        files0b = [files0b, [folder, files(i).name]];
        loc = sscanf(files(i).name, 'result_static_%f_%f_extract.txt');
        targets0b = [targets0b, sqrt(sum((loc - [0;0]).^2)) * 100];
    end
end

% dataset B
folder = 'calibration_data/02142018_outdoor_480/';
files = dir(folder); files = files(3:end);  % remove . and ..
for i = length(files):-1:1
    if (~contains(files(i).name, 'result') ||...
            ~contains(files(i).name, 'extract') ||...
            contains(files(i).name, 'locs'))
        
    elseif contains(files(i).name, '34-f6-4b-5e-69-1f')
        files1f = [files1f, [folder, files(i).name]];
        loc = sscanf(files(i).name, 'result_static_%f_%f_extract.txt');
        targets1f = [targets1f, sqrt(sum((loc - [4.8;0]).^2)) * 100];
    else
        files0b = [files0b, [folder, files(i).name]];
        loc = sscanf(files(i).name, 'result_static_%f_%f_extract.txt');
        targets0b = [targets0b, sqrt(sum((loc - [0;0]).^2)) * 100];
    end
end

% % dataset C
% folder = 'calibration_data/outdoor/';
% files = dir(folder); files = files(3:end);  % remove . and ..
% for i = length(files):-1:1
%     if (~contains(files(i).name, 'result'))
%         
%     else
%         files1f = [files1f, [folder, files(i).name]];
%         targets1f = [targets1f, sscanf(files(i).name, 'result_%dcm.txt')];
%     end
% end

[targets0b, orderI] = sort(targets0b);
files0b = files0b(orderI);
[targets1f, orderI] = sort(targets1f);
files1f = files1f(orderI);

all_data0b = [];
all_data1f = [];
% figure(1); clf; 
for i = 1:length(files0b)
    filename = files0b{i};
    
    fileID = fopen(filename, 'r');
    formatSpec = [...
        'Target: %x:%x:%x:%x:%x:%x, status: %d, ',...
        'rtt: %d psec, distance: %d cm\n'...
    ];
    data = fscanf(fileID, formatSpec, [9 Inf]);
    fclose(fileID);
    if isempty(data)
        data = readtable(filename, 'ReadVariableNames', 0);
        if isempty(data)
            continue
        end
        data = data(2:end, :);
        caliDist = str2double(table2array(data(:, 2)))';
        rawRTT = str2double(table2array(data(:, 3)))';
        rawRTTStd = sqrt(str2double(table2array(data(:, 4)))');
        rawDist = str2double(table2array(data(:, 5)))';
        rawDistStd = sqrt(str2double(table2array(data(:, 6)))');
        rssi = str2double(table2array(data(:, 7)))';
        time = str2double(table2array(data(:, 8)))';
        logistics = isnan(caliDist) | isnan(time);
    else
        % get rid of invalid data
        data(:, data(7, :) ~= 0) = [];
        data(:, data(9, :) < -1000) = [];
        rawDist = data(9, :);
        rawDistStd = zeros(size(rawDist));
        rssi = zeros(size(rawDist));
        caliDist = 0.8927 * rawDist + 553.3157;
        logistics = isnan(caliDist);
    end
    caliDist(logistics) = [];
    rssi(logistics) = [];
%     figure(1); cdfplot(caliDist);
    
    err = nanmedian(caliDist) - targets0b(i);
    fprintf(...
        '%.2f: rssi %.2f sig std %.2f dist std %.2f err %.2f\n',...
        targets0b(i), nanmedian(rssi), nanstd(rssi), nanstd(caliDist), err)
%     all_data0b = [all_data0b;...
%         [nanmedian(rssi), nanstd(rssi),...
%         nanmedian(rawDistStd), nanstd(rawDistStd), err]];
    all_data0b = [all_data0b, caliDist - targets0b(i)];
end
for i = 1:length(files1f)
    filename = files1f{i};
    
    fileID = fopen(filename, 'r');
    formatSpec = [...
        'Target: %x:%x:%x:%x:%x:%x, status: %d, ',...
        'rtt: %d psec, distance: %d cm\n'...
    ];
    data = fscanf(fileID, formatSpec, [9 Inf]);
    fclose(fileID);
    if isempty(data)
        data = readtable(filename, 'ReadVariableNames', 0);
        if isempty(data)
            continue
        end
        data = data(2:end, :);
        caliDist = str2double(table2array(data(:, 2)))';
        rawRTT = str2double(table2array(data(:, 3)))';
        rawRTTStd = sqrt(str2double(table2array(data(:, 4)))');
        rawDist = str2double(table2array(data(:, 5)))';
        rawDistStd = sqrt(str2double(table2array(data(:, 6)))');
        rssi = str2double(table2array(data(:, 7)))';
        time = str2double(table2array(data(:, 8)))';
        logistics = isnan(caliDist) | isnan(time);
    else
        % get rid of invalid data
        data(:, data(7, :) ~= 0) = [];
        data(:, data(9, :) < -1000) = [];
        rawDist = data(9, :);
        rawDistStd = zeros(size(rawDist));
        rssi = zeros(size(rawDist));
        caliDist = 0.8927 * rawDist + 553.3157;
        logistics = isnan(caliDist);
    end
    caliDist(logistics) = [];
    rssi(logistics) = [];
%     figure(1); cdfplot(caliDist - targets1f(i));
    
    err = nanmedian(caliDist) - targets1f(i);
    fprintf(...
        '%.2f: rssi %.2f sig std %.2f dist std %.2f err %.2f\n',...
        targets1f(i), nanmedian(rssi), nanstd(rssi), nanstd(caliDist), err)
%     all_data1f = [all_data1f;...
%         [nanmedian(rssi), nanstd(rssi),...
%         nanmedian(rawDistStd), nanstd(rawDistStd), err]];
    all_data1f = [all_data1f, caliDist - targets1f(i)];
end

figure(2); clf; hold on;
cdfplot(all_data0b); cdfplot(all_data1f);
hold off; legend('0b', '1f');
pd1f = fitdist(all_data1f', 'Normal');
pd0b = fitdist(all_data0b', 'Normal');
pd = fitdist([all_data0b, all_data1f]', 'Normal');

%  Normal distribution
%        mu = -5.77619   [-7.52889, -4.02349] <- measurement error
%     sigma =  52.8182   [51.6078, 54.0872]
% The sigma is consistent across observations in multiple ranging locations