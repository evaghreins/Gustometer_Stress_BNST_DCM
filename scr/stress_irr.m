function stress_irr(review_dir)

% Provide rater initals
raters = {'EGH', 'MG'};
excludedSubjects = containers.Map();

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
        if isKey(excludedSubjects, subject)
            excludedSubjects(subject) = [excludedSubjects(subject), i];
        else
            excludedSubjects(subject) = i;
        end
    end
end

% Calculate inter-rater reliability
agreements = cellfun(@numel, values(excludedSubjects));
numRaters = numel(raters);
numSubjects = numel(agreements);
agreements(agreements > numRaters) = numRaters;

% Reliability calculation (Fleiss' kappa or observed agreement)
observedAgreement = sum(agreements == numRaters) / numSubjects;

fprintf(['Inter-rater reliability (total agreement on subjects):',...
    ' %.2f%%\n'], observedAgreement * 100);

% Exclude
candidates = keys(excludedSubjects);
exclusions = candidates(agreements == numRaters);
save('exclusions.mat', "exclusions", "observedAgreement");

end