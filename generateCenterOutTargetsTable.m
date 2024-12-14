function T = generateCenterOutTargetsTable(options)
%GENERATECENTEROUTTARGETSTABLE  Generates table of center-out targets.
%
% Syntax:
%   T = cursor.generateCenterOutTargetsTable('Name', value, ...);

arguments
    options.NumAngles (1,1) {mustBeInteger, mustBePositive} = 5;
    options.NumRepsPerCombo (1,1) {mustBeInteger, mustBePositive} = 4;
    options.OuterRingRadius (:,1) double {mustBePositive} = [100.0; 290.0];
    options.TargetRadius (:,1) double {mustBePositive} = [25, 50];
    options.T1Hold1 (:,1) double = 1;
    options.T1Hold2 (:,1) double = 0.5;
    options.MoveLimit (1,1) double = 1.5;
    options.T2Hold1Limit (1,1) double = 0.5;
    options.TotalLimit (1,1) double = 10.0;
end

theta = linspace(0, 2*pi, options.NumAngles+1);
theta = theta + mean(diff(theta))/2; % offset slightly from 0
theta = reshape(theta(1:options.NumAngles),options.NumAngles,1);

n = options.NumRepsPerCombo;
a = options.NumAngles; 
b = numel(options.OuterRingRadius);
c = numel(options.TargetRadius);
d = numel(options.T1Hold1);
e = numel(options.T1Hold2);

theta = repmat(theta, b, 1);
delta = repelem(options.OuterRingRadius, a, 1);

theta = repmat(theta, c, 1);
delta = repmat(delta, c, 1);
r = repelem(options.TargetRadius, a*b, 1);

theta = repmat(theta, d, 1);
delta = repmat(delta, d, 1);
r = repmat(r, d, 1);
T1Hold1 = repelem(options.T1Hold1, a*b*c, 1);

theta = repmat(theta, e, 1);
delta = repmat(delta, e, 1);
r = repmat(r, e, 1);
T1Hold1 = repmat(T1Hold1, e, 1);
T1Hold2 = repelem(options.T1Hold2, a*b*c*d, 1);

[T1_x, T1_y, T2_x, T2_y] = convert_thetas_to_targets(theta, delta);
T1_r = r;
T2_r = r;
nUnique = a*b*c*d*e;
T2Hold1 = ones(nUnique,1).*options.T2Hold1Limit;
Move = ones(nUnique,1).*options.MoveLimit;
Total = ones(nUnique,1).*options.TotalLimit;

tmp = table(T1_x, T1_y, T1_r, T2_x, T2_y, T2_r, T1Hold1, T1Hold2, T2Hold1, Move, Total);
T = repmat(tmp,n*2,1);
% Generate the replicates with stratification
for ii = 1:n
    vec = (1:(2*nUnique)) + (ii-1)*2*nUnique;
    trialOrder = randperm(nUnique,nUnique);
    t = repelem(tmp(trialOrder,:),2,1); 
    t.T1_x(1:2:end) = 0;
    t.T1_y(1:2:end) = 0;
    t.T2_x(2:2:end) = 0;
    t.T2_y(2:2:end) = 0;
    T(vec,:) = t;
end
    function [T1_x, T1_y, T2_x, T2_y] = convert_thetas_to_targets(theta, delta)
        x_opts = round(delta.*cos(theta));
        y_opts = round(delta.*sin(theta));
        T1_x = x_opts;
        T2_x = x_opts;
        T1_y = y_opts;
        T2_y = y_opts;
    end

end