# Uniswap Universal Router 2.3.0 security engagement

Audit the two pinned repository snapshots below. The authoritative file-level scope is [context/scope.json](context/scope.json); its parent-contract and affected-library qualifications are in the [selected judging guidelines](context/judging-guidelines.md#i-sherlocks-standards).

| Repository | Audited revision |
| --- | --- |
| [Uniswap/universal-router](Uniswap__universal-router/) | `26f89e69a88f8dbfd665e38cb3bede27ee03d508` (`dev-2.3.0`) |
| [Uniswap/v4-periphery](Uniswap__v4-periphery/) | `7ed84398b979827150306c8079271a2bc9b2a58b` (`dev-ur-2.3.0`) |

Before assessing or submitting a finding, use the [context map](context/README.md) and [entries inventory](context/entries.json) to check its validity, scope, known status, and severity. In particular:

- [contest context](context/UR-2.3.0-contest-context.md) defines the engagement-specific trust model, exclusions, accepted behavior, and known issues;
- [prior-disclosure locator](context/prior-disclosures.json) makes every locally supplied audit finding searchable; the full reports remain authoritative;
- [selected judging guidelines](context/judging-guidelines.md) govern validity and duplication;
- [severity set](context/severity-set.json) contains the pinned definitions, while the guidelines preserve the additional thresholds and conditions; and
- [deduplication guidelines](context/deduplication-guidelines.md) give the source-referenced merge test.

Build and test prerequisites are in [context/SETUP-SUBMODULES.md](context/SETUP-SUBMODULES.md). The staged `lib/` directories are empty; use the pinned public clones when dependency-complete builds or PoCs are required.
