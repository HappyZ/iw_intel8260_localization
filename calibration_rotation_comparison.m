clear all;

folder = 'calibration_data/new_indoor/';

files = dir(folder); files = files(3:end);  % remove . and ..
files_left = files;
files_right = files;
targets = zeros(1, length(files));
for i = length(files):-1:1
    if contains(files(i).name, 'left') || contains(files(i).name, 'right')
        if contains(files(i).name, 'left')
            files_right(i) = [];
            % remove only once
            targets(i) = sscanf(files(i).name, 'result_%dcm.txt');
        else
            targets(i) = [];
            files_left(i) = [];
        end
    else
        files_right(i) = [];
        files_left(i) = [];
        targets(i) = [];
    end
end
for i = length(files):-1:1
    target = sscanf(files(i).name, 'result_%dcm.txt');
    if isempty(target)
        continue
    end
    if ~ismember(target, targets) || ...
            contains(files(i).name, 'left') || ...
            contains(files(i).name, 'right') || ...
            contains(files(i).name, 'ap') || ...
            contains(files(i).name, 'down') || ...
            contains(files(i).name, 'up')
        files(i) = [];
    end
end
[targets, orderI] = sort(targets);
files_left = files_left(orderI);
files_right = files_right(orderI);
files = files(orderI);

medians = zeros(3, length(targets));
figure(1); clf; 
subplot(2, 1, 1); hold on;
for i = 1:length(targets)
    % normal
    filename = [folder, files(i).name];
    data = readtable(filename, 'ReadVariableNames', 0);
    if isempty(data)
        continue
    end
    data = data(2:end, :);
    rawDist_ori = str2double(table2array(data(:, 5)))';
    rawDistVar_ori = str2double(table2array(data(:, 6)))';
    rssi_ori = str2double(table2array(data(:, 7)))';
    time_ori = str2double(table2array(data(:, 8)))';
    medians(1, i) = median(rawDist_ori);
    % left
    filename = [folder, files_left(i).name];
    data = readtable(filename, 'ReadVariableNames', 0);
    if isempty(data)
        continue
    end
    data = data(2:end, :);
    rawDist_left = str2double(table2array(data(:, 5)))';
    rawDistVar_left = str2double(table2array(data(:, 6)))';
    rssi_left = str2double(table2array(data(:, 7)))';
    time_left = str2double(table2array(data(:, 8)))';
    medians(2, i) = median(rawDist_left);
    % right
    filename = [folder, files_right(i).name];
    data = readtable(filename, 'ReadVariableNames', 0);
    if isempty(data)
        continue
    end
    data = data(2:end, :);
    rawDist_right = str2double(table2array(data(:, 5)))';
    rawDistVar_right = str2double(table2array(data(:, 6)))';
    rssi_right = str2double(table2array(data(:, 7)))';
    time_right = str2double(table2array(data(:, 8)))';
    medians(3, i) = median(rawDist_right);
    
    % plot rssi relation
    subplot(2, 1, 1);
    scatter(rawDist_ori, rssi_ori, 'ro');
    scatter(rawDist_left, rssi_left, 'cs');
    scatter(rawDist_right, rssi_right, 'b*');
end

subplot(2, 1, 1);
title('Signal propagation variation');
legend('Face2face', 'Left2Face', 'Right2Face', 'Location', 'best');
xlabel('Reported Raw Distance (cm)');
ylabel('RSSI (dBm)');

subplot(2, 1, 2); hold on;
title('Validation: No Significant Variation in Orientation :)');
scatter(targets, medians(1, :), 'ro', 'LineWidth', 2);
scatter(targets, medians(2, :), 'cs', 'LineWidth', 2);
scatter(targets, medians(3, :), 'b*', 'LineWidth', 2);
legend('Face2face', 'Left2Face', 'Right2Face', 'Location', 'best');
xlabel('Groundtruth (cm)');
ylabel({'(Median) Reported', 'Raw Distance (cm)'});