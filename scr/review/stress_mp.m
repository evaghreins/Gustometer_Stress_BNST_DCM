function stress_mp(sub, data_dir)
% STRESS_MP - Prepares and processes PsPM-formatted data for modeling 
%             psychophysiological responses using the PsPM toolbox
%
% This function processes psychophysiological data stored in PsPM-formatted 
% .mat files, standardizing time series lengths and handling specific cases 
% where adjustments are necessary (as specified in the *edited*.txt files). 
% It then sets up and executes model inversion using the matching pursuit 
% (MP) algorithm.
%
% INPUT:
%   - sub (integer)      : Index of the subject file in `data_dir`
%   - data_dir (string)  : Directory containing the PsPM .mat files
%
% PROCESS:
%   1. Loads the subject-specific .mat file from `data_dir`.
%   2. Extracts marker timestamps and physiological time series.
%   3. Determines the epoch range using a helper function (`obtain_epoch`).
%   4. Standardizes time series to 120s unless specified.
%   5. Saves the updated .mat file.
%   6. If a valid epoch is detected, prepares and runs a PsPM inversion.
%
% OUTPUT:
%   - Updated PsPM-formatted .mat file with standardized time series.
%   - Results stored in the current working directory (`sf`).
%
% DEPENDENCIES:
%   - **PsPM toolbox** (must be installed and added to the MATLAB path).
%
% EXAMPLE USAGE:
%   stress_mp(1, '/path/to/pspm_data');
%
% NOTES:
%   - Some subjects have specific adjustments based on `obtain_epoch` logic.
%   - Epochs are determined using hardcoded cases or defaulted to [0, 120s].
%
% ------------------------------------------------------------------------

output_dir = fullfile(pwd, 'sf');
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

% Obtain useful params
files = dir(fullfile(data_dir, '*.mat'));
load(fullfile(files(sub).folder, files(sub).name), 'data', 'infos');
marker_seconds = data{1, 1}.data;
time_series = data{2, 1}.data;

% Obtain epoch and update time series if needed
sub_sess_id = extractBetween(files(sub).name, 'pspm_', '.mat');
[time_series, epoch] = obtain_epoch(sub_sess_id, marker_seconds,...
    time_series);

% Save updated file
data{2, 1}.data = time_series;
save(fullfile(files(sub).folder, files(sub).name), 'data', 'infos');

% Invert models if epoch provided
if epoch ~= 0

    matlabbatch{1}.pspm{1}.first_level{1}.scr{1}.sf.datafile =...
        {fullfile(files(sub).folder, files(sub).name)};
    matlabbatch{1}.pspm{1}.first_level{1}.scr{1}.sf.modelfile =...
        [sub_sess_id{:}, '_sf'];
    matlabbatch{1}.pspm{1}.first_level{1}.scr{1}.sf.outdir =...
        {output_dir};
    matlabbatch{1}.pspm{1}.first_level{1}.scr{1}.sf.method = 'mp';
    matlabbatch{1}.pspm{1}.first_level{...
        1}.scr{1}.sf.timeunits.seconds.epochs.epochentry = epoch;
    matlabbatch{1}.pspm{1}.first_level{1}.scr{1}.sf.filter.def = 0;
    matlabbatch{1}.pspm{1}.first_level{1}.scr{1}.sf.chan.chan_def = 0;
    matlabbatch{1}.pspm{1}.first_level{1}.scr{1}.sf.overwrite = false;
    matlabbatch{1}.pspm{1}.first_level{1}.scr{1}.sf.threshold = 0.1;
    matlabbatch{1}.pspm{1}.first_level{1}.scr{1}.sf.theta = [];
    matlabbatch{1}.pspm{1}.first_level{1}.scr{1}.sf.fresp = [];
    matlabbatch{1}.pspm{1}.first_level{1}.scr{1}.sf.dispwin = 1;
    matlabbatch{1}.pspm{1}.first_level{1}.scr{1}.sf.dispsmallwin = 0;

    % Run batch
    pspm_jobman ('initcfg');
    pspm_jobman ('run', matlabbatch);

else
    fprintf('No epoch detected for %s. Inversion not possible.\n',...
        sub_sess_id{:})
end

end

%--------------------------------------------------------------------------
% Helper function for updating epochs and time series data
%--------------------------------------------------------------------------

function [data, epoch] = obtain_epoch(sub_sess_id,...
    marker_seconds, time_series)

% OBTAIN_EPOCH - Determines the time epoch for PsPM analysis and adjusts 
%                time series
%
% This function defines the analysis epoch for a given subject-session ID
% based on predefined conditions. If a session has a specified epoch, it is
% used; otherwise, the epoch defaults to [marker_seconds(1),
% marker_seconds(1) + 120]. If a session is flagged as 'nan', linear
% interpolation is applied to adjust the time series.
%
% INPUT:
%   - sub_sess_id (string)       : Subject and session identifier
%   - marker_seconds (array)     : Marker timestamps in seconds
%   - time_series (array)        : Original time series data
%
% OUTPUT:
%   - data (array)               : Adjusted time series data
%   - epoch (array)              : Selected epoch [start_time, end_time]
%
% PROCESS:
%   1. Matches `sub_sess_id` to a predefined list of epochs.
%   2. If an epoch is specified as 'nan', applies linear interpolation to a 
%      segment of the time series before assigning a standard epoch.
%   3. If no predefined rule exists, assigns the default epoch of 120 s.
%   4. Ensures the time series data is strictly positive.
%
% EXAMPLE USAGE:
%   [data, epoch] = obtain_epoch('101_Stress1', marker_seconds,...
%       time_series);
%
% NOTES:
%   - Hardcoded adjustments apply to specific subject-session cases.
%   - Linear interpolation is applied when flagged as 'nan' in the 
%     predefined list.
%
% ------------------------------------------------------------------------

updates =...
    {'101_Stress1', '[marker_seconds(1), marker_seconds(1)+120]';...
    '101_Stress2', '[marker_seconds(1), marker_seconds(1)+120]';...
    '103_Stress2', '[marker_seconds(1), marker_seconds(1)+120]';...
    '120_Stress1', '[marker_seconds(1), marker_seconds(1)+120]';...
    '120_Stress2', '0';...
    '123_Stress2', '[marker_seconds(1)-120, marker_seconds(1)]';...
    '127_Stress2', '[marker_seconds(1), marker_seconds(1)+120]';...
    '152_Stress1', '0';...
    '152_Stress2', '0';...
    '904_Stress1', '[marker_seconds(1)-120, marker_seconds(1)]';...
    '116_Stress2', 'nan'};

if any(contains(updates(:,1), sub_sess_id))
    epoch = eval(updates{contains(updates(:,1), sub_sess_id), 2});
    if isnan(epoch)
        i = 1*10^5;
        j = 1.3*10^5;
        x = linspace(time_series(i), time_series(j),...
            length(time_series(i:j)));
        time_series(i:j) = x;
        epoch = [marker_seconds(1), marker_seconds(1)+120];
    end
else
    epoch = [marker_seconds(1), marker_seconds(1)+120];
end

% Ensure absolute values
data = time_series + abs(min(time_series));

end