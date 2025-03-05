function stress_test(data_dir)
% STRESS_TEST - Analyzes session-based differences in spontaneous 
%               fluctuations using PsPM results
%
% This function processes PsPM model outputs to assess changes in the 
% frequency of spontaneous fluctuations between two stress conditions.
% It extracts subject-specific results, performs a statistical comparison, 
% and visualizes the results using a raincloud plot.
%
% INPUT:
%   - data_dir (string, optional) : Directory containing PsPM results 
%                                   (.mat files) (default: 'sf').
%
% PROCESS:
%   1. Checks if `data_dir` is provided or defaults to 'sf'.
%   2. Identifies subjects with complete data across both stress sessions.
%   3. Extracts statistical results from PsPM-formatted .mat files.
%   4. Performs a paired t-test to compare spontaneous fluctuations between
%      sessions.
%   5. Visualizes results using a raincloud plot.
%
% OUTPUT:
%   - Prints paired t-test results.
%   - Generates a plot comparing low-stress vs. high-stress sessions.
%
% DEPENDENCIES:
%   - **daviolinplot** (for raincloud plot visualization).
%
% EXAMPLE USAGE:
%   stress_test_update('/path/to/pspm_results');  % Process directory
%   stress_test_update();                         % Use default directory
%
% NOTES:
%   - Assumes files follow the naming format: 
%     `<subject>_Stress<session>_sf.mat`.
%   - Expects a variable `sf.stats` in each .mat file.
%   - Subjects missing data for one session are excluded from analysis.
%
% ------------------------------------------------------------------------

% Check if the function was called without an argument
if nargin < 1
    % Check if the default directory 'sf' exists
    if exist('sf', 'dir')
        data_dir = 'sf';  % Set default data directory
    else
        error(['This function can only run if the directory containing',...
            ' PsPM results is provided (or is available in the working',...
            ' directory as "sf").']);
    end
end

% Confirm the directory exists before proceeding
if ~exist(data_dir, 'dir')
    error('The specified directory "%s" does not exist.', data_dir);
end

% Obtain PsPM reults
files = dir(fullfile(data_dir, '*.mat'));
files_cell = struct2cell(files);
subs = extractBefore(files_cell(1,:), '_');

% Get unique subjects and their counts
[unique_subs, ~, idx] = unique(subs);
counts = histcounts(idx, 1:numel(unique_subs));

% Find subjects that appear only once
subs_update = unique_subs(counts ~= 1);

% Organize results
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
    ' t(%s) = %s, p = %s \n\n'], num2str(STATS.df),...
    num2str(STATS.tstat),...
    num2str(P));

% Plot with DataViz
figure;
daviolinplot(result, 'outsymbol', 'k+',...
    'boxcolors', 'w',...
    'violinalpha', 1/2, 'scatter', 1, 'jitter', 1,...
    'withinlines', 1,... 
    'xtlabels', {'Low Stress', 'High Stress'});
ylabel(['Frequency of spontaneous fluctuations (1/s)', newline]);
xlabel([newline, 'Session']);
set(gca,'FontSize',20);

end