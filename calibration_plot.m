figure(1);
clf; hold on;

desired_result = [60:30:1200, 120, 170, 200, 430, 1000, 1300:100:2000];
mean_result = zeros(size(desired_result));
diff_result = zeros(size(desired_result));
all_data = [];
for i = 1:length(desired_result)
    dist = desired_result(i);
    filename = ['calibration_data/result_', num2str(dist), 'cm.txt'];

    fileID = fopen(filename, 'r');
    sizeData = [9 Inf];
    formatSpec = [...
        'Target: %x:%x:%x:%x:%x:%x, status: %d, ',...
        'rtt: %d psec, distance: %d cm\n'...
    ];
    data = fscanf(fileID, formatSpec, sizeData);
    data(:, data(7, :) ~= 0) = [];
    data(:, data(9, :) < -1000) = [];
    fclose(fileID);

    fprintf('distance: %d:\n', dist);
    fprintf('* mean: %.2fcm\n', mean(data(9, :)));
    fprintf('* median: %.2fcm\n', median(data(9, :)));

    cdfplot(data(9, :));
    
    mean_result(i) = mean(data(9, :));
    all_data = [all_data, [data(9, :); dist * ones(1, length(data(9, :)))]];
    diff_result(i) = desired_result(i) - mean_result(i);
end

figure(2); clf;
scatter(all_data(1, :), all_data(2, :), '.');
params = polyfit(all_data(1, :), all_data(2, :), 1)
fitted_data = params(1) * all_data(1, :) + params(2);
hold on;
plot(all_data(1, :), fitted_data, '-')