function cfg = sp_config()
% SP_CONFIG  Settings for SophiesPaper, the EPM pharmacology project. Deliberately independent of EPM_config /
%  pp_config: nothing here reads Arnau's animals_sessions.xlsx and nothing writes into his results folders.
%
%  Change roots in ONE place. cfg.poseRoot is the only path that points outside Arnau's own area (read-only, with
%  his explicit permission, 14 Nov 2026); if that access ends, copy the summaries into cfg.srcDir and repoint it.

cfg.project = 'SophiesPaper';

% ---- roots ----
cfg.root     = '\\tachyon.fmi.ch\tachyon\groups\scratch\gluthi\ramoarna\stress_project\';
cfg.code     = [cfg.root 'Codes\Matlab\SophiesPaper\'];
cfg.outRoot  = [cfg.root 'Data\Analysis\SophiesPaper\'];          % every output of this project
cfg.behDir   = [cfg.outRoot '1_behaviour\'];                       % DLC cross-check route
cfg.anaDir   = [cfg.outRoot '2_analysis\'];
cfg.figDir   = [cfg.outRoot '10_figures\'];
cfg.srcDir   = [cfg.outRoot '0_source\'];                          % local copies of anything read from elsewhere

% READ-ONLY. Sophie's own analysis tree. Never write under this path.
cfg.poseRoot = '\\tachyon.fmi.ch\tachyon\groups\scratch\gluthi\schmsoph\Data\Analysis\Behavior\';
cfg.poseBatchDir = containers.Map( ...
    {'A11', 'S3'}, ...
    {'BATCHA11_Jan26\EPM\', 'BATCHS3_Sept26\EPM\'});               % A15 mice are inside her S3 EPM block
cfg.poseFile = containers.Map({'5min','15min'}, ...
    {'EPM_PoseEstimation_Summary_5min.csv', 'EPM_PoseEstimation_Summary_15min.csv'});

% ---- behaviour source ----
cfg.source = 'pose';          % 'pose' = Sophie's Python pose pipeline (default, all 66 mice, her paper's measures)
                              % 'dlc'  = Arnau's EPM_dlcBehavior route (34 mice, independent cross-check only)
cfg.poseCut = '15min';        % which of her cuts to use as the primary when source = 'pose'
% The two sources disagree (9567 pctOpen 11.6 % pose vs 18.3 % dlc: different pose estimation and zone geometry).
% Never combine them in one figure. sp_loadPose stamps every table with the source it came from.

% ---- cohort ----
cfg.animalsFile = [cfg.code '0_config\sp_animals.csv'];
cfg.treatments  = {'Vehicle', 'DOI', 'Alprazolam', 'Tabernanthalog'};
cfg.refTreatment = 'Vehicle';

% ---- exclusions ----
cfg.useSophieExclusions = true;   % honour her Excl. EPM flag: drops 7016 (398 s session), 9909, 9928
cfg.extraExclude = [];            % anything Arnau wants out on top
% 9909: her database excludes it everywhere (Status = Dead); Arnau has said it is included in his analyses.
% Unresolved. With useSophieExclusions = true it is dropped. Report both ways for anything that depends on it.
cfg.reportWithAndWithout = [9909];

% ---- analysis ----
cfg.sessionSec = 690;             % every session except 7016 (398 s)
cfg.bins = [0 2.5; 2.5 5; 5 7.5; 7.5 10; 10 11.5];   % minutes, non-overlapping
cfg.cumWindows = [1 2 3 4 5 6 7 8 9 10 11.5];        % minutes, cumulative
cfg.stillThr = 1;                 % cm/s, matches Arnau's cfg.stillThr so the DLC route stays comparable
cfg.alpha = 0.05;
cfg.batchPoolTest = true;         % test vehicle-arm equality across batches before pooling, and refuse if it fails

% ---- provenance ----
cfg.allocationSource = 'Sophie Notion Experiment database, Mice table, exported 14 Nov 2026';
cfg.engineDir = [cfg.code '_engine\'];
cfg.engineManifest = [cfg.engineDir 'MANIFEST.csv'];
cfg.engineSource = [cfg.root 'Codes\Matlab\arnau custom\EPM_AA_paper\'];   % what the engine was copied FROM

for d = {cfg.outRoot, cfg.behDir, cfg.anaDir, cfg.figDir, cfg.srcDir}
    if ~isfolder(d{1}), mkdir(d{1}); end
end
end
