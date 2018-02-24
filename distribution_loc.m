% pd = makedist('normal', 'mu', 0, 'sigma', 53.8836);  % cm

pd = makedist('tlocationscale', 'mu', 0, 'sigma', 42.8875, 'nu', 5.3095);

% params
plotflag = 0;
samples = 100000;
farthest_dist = [500, 2000]; % cm
devLocations = [0, 0;
                500, 0;
                500, 2000;
                0, 2000];

% setup
for i = size(devLocations, 1):-1:1
    for j = size(devLocations, 1):-1:(i+1)
        diff = devLocations(i, :) - devLocations(j, :);
        pairwiseDist(i, j) = sqrt(sum(diff.^2));
    end
end
targetLocs = rand(samples, 2) .* farthest_dist;
% targetLocs = [250, 100; 250, 200; 250, 300; 250, 400; 250, 500];
% samples = size(targetLocs, 1);
trueDist = zeros(size(devLocations, 1), samples);
estDist = zeros(size(devLocations, 1), samples);

% % estimate measurements
for i = 1:size(devLocations, 1)
    trueDist(i, :) = sqrt(sum((targetLocs - devLocations(i, :)).^2, 2));
    if isa(pd, 'prob.NormalDistribution')
        randvar_vec = random(pd, size(trueDist(i, :)));
    else
        signs = (rand(size(trueDist(i, :))) < 0.5) * 2 - 1;
        randvar_vec = random(pd, size(trueDist(i, :))) .* signs;
    end
    estDist(i, :) = trueDist(i, :) + randvar_vec;
end

% estimate locations
estLocs = zeros(size(targetLocs));
if plotflag
    figure(3); clf; hold on;
    scatter(devLocations(:, 1), devLocations(:, 2), 'b*');
end
for i = 1:samples
    points = [];
    for j = 1:size(devLocations, 1)
        for k = (j+1):size(devLocations, 1)
            d = pairwiseDist(j, k);
            if (d > estDist(j, i) + estDist(k, i)) ||...
                    (d < abs(estDist(j, i) - estDist(k, i)))
                continue
            end
            a = (estDist(j, i) * estDist(j, i) -...
                estDist(k, i) * estDist(k, i) +...
                d * d) / (2 * d);
            h = sqrt(estDist(j, i) * estDist(j, i) - a * a);
            x0 = devLocations(j, 1) +...
                a * (devLocations(k, 1) - devLocations(j, 1)) / d;
            y0 = devLocations(j, 2) +...
                a * (devLocations(k, 2) - devLocations(j, 2)) / d;
            rx = -(devLocations(k, 2) - devLocations(j, 2)) * (h / d);
            ry = -(devLocations(k, 1) - devLocations(j, 1)) * (h / d);
            points = [points; x0 + rx, y0 - ry; x0 - rx, y0 + ry];
        end
    end
    if ~isempty(points) && size(devLocations, 1) == 2
        if devLocations(1, 2) == devLocations(2, 2)
            points(points(:, 2) < devLocations(1, 2), :) = [];
        elseif devLocations(1, 1) == devLocations(2, 1)
            points(points(:, 1) < devLocations(1, 1), :) = [];
        end
    end
    estLoc = median(points, 1);
    if isempty(estLoc)
        estLocs(i, :) = nan;
    else
        estLocs(i, :) = estLoc;
        if plotflag
            scatter(targetLocs(i, 1), targetLocs(i, 2), 'ks');
            scatter(estLocs(i, 1), estLocs(i, 2), 'r.');
            pause(0.001)
        end
    end
end

logistics = isnan(estLocs(:, 1));
estLocs(logistics, :) = [];
targetLocs(logistics, :) = [];
fprintf('* %d cannot est locations\n', sum(logistics));

err = sqrt(sum((estLocs - targetLocs).^2, 2));
figure(4); hold on; cdfplot(err);

fitresult = allfitdist(err, 'pdf');
% essentially, we are getting a gamma distribution in generall
% the result should be validated in real-life experiments also