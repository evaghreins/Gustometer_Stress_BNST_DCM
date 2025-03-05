function stress_irr(review_dir)
% STRESS_IRR - Computes inter-rater reliability (IRR) for exclusions
%
% This function assesses inter-rater reliability by analyzing subject 
% exclusions recorded by multiple raters. The agreement is computed as 
% the proportion of subjects that all raters agree to exclude.
%
% INPUT:
%   review_dir (optional) - Directory containing exclusion files 
%                           (default: 'review' if available).
%
% FILE FORMAT:
%   Each rater's exclusions are stored in a text file named:
%     '<RaterInitials>_discarded_files.txt'
%   The file contains a list of filenames in the format:
%     'MG_pspm_<subject>_<session>.mat'
%   The function extracts <subject> for IRR assessment.
%
% PROCESS:
%   1. Reads exclusion files for each rater.
%   2. Extracts subject identifiers from filenames.
%   3. Records subjects marked for exclusion by each rater.
%   4. Computes observed agreement (percentage of subjects all raters 
%      agree to exclude).
%   5. Saves the list of fully excluded subjects and IRR score to 
%      'exclusions.mat'.
%
% OUTPUT:
%   - Prints inter-rater agreement percentage.
%   - Saves:
%     - 'exclusions.mat': Contains subjects excluded by all raters.
%     - 'observedAgreement': Agreement percentage.
%
% EXAMPLE USAGE:
%   stress_irr('my_review_dir');  % Use a specific directory
%   stress_irr();                 % Use default directory ('review')
%
% NOTE:
%   - Rater initials should be defined in the 'raters' variable.
%   - The function assumes filenames follow the specified format.
%
% ------------------------------------------------------------------------

% Check if the function was called without an argument
if nargin < 1
    % Check if the default directory 'sf' exists
    if exist('review', 'dir')
        review_dir = 'review';  % Set default data directory
    else
        error(['This function can only run if the directory containing',...
            ' *discarded*.txt is provided (or is available in the',...
            ' working directory as "review").']);
    end
end

% Confirm the directory exists before proceeding
if ~exist(review_dir, 'dir')
    error('The specified directory "%s" does not exist.', review_dir);
end

% Provide rater initals
raters = {'EGH', 'MG'};
excluded_subjects = containers.Map();

% Loop through each rater's file
for i = 1:numel(raters)
    % Build filename based on the rater's initials
    filename = fullfile(review_dir, sprintf('%s_discarded_files.txt',...
        raters{i}));

    % Read file contents line-by-line
    fid = fopen(filename, 'r');
    fileData = textscan(fid, '%s', 'Delimiter', '\n');
    fclose(fid);

    % Extract subject for each exclusion
    for j = 1:length(fileData{1})
        file = fileData{1}{j};

        % Split filename by underscores and dots
        parts = split(file, {'_', '.'});

        % Get subject (3rd part)
        subject = parts{3};

        % Record the exclusion for inter-rater comparison
        if isKey(excluded_subjects, subject)
            excluded_subjects(subject) = [excluded_subjects(subject), i];
        else
            excluded_subjects(subject) = i;
        end
    end
end

% Calculate inter-rater reliability
agreements = cellfun(@numel, values(excluded_subjects));
n_raters = numel(raters);
n_subjects = numel(agreements);
agreements(agreements > n_raters) = n_raters;

% Reliability calculation (Fleiss' kappa or observed agreement)
observedAgreement = sum(agreements == n_raters) / n_subjects;
fprintf(['Inter-rater reliability (total agreement on subjects):',...
    ' %.2f%%\n'], observedAgreement * 100);

% Exclude
candidates = keys(excluded_subjects);
exclusions = candidates(agreements == n_raters);
save('exclusions.mat', "exclusions", "observedAgreement");

end