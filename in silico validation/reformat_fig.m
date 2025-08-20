function reformat_fig(fig_files)

x_peb = cell(1,2);
y_peb = cell(1,2);
y_dcm = cell(1,2);
peb_string = cell(1,2);

for i = 1:length(fig_files)
    % Load the figure
    fig = openfig(fig_files{i}, 'invisible');

    % Get all axes in the figure
    ax = findall(fig, 'Type', 'axes');

    % Assume:
    % ax(1) = right subplot (DCM recovery)
    % ax(2) = left subplot (PEB recovery)

    % ---------------------------
    % PEB recovery (left scatter)
    % ---------------------------
    scatter_ax = ax(2);  % Adjust if order is reversed
    scatter_obj = findobj(scatter_ax, 'Type', 'Scatter');
    text_obj = findobj(scatter_ax, 'Type', 'Text');
    peb_string{i} = text_obj.String;

    % Extract data
    x_peb{i} = scatter_obj.XData;
    y_peb{i} = scatter_obj.YData;

    % ---------------------------
    % DCM recovery (right bar)
    % ---------------------------
    bar_ax = ax(1);  % Adjust if needed
    bar_objects = findall(bar_ax, 'Type', 'Bar');

    % There may be multiple bar objects, take the first
    bar_data = bar_objects(1);
    y_dcm{i} = bar_data.YData;
    disp(mean(y_dcm{i}, "all", "omitmissing"));
    disp(std(y_dcm{i}, "omitmissing"));
end

fig = figure;
set(fig, 'Units', 'normalized', 'Color', 'white', 'OuterPosition',...
    [0 1/2 4/5 1/1.3]);
%--------------------------------------------------------------------------
% Subplots a and b: Cue results
%--------------------------------------------------------------------------
% Subplot a
ax_a = subplot(2,2,1);
xy_ax = max(1, ceil(max(abs([x_peb{1}, y_peb{1}]))));
scatter(x_peb{1}, y_peb{1}, 150, 'g', 'filled');
hold on;
plot([-xy_ax, xy_ax], [-xy_ax, xy_ax], 'k--', 'LineWidth', 1.2);
ylim([-xy_ax, xy_ax]);
xlim([-xy_ax, xy_ax]);
grid on;
xlabel('MAP estimates (empirical)');
ylabel('MAP estimates (simulations)');
set(findall(gcf, '-property', 'FontSize'), 'FontSize', 16);
ax_a_ttl = title('a', 'FontSize', 18);
text(0.5, 1.10, 'Cue: second level ', ...
    'Units', 'normalized', ...
    'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'top', ...
    'FontSize', 16, ...
    'FontWeight', 'normal');

% Add RMSE and correlation as top-left annotation
annotation_str = peb_string{1};
axes(ax_a);
x_pos = 0.02;
y_pos = 0.98;
text(x_pos, y_pos, annotation_str, ...
    'Units', 'normalized', ...
    'HorizontalAlignment', 'left', ...
    'VerticalAlignment', 'top', ...
    'FontSize', 14, ...
    'FontWeight', 'normal');

% Subplot b
ax_b = subplot(2,2,2);
bar(y_dcm{1});
xlabel('Instantiation (simulated subject)');
ylabel('Pearson''s \it{r}');
set(findall(gcf, '-property', 'FontSize'), 'FontSize', 16);
ax_b_ttl = title('b', 'FontSize', 18);
text(0.5, 1.10, 'Cue: first level ', ...
    'Units', 'normalized', ...
    'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'top', ...
    'FontSize', 16, ...
    'FontWeight', 'normal');

%--------------------------------------------------------------------------
% Subplots c and d: Taste results
%--------------------------------------------------------------------------
% Subplot c
ax_c = subplot(2,2,3);
xy_ax = max(1, ceil(max(abs([x_peb{1}, y_peb{1}]))));
scatter(x_peb{2}, y_peb{2}, 150, 'g', 'filled');
hold on;
plot([-xy_ax, xy_ax], [-xy_ax, xy_ax], 'k--', 'LineWidth', 1.2);
ylim([-xy_ax, xy_ax]);
xlim([-xy_ax, xy_ax]);
grid on;
xlabel('MAP estimates (empirical)');
ylabel('MAP estimates (simulations)');
set(findall(gcf, '-property', 'FontSize'), 'FontSize', 16);
ax_c_ttl = title('c', 'FontSize', 18);
text(0.5, 1.10, 'Taste: second level ', ...
    'Units', 'normalized', ...
    'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'top', ...
    'FontSize', 16, ...
    'FontWeight', 'normal');

% Add RMSE and correlation as top-left annotation
annotation_str = peb_string{2};
axes(ax_c);
x_pos = 0.02;
y_pos = 0.98;
text(x_pos, y_pos, annotation_str, ...
    'Units', 'normalized', ...
    'HorizontalAlignment', 'left', ...
    'VerticalAlignment', 'top', ...
    'FontSize', 14, ...
    'FontWeight', 'normal');

% Subplot d
ax_d = subplot(2,2,4); %#ok
bar(y_dcm{2});
xlabel('Instantiation (simulated subject)');
ylabel('Pearson''s \it{r}');
set(findall(gcf, '-property', 'FontSize'), 'FontSize', 16);
ax_d_ttl = title('d', 'FontSize', 18);
text(0.5, 1.10, 'Taste: first level ', ...
    'Units', 'normalized', ...
    'HorizontalAlignment', 'center', ...
    'VerticalAlignment', 'top', ...
    'FontSize', 16, ...
    'FontWeight', 'normal');

%--------------------------------------------------------------------------
% Adjustments
set(ax_a_ttl, 'Position', [-1.05 1.10 1.4211e-14]);
set(ax_c_ttl, 'Position', [-1.05 1.10 1.4211e-14])
set(ax_b_ttl, 'Position', [-1.50 1.05 0]);
set(ax_d_ttl, 'Position', [-1.50 1.05 0]);

end