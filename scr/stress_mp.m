function stress_mp(sub, data_dir)

output_dir = fullfile(pwd, 'sf');
mkdir(output_dir);

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