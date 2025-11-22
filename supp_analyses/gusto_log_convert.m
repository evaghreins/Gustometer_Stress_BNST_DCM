function output = gusto_log_convert(file)
% GUSTO_LOG_CONVERT
% -------------------------------------------------------------------------
% Purpose:
%   Parse a behavioural log file from the gustometer fMRI task and return
%   all key timing and rating information in a structured format suitable
%   for condition file generation and later inclusion in GLM/DCM models.
%
% Usage:
%   output = gusto_log_convert('/path/to/sub01_gusto_1.txt');
%
% Input:
%   file      - Full path or filename of a gustometer log (.txt) file.
%               Expected to follow the formatting produced by the PsychoPy
%               script (header, ratings, trial timing blocks).
%
% Output (structure):
%   output.sub                      - Subject ID (numeric)
%   output.ses                      - Session/run number (numeric)
%   output.date                     - [date, time] strings
%
%   output.ratings.stress           - Pre-task stress rating
%   output.ratings.hunger           - Pre-task hunger rating
%   output.ratings.pleasantness     - 12×1 ratings of taste pleasantness
%
%   output.timings                  - Nx1 vector of event onset times (sec)
%   output.events                   - Nx1 cell array of event labels
%                                     for each entry in output.timings
%
% Description:
%   The log file is assumed to contain:
%       - Header info (subject, session, date/time)
%       - Pre-task ratings (stress, hunger)
%       - Pleasantness ratings in a tabular block at the end
%       - Event onsets for Water/Milk cues and tastes, rinses, and ratings
%   This function extracts these pieces, converts to numeric where needed,
%   and aligns event labels with sorted onset times.
%
% Notes:
%   - Assumes a fixed file structure produced by the PsychoPy code.
%   - Times are in seconds relative to scanner trigger.
%   - Minor string cleaning is applied to remove trailing semicolons.
%
% Author:
%   Matthew D. Greaves
%   Last updated: 03-Nov-2025
% -------------------------------------------------------------------------

% Import options
opts = delimitedTextImportOptions("NumVariables", 14);
opts.Delimiter = " ";
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";
opts.ConsecutiveDelimitersRule = "join";
opts.LeadingDelimitersRule = "ignore";

% Header, trial type and initial ratings
opts.DataLines = [1, 7];
x = ["food", "cue", "task", "behavioural", "data", "VarName6",...
    "VarName7", "VarName8", "VarName9", "VarName10", "VarName11",...
    "VarName12", "VarName13", "VarName14"];
opts.VariableNames = x;
opts.VariableTypes = repelem("string",14);
opts = setvaropts(opts, x, "WhitespaceRule", "preserve");
opts = setvaropts(opts, x, "EmptyFieldRule", "auto");
header = readmatrix(file, opts);

% Pleasantness
opts.DataLines = [22, Inf];
opts.VariableTypes = strrep(opts.VariableTypes,"string","double");
opts = setvaropts(opts, x, "TrimNonNumeric", true);
opts = setvaropts(opts, x, "ThousandsSeparator", ",");
pleasantness = readtable(file, opts);
pleasantness = table2array(pleasantness);
pleasantness = reshape(pleasantness(~isnan(pleasantness)), 12, 2);
pleasantness = sortrows(pleasantness,1);

% Onsets
opts.DataLines = [9, 21];
opts.VariableNames = x(1:8);
opts.VariableTypes = strrep(opts.VariableTypes,"double","string");
opts.VariableTypes = opts.VariableTypes(1:8);
opts = setvaropts(opts, x(1:8), "WhitespaceRule", "preserve");
opts = setvaropts(opts, x(1:8), "EmptyFieldRule", "auto");
onsets = readmatrix(file, opts);

output.sub = str2double(header(2,2));
output.ses = str2double(header(3,2));
output.date = header(4,1:2);
output.ratings.stress = str2double(header(5,3));
output.ratings.hunger = str2double(header(6,3));
output.ratings.pleasantness = pleasantness(:,2);

trial = header(7,3:end)';
timings = [str2double(extractBefore(onsets(2:13,2), ';'));...
    str2double(extractBefore(onsets(2:13,4), ';'));...
    str2double(extractBefore(onsets(2:13,6), ';'));...
    str2double(onsets(2:13,8))];
output.timings = sortrows(timings); output.events =... 
repmat(onsets(1,1:2:7)',12,1);
output.events(contains(output.events, "visual")) = trial;

end

