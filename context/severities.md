# Severities

## Critical (severity-def:critical-v2)

Abbreviation: C · Weight: 0.6%

Direct theft of funds without limitations of external conditions and can be triggered at any moment. The loss of the affected party must be significant, excluding unclaimed yield/rewards.

## High (severity-def:high-v2)

Abbreviation: H · Weight: 0.2%

Direct loss of funds with considerable limitations of external conditions, i.e., requires specific but non-extreme conditions. The loss of the affected party must be considerable.

## Medium (severity-def:medium-v4)

Abbreviation: M · Weight: 0.05%

1. Causes a loss of funds but requires certain external conditions or specific states, or a loss is highly constrained. The loss must be relevant to the affected party.
2. Breaks **core** contract functionality, which renders the contract useless or leads to loss of funds that's relevant to the affected party.

## Low (severity-def:low-v4)

Abbreviation: L · Weight: 0.02%

1. Causes a minor loss of funds only under extreme external conditions, or the loss is recoverable by admins.
2. Breaks contract functionality without a direct loss of funds, causing minor disruption of the protocol workflow or requiring admin intervention to resolve the issue.

## Info (severity-def:info-v1)

Abbreviation: I · Weight: 0%

Info is a catch-all severity for any issue that doesn't qualify for Low or higher severity. This includes issues that are technically valid but fall short of Low, as well as issues that are ultimately determined to be invalid. Info severity by itself does not indicate whether an issue is valid or correct and is not rewarded.
