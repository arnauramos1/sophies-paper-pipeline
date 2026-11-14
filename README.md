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

**The two do not agree and must never be mixed in one figure.** For 9567 the 15-min `pctOpen` is 11.6 % by her
pose pipeline and 18.3 % by Arnau's DLC route — different pose estimation (she uses snout plus centroid, and
reports `pctSnoutCentroidDisagree`) and different zone geometry. Her pipeline is the default here because it is
her paper, it covers every mouse, and it is richer. The DLC route is kept only as an independent cross-check.

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
