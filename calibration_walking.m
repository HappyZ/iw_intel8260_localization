function diffs = calibration_walking(filename)
    startI = 3600;
    endI = 100;
    if contains(filename, '_r_')
        startI = 100;
        endI = 3600;
    end
%     param_linear = [0.6927, 400.3157];  % medical_try_0b
%     param_linear = [0.7927,483.3157];  % medical_try_1f
    param_linear = [0.8927,553.3157];  % outdoor
%     param_linear = [0.9376, 558.0551];   % indoor
    data = readtable(filename, 'ReadVariableNames', 0);
    data = data(2:end, :);
    caliDist = str2double(table2array(data(:, 2)))';
    rawRTT = str2double(table2array(data(:, 3)))';
    rawRTTVar = str2double(table2array(data(:, 4)))';
    rawDist = str2double(table2array(data(:, 5)))';
    rawDistVar = str2double(table2array(data(:, 6)))';
    rssi = str2double(table2array(data(:, 7)))';
    time = str2double(table2array(data(:, 8)))';
    % clear invalid data
    logistics = rawDist < -1000 | rawDist > 10000 | isnan(time);
    caliDist(logistics) = [];
    rawRTT(logistics) = [];
    rawRTTVar(logistics) = [];
    rawDist(logistics) = [];
    rawDistVar(logistics) = [];
    rssi(logistics) = [];
    time(logistics) = [];
    % normalize time
    time = (time - time(1)) ./ (time(end) - time(1));
    
%     rawDist = movmean(rawDist, 10, 'omitnan');
%     rssi = movmean(rssi, 10, 'omitnan');
%     for i = size(caliDist, 2) - 3: -4: 1
%         rawDist(i) = nanmean(rawDist(i: i + 3));
%         rawDist(i + 1: i + 3) = [];
%         rssi(i) = nanmean(rssi(i: i + 3));
%         rssi(i + 1: i + 3) = [];
%         time(i + 1: i + 3) = [];
%     end
    
    dist = rawDist * param_linear(1) + param_linear(2);
    targets = (time - time(1)) * (endI - startI) / (time(end) - time(1)) + startI;
    diffs = (targets - dist);
    fprintf("** mean diff: %.4f cm\n", nanmean(diffs));
    fprintf("** median diff: %.4f cm\n", nanmedian(diffs));
    
    figure(1); % clf; 
    scatter3(time, dist, rssi); hold on; scatter(time, dist, '.')
%     plot([time(1), time(end)], [startI, endI]); 
    view([0, 90]);
%     if contains(filename, '_r_')
%         title('back')
%         figure(9); hold on;
%         plot(flip((time - time(1)) ./ (time(end) - time(1))), rssi)
%     else
%         title('front')
%         figure(9); hold on;
%         plot(((time - time(1)) ./ (time(end) - time(1))), rssi)
%     end
    
%     figure(2); clf; hold on;
%     pd = fitdist(diffs(~isnan(diffs))', 'Normal')
%     prob_fit = cdf(pd, diffs(~isnan(diffs))');
%     scatter(diffs(~isnan(diffs))', prob_fit);
%     cdfplot(diffs);
% %     histogram(diffs, 'BinWidth', 1, 'Normalization', 'pdf');
   
end