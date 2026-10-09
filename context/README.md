# Context map

- [scope.json](scope.json) — authoritative repository pins and in-scope file arrays.
- [entries.json](entries.json) — filterable inventory of rules, disclosures, sources, affected judging dimensions, authority level, and visibility. Filter `dimensions` for `tf`, `scope`, `known`, or `severity`; an empty array denotes background.
- [prior-disclosures.json](prior-disclosures.json) — report-by-report issue locator. Search `id`, `title`, `summary`, or `source_file`, then open the cited unchanged report for full evidence and resolution notes.
- [judging-guidelines.md](judging-guidelines.md) — selected Sherlock guidelines, preserved exactly.
- [severity-set.json](severity-set.json) — complete ordered pinned severity array. Additional thresholds and conditions remain in the judging guidelines.
- [deduplication-guidelines.md](deduplication-guidelines.md) — source-referenced rules for comparing a target report with a potential duplicate.

The remaining files are unchanged engagement sources and readable audit-report conversions. Their effect and precise source locations are declared in `entries.json`; do not infer authority from a filename or directory.
