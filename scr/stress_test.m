function stress_test(data_dir)

% Obtain files
files = dir(fullfile(data_dir, '*.mat'));
files_cell = struct2cell(files);
subs = extractBefore(files_cell(1,:), '_');

% Get unique subjects and their counts
[unique_subs, ~, idx] = unique(subs);
counts = histcounts(idx, 1:numel(unique_subs));

% Find subjects that appear only once
subs_update = unique_subs(counts ~= 1);

% Methods and results
result = nan(length(subs_update),2);

for i = 1:length(subs_update)   % Subject
    sub = subs_update{i};
    for j = 1:2                 % Session
        load(fullfile(data_dir, [sub, '_Stress', num2str(j),...
            '_sf.mat']), 'sf');
        result(i,j) = sf.stats;
    end
end

% Statistics
% Perform within-subjects t-test
[H,P,CI,STATS] = ttest(result(:,1), result(:,2));
NHST = {'no', 'yes'};
fprintf('Null hypothesis rejected: %s\n', NHST{H+1});
fprintf('Mean diff: %s [%s, %s]\n',...
    num2str(mean(result(:,1)-result(:,2))),...
    num2str(CI(1)),...
    num2str(CI(2)));
fprintf(['Within-subjects t-test:',...
    ' t(%s) = %s, p = %s \n\n'], num2str(STATS.df), num2str(STATS.tstat),...
    num2str(P));

% Data for plotting
means = mean(result(:,:), 1);
sems = std(result(:,:), 0, 1) / sqrt(size(result(:,:), 1));

% Plot using superbar
superbar(1:2, means, 'E', sems, 'BarFaceColor', [0.2 0.6 0.8],...
    'ErrorBarColor', 'k');


% Annotate the plot
xticks([1 2]);
xticklabels({'Low Stress', 'High Stress'});
ylabel(['Frequency of spontaneous fluctuations (1/s)', newline]);
xlabel([newline, 'Session']);
ylim([0, round((max(means) + max(sems)*2), 1)]);
fontsize(gcf, scale=1.8)