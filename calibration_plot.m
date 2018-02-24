% clear all; %close all;
param_linear = [0.8927, 553.3157];
folder = 'calibration_data/outdoor/';
files = dir(folder); files = files(3:end);  % remove . and ..
targets = zeros(1, length(files));
for i = length(files):-1:1
    if (~contains(files(i).name, 'result') ||...
            contains(files(i).name, 'left') ||...
            contains(files(i).name, 'right') ||...
            contains(files(i).name, 'ap') ||...
            contains(files(i).name, 'down') ||...
            contains(files(i).name, 'up'))
        files(i) = [];
        targets(i) = [];
    else
        targets(i) = sscanf(files(i).name, 'result_%dcm.txt');
    end
end
[targets, orderI] = sort(targets);
files = files(orderI);

median_result = zeros(1, length(files));
mean_result = zeros(1, length(files));
median_rssi = zeros(1, length(files));
median_diststd = zeros(1, length(files));
all_data = [];
figure(1); clf; hold on;
% figure(2); clf; hold on;
for i = 1:length(files)
    filename = [folder, files(i).name];

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
        rawRTTVar = str2double(table2array(data(:, 4)))';
        rawDist = str2double(table2array(data(:, 5)))';
        rawDistVar = str2double(table2array(data(:, 6)))';
        rssi = str2double(table2array(data(:, 7)))';
        time = str2double(table2array(data(:, 8)))';
    else
        % get rid of invalid data
        data(:, data(7, :) ~= 0) = [];
        data(:, data(9, :) < -1000) = [];
        rawDist = data(9, :);
        rawDistVar = zeros(size(rawDist));
        rssi = zeros(size(rawDist));
    end

    mean_result(i) = mean(rawDist);
    median_result(i) = median(rawDist);
    median_diststd(i) = median(sqrt(rawDistVar));
    median_rssi(i) = median(rssi);
    
    fprintf('distance: %d:\n', targets(i));
    fprintf('* mean: %.2f (uncalibrated)\n', mean_result(i));
    fprintf('* median: %.2f (uncalibrated)\n', median_result(i));
    fprintf('* std: %.2f (uncalibrated)\n', std(rawDist));

    figure(1); cdfplot(rawDist);
    diffs_each = param_linear(1) * rawDist + param_linear(2) - targets(i);
    pd = fitdist(diffs_each(~isnan(diffs_each))', 'Normal');
    fit_pd_each(i) = pd;
%     figure(2);
%     scatter3(...
%         sqrt(rawDistVar),...
%         rssi,...
%         rawDist - targets(i));
    
    all_data = [...
        all_data,...
        [rawDist;...
         targets(i) * ones(1, size(rawDist, 2));...
         sqrt(rawDistVar);...
         rssi
        ]...
    ];
end

% % shuffle
% shuffled_data = all_data(:, randperm(size(all_data, 2)));
% 
% % 10-fold cross validation
% step = floor(size(shuffled_data, 2) / 20);
% params = zeros(2, 20);
% mse = zeros(1, 20);
% for i = 1:20
%     from = step * (i - 1) + 1;
%     to = step * i;
%     train_data = shuffled_data;
%     test_data = train_data(:, from:to);
%     train_data(:, from:to) = [];
%     params(:, i) = polyfit(train_data(1, :), train_data(2, :), 1);
%     test_est = params(1, i) * test_data(1, :) + params(2, i);
%     mse(i) = sum((test_est - test_data(2, :)).^2) / size(test_data, 2);
% end

% param(1) = sum(params(1, :)) / size(mse, 2);
% % mse ./ sum(mse) * params(1, :)';
% param(2) = sum(params(2, :)) / size(mse, 2);
% % mse ./ sum(mse) * params(2, :)';
% validated_fit_data = param(1) * all_data(1, :) + param(2);
% mstd_1 = sqrt(sum((validated_fit_data - all_data(2, :)).^2) /...
%     size(all_data, 2));


figure(3); clf; hold on;
scatter(all_data(1, :), all_data(2, :), 'b.');
plot(median_result, targets, 'r', 'LineWidth', 2)

% linear fit
param_linear = polyfit(all_data(1, :), all_data(2, :), 1);
data_linear = param_linear(1) * all_data(1, :) + param_linear(2);
mstd_linear = sqrt(...
    sum((data_linear - all_data(2, :)).^2) / size(all_data, 2));
scatter(all_data(1, :), data_linear, 'c.');


diffs = data_linear - all_data(2, :); diffs_std = [];
figure(4); clf; hold on;
cdfplot(diffs)
% for i = 1:size(targets, 2)
%     diffs_std(i) = std(diffs(all_data(2, :) == targets(i)));
% %     pause;
% end
% scatter(median_rssi, diffs_std)

figure(3);
% parabolic fit
param_parabolic = polyfit(all_data(1, :), all_data(2, :), 2);
data_parabolic = ...
    param_parabolic(1) * all_data(1, :).^2 +...
    param_parabolic(2) * all_data(1, :) + ...
    param_parabolic(3);
mstd_parabolic = sqrt(...
    sum((data_parabolic - all_data(2, :)).^2) / size(all_data, 2));
scatter(all_data(1, :), data_parabolic, 'g.');

xlabel('Raw Distance'); 
ylabel('Target Distance');
legend('all data', 'median val', 'linear fit', 'parabolic fit', 'location', 'best')

fprintf('Std Err:\n');
fprintf(' linear mode: %.6f\n', mstd_linear);
fprintf(' parabolic mode: %.6f\n', mstd_parabolic);




% 
% diffs = [];
% diffs = [diffs, calibration_walking('calibration_data/walking_outdoor/result_walking_3800_to_100cm_1517706485.txt')];
% diffs = [diffs, calibration_walking('calibration_data/walking_outdoor/result_walking_3800_to_100cm_1517706584.txt')];
% diffs = [diffs, calibration_walking('calibration_data/walking_outdoor/result_walking_3800_to_100cm_1517706685.txt')];
% diffs = [diffs, calibration_walking('calibration_data/walking_outdoor/result_walking_3800_to_100cm_1517706784.txt')];
% diffs = [diffs, calibration_walking('calibration_data/walking_outdoor/result_walking_3800_to_100cm_1517706881.txt')];
% diffs = [diffs, calibration_walking('calibration_data/walking_outdoor/result_walking_3800_to_100cm_1517706976.txt')];
% diffs = [diffs, calibration_walking('calibration_data/walking_outdoor/result_walking_3800_to_100cm_1517707172.txt')];

% 
% diffs = [diffs, calibration_walking('calibration_data/walking_outdoor/result_walking_3800_to_100cm_r_1517706433.txt')];
% diffs = [diffs, calibration_walking('calibration_data/walking_outdoor/result_walking_3800_to_100cm_r_1517706537.txt')];
% diffs = [diffs, calibration_walking('calibration_data/walking_outdoor/result_walking_3800_to_100cm_r_1517706636.txt')];
% diffs = [diffs, calibration_walking('calibration_data/walking_outdoor/result_walking_3800_to_100cm_r_1517706737.txt')];
% diffs = [diffs, calibration_walking('calibration_data/walking_outdoor/result_walking_3800_to_100cm_r_1517706835.txt')];
% diffs = [diffs, calibration_walking('calibration_data/walking_outdoor/result_walking_3800_to_100cm_r_1517706930.txt')];
% diffs = [diffs, calibration_walking('calibration_data/walking_outdoor/result_walking_3800_to_100cm_r_1517707073.txt')];
% pd = fitdist(diffs(~isnan(diffs))', 'Normal');
% prob_fit = cdf(pd, diffs(~isnan(diffs))');
% figure(10); clf; hold on;
% scatter(diffs(~isnan(diffs))', prob_fit);
% cdfplot(diffs); xlim([-200, 200])
% xlabel('Distance Err (cm)')
% title('Distribution of Distance Err When Walking')
% legend('fitted \mu=53.5043, \sigma=72.1852', 'actual dist error', 'location', 'best')

% % 
% diffs = [];
% diffs = [diffs, calibration_walking('calibration_data/walking_indoor/result_walking_3600_to_100cm_1517693155.txt')];
% diffs = [diffs, calibration_walking('calibration_data/walking_indoor/result_walking_3600_to_100cm_1517693287.txt')];
% diffs = [diffs, calibration_walking('calibration_data/walking_indoor/result_walking_3600_to_100cm_1517693408.txt')];
% diffs = [diffs, calibration_walking('calibration_data/walking_indoor/result_walking_3600_to_100cm_1517693534.txt')];
% 
% diffs = [];
% diffs = [diffs, calibration_walking('calibration_data/walking_indoor/result_walking_3600_to_100cm_r_1517693224.txt')];
% diffs = [diffs, calibration_walking('calibration_data/walking_indoor/result_walking_3600_to_100cm_r_1517693350.txt')];
% diffs = [diffs, calibration_walking('calibration_data/walking_indoor/result_walking_3600_to_100cm_r_1517693475.txt')];


% pd = fitdist(diffs(~isnan(diffs))', 'Normal');
% prob_fit = cdf(pd, diffs(~isnan(diffs))');
% figure(11); clf; hold on;
% scatter(diffs(~isnan(diffs))', prob_fit);
% cdfplot(diffs); xlim([-200, 200])
% xlabel('Distance Err (cm)')
% title('Distribution of Distance Err When Walking')
% legend('fitted \mu=28.8055, \sigma=50.1228', 'actual dist error', 'location', 'best')