# SophiesPaper — EPM pharmacology pipeline

Sophie Schmid's EPM drug project, kept deliberately separate from Arnau's `EPM_AA_paper` pipeline
(`arnauramos1/epm-aa-imaging-pipeline`). Nothing here reads or writes anything the papers depend on, and nothing
in the papers reads anything here.

Built 14 Nov 2026.

## Scope

Vehicle vs DOI vs alprazolam vs tabernanthalog on the elevated plus maze, pooled across batches, with the
time course of exploration as the central question. Imaging and the two-way avoidance arms are out of scope for
now; the structure leaves room for them (`3_imaging`, `4_avoidance` are reserved names).

## The cohort

From Sophie's Notion **Experiment database** (Mice table), read 14 Nov 2026 and frozen into
`0_config/sp_animals.csv`. The EPM treatment is the `EPM`-prefixed token of her `Group` field **only**: a string
such as `EPMVehTWAALVehTWAAEDOI2` means *vehicle on the maze* and DOI later in TWAA extinction. A substring search
for `DOI` misreads the maze condition — this is the single easiest mistake to make with this dataset.

| treatment | dose | n usable | batches |
|---|---|---|---|
| Vehicle | — | 22 | A11 8, S3 13, A15 1 |
| DOI | 2 mg/kg | 13 | A11 7, S3 6 |
| Alprazolam | 0.5 mg/kg | 14 | A15 13, S3 1 |
| Tabernanthalog | 10 / 50 mg/kg | 7 / 7 | E1 |

Excluded, per her own `Excl. EPM` flag: **7016** (session truncated to 398 s), **9909** (excluded everywhere,
`Status = Dead`), **9928**. Arnau has previously said 9909 is included in his analyses; that conflict is
unresolved and `sp_config` exposes it as a switch rather than deciding it.

Some of Arnau's mice are in this cohort — all of A11 (his batch11) and A15 (his batch15). They belong to her drug
experiment, and their presence here does not put them in his papers: of the 66, only five vehicle mice
(9567, 9572, 9573, 9773, 9931) are in the paper's EPM pool, and no drug-treated mouse is.

## Two behaviour sources, and why that matters

| source | what it is | where |
|---|---|---|
| **`pose` (default)** | Sophie's own Python pose pipeline: 30 measures per mouse incl. protected/unprotected head dips, transition matrices, entropy. Exists for every mouse in both 5-min and 15-min cuts. | her `Data\Analysis\Behavior\<batch>\EPM\EPM_PoseEstimation_Summary_*.csv` (read-only) |
| `dlc` | Arnau's DLC + MATLAB route (`EPM_dlcBehavior`), available for 34 of the 66 | `Data\Analysis\SophiesPaper\1_behaviour\` |

### How much they differ, measured

All 34 mice that have both, 15-min cut vs the full 690 s DLC session:

| measure | DLC (Arnau) | pose (Sophie) | ratio | Spearman |
|---|---|---|---|---|
| open-arm % | 12.67 | 9.28 | 0.73 | **0.96** |
| closed-arm % | 78.83 | 77.94 | 0.99 | **0.95** |
| centre % | 6.86 | 10.21 | **1.49** | **0.95** |
| open entries | 10.0 | 10.5 | 1.05 | 0.86 |
| head dips | 12.5 | 26.5 | **2.12** | 0.83 |
| distance (cm) | 1775 | 2803 | **1.58** | **0.96** |
| mean speed | 2.61 | 3.17 | 1.21 | **0.96** |

**The tracking agrees; the scoring convention does not.** Spearman 0.83–0.96 on every measure means the two
pipelines rank the mice almost identically, and tracking quality is comparable (her missing data 0.14 %, DLC
tracked 98.0 %). The systematic offsets come from two things:

1. **The centre/open boundary.** Her pipeline puts less time in open (×0.73) and more in centre (×1.49) while
   closed is unchanged (×0.99). Open and centre trading off with closed untouched means her centre zone is
   effectively larger, or her open-arm criterion requires the animal further out.
2. **Which body point.** Distance is 1.58× longer and head dips 2.12× more numerous, because the snout travels
   much further than the body centre and crosses the arm edge more often. Her `pctSnoutCentroidDisagree` is a
   median 16 % (range 4–37 %), so she tracks both and knows they diverge.

**Consequences.** Relative comparisons are safe in either pipeline — both independently find DOI anxiolytic
(P = 0.015 on 6v6 by DLC, P = 0.0004 on 13v21 by pose) and both find the vehicle batch effect (open-arm
7.2 vs 12.7 %, P = 0.029 by DLC; 5.97 vs 11.61 %, P = 0.023 by pose). Two different pose methods agreeing is
why that batch effect should be taken seriously. **Absolute values are not interchangeable** and must never be
pooled or cross-quoted in one panel; head dips and distance are the worst offenders.

Her pipeline is the default here because it is her paper, it covers every mouse, and it is richer. The DLC route
is kept only as an independent cross-check.

## Layout

```
0_config/    sp_config.m, sp_animals.m, sp_animals.csv
1_behaviour/ sp_loadPose.m (her summaries), sp_stage4.m (DLC cross-check route)
2_analysis/  sp_drugCompare.m, sp_timecourse.m
10_figures/
_engine/     copies of the shared processing functions + MANIFEST.csv
tools/       sp_makeEngine.m, sp_engineCheck.m
```

Results go to `Data\Analysis\SophiesPaper\` on tachyon, never into `EPM_AA_paper\`.

## The engine, and why it is a copy

`_engine/` holds copies of the few processing functions shared with Arnau's pipeline (zone definition, the DLC
behaviour extractor, plotting helpers). They are **copied, not referenced**, so her results cannot change when he
edits his pipeline — he develops it actively, and pushes to it from more than one machine.

The cost of copying is silent divergence, so every copy is recorded in `_engine/MANIFEST.csv` with its source
path, md5 and the originating commit, and `tools/sp_engineCheck.m` diffs the copy against his live pipeline and
lists drift. Pulling a fix across is then a deliberate act with a record, not an accident. Run it before any
analysis that will be published.

Only ~25 files are copied. Arnau's pipeline is 273 files; the rest is his imaging, heart rate, opto, validation
and figure code, which this project does not use. Copying those would create a second copy of code under active
development for no benefit.

## Imaging readiness — corrected 14 Nov 2026

An earlier note in the project docs said EXTRACT "was never run" on the batch15 alprazolam mice and that a neural
comparison would need 13 movies of ~930 MB reprocessed. **That was wrong, and it was wrong because only Arnau's
folders had been checked.** His `Data\Analysis\batch15\EPM\` holds just the cropped videos. Sophie's
`Data\Analysis\Miniscope\<batch>\EPM\` holds her preprocessing output.

| | vehicle | DOI | alprazolam | TAB |
|---|---|---|---|---|
| `Included Imaging = Yes` | 12 | 8 | 5 | **0** |
| motion-corrected (`.mmap` + `preprocessing_done.json`) | 12 | 8 | 5 | 0 |
| **cells extracted** | **0** | **0** | **0** | 0 |

All 25 imaging-viable mice across A11, S3 and A15 are **already motion-corrected** — each session folder carries a
CaImAn-style `movie_ds2_els__*.mmap` of 3.6–4.9 GB (downsampled ×2, elastic motion correction), plus
`headOrientation.csv`, bad-frame repairs and a pipeline log. The expensive step is done.

**What is missing is cell extraction, for every mouse in the cohort including vehicle and DOI.** Her
`Cells extracted` column is blank for all 66, and her `cnmfe_seed_search` and `settings_search` folders show she
is still tuning parameters rather than having run a final extraction.

So the open decision is not "reprocess movies" but **which extraction route**: her CaImAn/CNMF-E stack, which
consumes the `.mmap` files directly, or Arnau's EXTRACT + cell-sorting + cross-day alignment chain, which expects
a different input format and would need either a conversion or his own motion correction re-run. That choice also
decides whether his sorter (`predictions_v3b`) and alignment code can be reused at all.

Mice with imaging but not preprocessed (e.g. 9900, 9901, 9907, 9908, 9898 in the alprazolam arm) have only
`cropped_video.avi` and `timeStamps.csv`, consistent with their `Included Imaging = No`.

## Data that is read but not owned

Sophie's pose summaries and raw behaviour are read **read-only** from her scratch area
(`...\scratch\gluthi\schmsoph\`), with Arnau's explicit permission given 14 Nov 2026. This pipeline never writes
there. If that permission is withdrawn, the `pose` source needs the summaries copied into
`Data\Analysis\SophiesPaper\0_source\` instead; `sp_config.poseRoot` is the single place to change.

## Known open questions

- The **A15 alprazolam dose is flagged unclear** in her own pharmacology entry (`A15: prep problems, dose
  unclear`), which likely explains the responder split in that arm. Treat A15 alprazolam effect sizes as
  provisional.
- **Vehicle solvent is not matched across batches** (0.9 % NaCl in A11, 2.5 % DMSO in S3/A15) and the vehicle arms
  differ significantly between batches on open- and closed-arm time. `sp_drugCompare` tests this first and refuses
  to pool if it fails.
- What the `Veh` mice actually received is not recorded in the Notion export.
- Her pharmacology entry says DOI increases locomotion; the DLC route finds no distance or immobility change
  relative to A11 vehicle. To be reconciled.
