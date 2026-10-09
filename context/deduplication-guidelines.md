# Deduplication guidelines

The selected Sherlock rules govern duplication. Engagement context may help apply them but does not override them. [Read the complete source, § XII](judging-guidelines.md#xii-duplication-guidelines).

## Merge test

For a target issue and a potential duplicate, the potential duplicate must satisfy all three conditions:

1. identify the root cause;
2. identify at least a Low impact; and
3. identify a valid attack path or vulnerability path.

Merge only when all three are met. If any is absent, do not merge it with that target; it may still receive another judgment, including solo treatment or duplication with another issue. All findings merged into a family receive the highest severity identified among its duplicates. Severity qualification comes from the [pinned severity set](severity-set.json) together with the full conditions in [guidelines §§ I, III–VII, and IX](judging-guidelines.md). ([Source, guidelines § XII, lines 179–189](judging-guidelines.md#xii-duplication-guidelines))

## Root-cause grouping

Occurrences in different locations or contracts may share a root cause when they repeat the same logic mistake, the same conceptual mistake, or the same category of slippage protection, reentrancy, access control, or front-run/sandwich error. Different underlying implementations, impacts, or fixes may be treated separately. ([Source, guidelines § XII, lines 191–207](judging-guidelines.md#root-cause-groupings))

For reentrancy, compare within the source's five groups: same-function, cross-function, cross-contract, read-only, and cross-chain. Different scenarios of the same reentrancy type within the codebase share a root cause. For front-running, sandwich, and slippage findings, the source groups issues fixable by slippage protection and issues fixable by commit-reveal. ([Source, guidelines § XII, lines 209–222](judging-guidelines.md#root-cause-groupings))

## Family consequences

The engagement reward source defines a family as one root cause: the canonical finding plus all duplicates. Every submitter in a Medium, High, or Critical family splits that family's bonus equally; it specifies no duplicate decay and no first-finder premium for that bonus. The selected Sherlock merge test above still decides family membership. ([Source, reward structure §§ 2 and 7](uniswap-reward-structure.md#2-terms))
