# Variable Glossary

This document describes all variables present in the dataset, both in their **original fbref form** (as returned by `worldfootballR`) and after **renaming** applied in `report.Rmd`.

## Dropped Variables

These columns are removed in the cleaning step because they are administrative or redundant:

| Original Name | Reason for Removal |
|---|---|
| `Competition_Name` | Constant within each sub-dataset |
| `Gender` | Constant (`M`) |
| `Country` | Encoded implicitly by league |
| `Season_End_Year` | Constant (`2024`) |
| `Team_or_Opponent` | Only team rows are retained |
| `Num_Players` | Not relevant to defensive style |
| `Mins_Per_90` | Proxy for matches played; not a defensive metric |
| `Tkl_plus_Int` | Linear combination of `Tkl` and `Int` |
| `Blocks_Blocks` | Sum of `Sh_Blocks` and `Pass_Blocks` |

## Retained Variables

| Original Name | Renamed To | Type | Description |
|---|---|---|---|
| `Squad` | `Squad` | character | Team name |
| `Tkl_Tackles` | `Tkl` | integer | Total tackles attempted |
| `TklW_Tackles` | `TklWin` | integer | Tackles won (ball possession recovered) |
| `Def 3rd_Tackles` | `Def.3rd_Tkl` | integer | Tackles in the defensive third |
| `Mid 3rd_Tackles` | `Mid.3rd_Tkl` | integer | Tackles in the middle third |
| `Att 3rd_Tackles` | `Att.3rd_Tkl` | integer | Tackles in the attacking third |
| `Tkl_Challenges` | `Tkl_Drib` | integer | Dribble attempts successfully countered |
| `Att_Challenges` | `Atmp_Drib` | integer | Total dribble attempts faced |
| `Tkl_percent_Challenges` | `Tkl_Drib.Perc` | numeric | Percentage of dribbles successfully countered |
| `Lost_Challenges` | `Lost_Drib` | integer | Failed attempts to counter a dribble |
| `Sh_Blocks` | `Sh_Blk` | integer | Shots blocked |
| `Pass_Blocks` | `Pass_Blk` | integer | Passes blocked |
| `Int` | `Int` | integer | Interceptions |
| `Clr` | `Clr` | integer | Clearances |
| `Err` | `Err` | integer | Errors leading to an opponent's shot |

## Notes

- All numeric variables are **season totals** (not per-match averages) at the time of data extraction.
- The dataset covers the regular season only; cup competitions are excluded.
- `Tkl_Drib.Perc` is expressed as a percentage (0–100).
