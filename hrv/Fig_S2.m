% RMSSD figure variant with panel b aligned to the post-hoc tests in HRV_combined_R1.
% Panel a remains a descriptive z-scored time course, but the shaded windows
% use the same proportional early/middle/late scheme as panel b.

clear; clc;

%% --- Load
infile = 'HRV_vectors_all_participants.mat';
S = load(infile);
HRV = S.HRV_vectors;

%% --- Config
exclude = {'Sub107','Sub133','Sub139','Sub147','Sub151'};
dt = 2;                         % display step for panel a
binProportion = 0.035;          % matches HRV_combined_R1 post-hoc windows
lsColor = [1.0 0.498 0.054];
hsColor = [0.275 0.510 0.705];
bandColor = [0.7 0.7 0.7];
fontSize = 14;
pointSize = 30;
pointJitter = 0.045;
jitterSeed = 7;

%% --- Panel a data: descriptive time course on a common trimmed length
participants = setdiff(fieldnames(HRV), exclude);
LS_list = {};
HS_list = {};
minLen = inf;

for i = 1:numel(participants)
    s = HRV.(participants{i});
    if isfield(s,'LS') && isfield(s,'HS') && ~isempty(s.LS) && ~isempty(s.HS)
        ls = s.LS(:).';
        hs = s.HS(:).';
        m = min(numel(ls), numel(hs));
        if m > 0
            LS_list{end+1} = ls(1:m); %#ok<SAGROW>
            HS_list{end+1} = hs(1:m); %#ok<SAGROW>
            minLen = min(minLen, m);
        end
    end
end

LS = cell2mat(cellfun(@(v) v(1:minLen), LS_list, 'UniformOutput', false).');
HS = cell2mat(cellfun(@(v) v(1:minLen), HS_list, 'UniformOutput', false).');
nSubjA = size(LS,1);
t = (0:minLen-1) * dt;

% Descriptive z-scored time course
LSz = (LS - mean(LS,2)) ./ max(std(LS,0,2), eps);
HSz = (HS - mean(HS,2)) ./ max(std(HS,0,2), eps);
lsMean = mean(LSz,1);
hsMean = mean(HSz,1);
lsSEM = std(LSz,0,1) / sqrt(nSubjA);
hsSEM = std(HSz,0,1) / sqrt(nSubjA);

% Approximate the inferential windows on the trimmed common timeline
segDisplay = floor(minLen * binProportion);
if segDisplay < 1
    error('Display window length is too short for the selected bin proportion.');
end
midStartDisplay = floor(minLen/2 - segDisplay/2 + 1);
midEndDisplay = midStartDisplay + segDisplay - 1;

earlyMask = false(1, minLen);
earlyMask(1:segDisplay) = true;
middleMask = false(1, minLen);
middleMask(midStartDisplay:midEndDisplay) = true;
lateMask = false(1, minLen);
lateMask(end-segDisplay+1:end) = true;

tE = t(earlyMask); e0 = tE(1); e1 = tE(end);
tM = t(middleMask); m0 = tM(1); m1 = tM(end);
tL = t(lateMask); l0 = tL(1); l1 = tL(end);

%% --- Panel b data: mirror HRV_combined_R1 post-hoc contrasts on raw values
dLS_EM = [];
dHS_EM = [];
dLS_EL = [];
dHS_EL = [];

for i = 1:numel(participants)
    p = participants{i};
    entry = HRV.(p);

    if ~isfield(entry, 'LS') || ~isfield(entry, 'HS')
        continue;
    end

    ls = entry.LS(:);
    hs = entry.HS(:);
    if isempty(ls) || isempty(hs)
        continue;
    end

    % Match HRV_combined_R1 as closely as possible:
    % window size is proportional to the LS vector length for each participant.
    n = length(ls);
    seg = floor(n * binProportion);
    if seg < 10
        continue;
    end

    midStart = floor(n/2 - seg/2 + 1);
    midEnd = midStart + seg - 1;
    if length(hs) < max([seg, midEnd]) || length(ls) < midEnd
        continue;
    end

    lsEarly = mean(ls(1:seg));
    lsMiddle = mean(ls(midStart:midEnd));
    lsLate = mean(ls(end-seg+1:end));

    hsEarly = mean(hs(1:seg));
    hsMiddle = mean(hs(midStart:midEnd));
    hsLate = mean(hs(end-seg+1:end));

    dLS_EM(end+1,1) = lsMiddle - lsEarly; %#ok<SAGROW>
    dHS_EM(end+1,1) = hsMiddle - hsEarly; %#ok<SAGROW>
    dLS_EL(end+1,1) = lsLate - lsEarly; %#ok<SAGROW>
    dHS_EL(end+1,1) = hsLate - hsEarly; %#ok<SAGROW>
end

nSubjB = numel(dLS_EM);
if nSubjB == 0
    error('No participants survived the panel b inferential windowing.');
end

deltaLS = [dLS_EM dLS_EL];
deltaHS = [dHS_EM dHS_EL];
mLS = [mean(dLS_EM) mean(dLS_EL)];
eLS = [std(dLS_EM)/sqrt(nSubjB) std(dLS_EL)/sqrt(nSubjB)];
mHS = [mean(dHS_EM) mean(dHS_EL)];
eHS = [std(dHS_EM)/sqrt(nSubjB) std(dHS_EL)/sqrt(nSubjB)];

[~, pEM] = ttest(dLS_EM, dHS_EM);
[~, pEL] = ttest(dLS_EL, dHS_EL);

%% --- Plot
figure('Color','w','Units','pixels','Position',[100 100 560 760]);
tiledlayout(2,1,'TileSpacing','compact','Padding','compact');

% ---------- Panel a ----------
ax1 = nexttile(1);
hold(ax1,'on');
box(ax1,'off');
grid(ax1,'on');

yl = [-1.5 1.5];
patch([e0 e1 e1 e0], [yl(1) yl(1) yl(2) yl(2)], bandColor, 'FaceAlpha',0.35, 'EdgeColor','none');
patch([m0 m1 m1 m0], [yl(1) yl(1) yl(2) yl(2)], bandColor, 'FaceAlpha',0.30, 'EdgeColor','none');
patch([l0 l1 l1 l0], [yl(1) yl(1) yl(2) yl(2)], bandColor, 'FaceAlpha',0.35, 'EdgeColor','none');

fill([t fliplr(t)], [lsMean+lsSEM fliplr(lsMean-lsSEM)], lsColor, 'FaceAlpha',0.25, 'EdgeColor','none');
fill([t fliplr(t)], [hsMean+hsSEM fliplr(hsMean-hsSEM)], hsColor, 'FaceAlpha',0.25, 'EdgeColor','none');

pLS = plot(t, lsMean, 'Color', lsColor, 'LineWidth',2);
pHS = plot(t, hsMean, 'Color', hsColor, 'LineWidth',2);

xlabel('Time (s)','FontSize',fontSize);
ylabel('z-scored RMSSD','FontSize',fontSize);
xlim([t(1) t(end)]);
legend([pLS pHS], {'Low-stress run','High-stress run'}, ...
    'Location','southwest', 'Box','off', 'FontSize',fontSize);
text(ax1, 0.0, 1.03, 'a', 'Units','normalized', 'FontSize',fontSize+2, ...
    'FontWeight','bold', 'HorizontalAlignment','left', 'VerticalAlignment','bottom');
set(ax1,'FontSize',fontSize);

% ---------- Panel b ----------
ax2 = nexttile(2);
hold(ax2,'on');
box(ax2,'off');
grid(ax2,'on');

X = categorical({'Early\rightarrowMiddle','Early\rightarrowLate'});
X = reordercats(X, {'Early\rightarrowMiddle','Early\rightarrowLate'});

B = bar(X, [mLS; mHS]','grouped');
B(1).FaceColor = lsColor;
B(2).FaceColor = hsColor;

pointData = {deltaLS, deltaHS};
rngState = rng;
rng(jitterSeed, 'twister');
for k = 1:numel(B)
    xk = B(k).XEndPoints;
    dataK = pointData{k};
    pointColor = 0.65 * B(k).FaceColor + 0.35 * [1 1 1];
    for j = 1:numel(xk)
        xj = xk(j) + (2 * rand(nSubjB, 1) - 1) * pointJitter;
        scatter(ax2, xj, dataK(:, j), pointSize, 'o', ...
            'MarkerFaceColor', pointColor, ...
            'MarkerEdgeColor', B(k).FaceColor, ...
            'LineWidth', 0.6, ...
            'HandleVisibility', 'off');
    end
end
rng(rngState);

for k = 1:numel(B)
    xk = B(k).XEndPoints;
    if k == 1
        mk = mLS;
        ek = eLS;
    else
        mk = mHS;
        ek = eHS;
    end
    errorbar(xk, mk, ek, 'k', 'LineStyle','none', 'LineWidth',1, 'CapSize',8);
end

yline(0,'Color',[0.2 0.2 0.2],'LineWidth',0.75);
ylabel('\Delta RMSSD (raw)','FontSize',fontSize);

yl2 = ylim;
pad = 0.05 * range(yl2);

x1 = B(1).XEndPoints(1);
x2 = B(2).XEndPoints(1);
y1 = max([mLS(1)+eLS(1), mHS(1)+eHS(1), max(deltaLS(:,1)), max(deltaHS(:,1))]) + pad;
plot([x1 x1 x2 x2], [y1 y1+pad y1+pad y1], 'k', 'LineWidth',1);
text(mean([x1 x2]), y1+1.6*pad, localSigLabel(pEM), ...
    'HorizontalAlignment','center', 'FontSize',fontSize+2);

x1 = B(1).XEndPoints(2);
x2 = B(2).XEndPoints(2);
y2 = max([mLS(2)+eLS(2), mHS(2)+eHS(2), max(deltaLS(:,2)), max(deltaHS(:,2))]) + pad;
plot([x1 x1 x2 x2], [y2 y2+pad y2+pad y2], 'k', 'LineWidth',1);
text(mean([x1 x2]), y2+1.6*pad, localSigLabel(pEL), ...
    'HorizontalAlignment','center', 'FontSize',fontSize+2);

ylim(ax2, [yl2(1), max([yl2(2), y1 + 2.3 * pad, y2 + 2.3 * pad])]);
legend(ax2, {'Low-stress run','High-stress run'}, 'Location','northwest', ...
    'Box','off', 'FontSize',fontSize);
text(ax2, 0.0, 1.03, 'b', 'Units','normalized', 'FontSize',fontSize+2, ...
    'FontWeight','bold', 'HorizontalAlignment','left', 'VerticalAlignment','bottom');
set(ax2,'FontSize',fontSize);

function label = localSigLabel(p)
if p < 0.001
    label = '***';
elseif p < 0.01
    label = '**';
elseif p < 0.05
    label = '*';
else
    label = 'n.s.';
end
end
