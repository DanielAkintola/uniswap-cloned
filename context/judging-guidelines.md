# Criteria for Issue Validity

This guide aims to provide clarity for both Watsons & protocols on various categories of issues that are valid under Sherlock's judging. Sherlock focuses on Critical, High, Medium and Low severity findings.

### I. Sherlock's standards:

1. **Subjectivity:** Despite these guidelines, we must understand that because of the complexity & subjective nature of smart contract security, there may be issues that are judged beyond the purview of this guide. However, for the vast majority of cases, this guide should suffice. Sherlock's chosen judges continue to have the last word on considering any issue as valid or not.
2. **Hierarchy of truth:** If the protocol team provides no specific information, the default guidelines always apply.

   If the protocol team includes specific information in the CODE COMMENTS, that information may be used as context during the judging process. The judge can decide that CODE COMMENTS are outdated. In that case, the default guidelines apply.

   > Example: The code comments state that "a swap can never fail" even though the code is built to support failing swaps.

3. The Sherlock Judge can use public statements up until 24h before the engagement ends to override the language in the chosen source of truth.

   If guidelines are updated, the new guidelines apply only to engagements that start after the date of change. The specific guidelines applied to each engagement are available in the engagement workspace.

   **Historical decisions are not considered sources of truth.**
   
4. **Could Denial-of-Service (DOS), griefing, or locking of contracts count as a valid issue?** To judge the severity we use two separate criteria:

   1. The issue causes funds to be locked for more than a week.
   2. The issue impacts the availability of time-sensitive functions (cutoff functions are not considered time-sensitive).

   If at least one of these is describing the case, the issue can be Medium. If both apply, the issue can be considered High severity. Additional constraints related to the issue may decrease its severity accordingly. Critical severity applies to a permanent lock of funds: funds that cannot be rescued by the protocol, where the contracts are also non-upgradeable.

   If a single occurrence of the attack results in a denial of service (DOS) for less than a week, the issue should be evaluated based on a **single occurrence** of the attack, even if it can be repeated indefinitely. It qualifies as a medium-level issue only if it disrupts a clearly time-sensitive function.

   > Note: if the single occurrence of the attack is relatively long (e.g. >2 days), and it takes only 2-3 iterations to cause a 7-day DOS, it may be considered a valid finding.
5. **(External) Admin trust assumptions**:\
   The internal protocol roles are trusted by default (including admins in the integrated protocols). They can be considered untrusted (i.e. act maliciously) only if the user can get the role without admin/owner permission (e.g. paying a specific fee). Admin functions are generally assumed to be used correctly and not harm users/the protocol.

6. **Contract Scope:**
   1. If a contract is in the engagement Scope, then all its parent contracts are included by default.
   2. In case the vulnerability exists in a library and an in-scope contract uses it and is affected by this bug, this is a valid issue.
   3. If there is a vulnerability in a contract from the engagement repository but is not included in the scope then issues related to it cannot be considered valid.
7. **Design decisions** are not valid issues. Even if the design is suboptimal, but doesn't imply any loss of funds, these issues are considered invalid.

### II. Audit Engine Mechanics

1. **Audit Engine Payout Criteria.** The account it eligible to receive the payout only if it passes the following thresholds:
   1. Submit at least 2 valid issues accross all Audit Engine engagements
   2. Your **Issues Ratio** must be >=20%. Issues Ratio is calculated as `# of valid issues submitted / total # of issues submitted`. The number of valid issues includes "Accepted" issues with Critical, High, Medium, Low or Info severity. 
   
   If the account doesn't pass at least one of the thresholds, the rewards are frozen until both requirements are met. Once it happens, all frozen rewards are paid out in the next payment batch.
   
2. **Statuses.** After the issue is judged, it receives one of the three statuses:

   1. **Accepted** - the issue is valid and will be accounted as +1/1 in the Issues Ratio. 
   2. **Dismissed** - the issue is invalid (i.e., doesn't qualify for any of the Severity definitions) and will be considered as +0/1 in the Issues Ratio.
   3. **Neutral** - the issue is not rewarded, but will **not** be accounted in the Issues Ratio.

3. **Judging verdicts.** The Lead Judge triages the issue based on several verdicts:
   1. **True Finding** - determines whether the issue is technically correct (True) or not (False).
   2. **Scope** - determines whether the issue is in scope or not.
   3. **Known** - determines whether the issue is known or not.
   4. **Duplicate** - determines whether the issue is a duplicate of any earlier submitted finding or not.
   5. **Severity** - the severities can be Info, Low, Medium, High or Critical. Note: the severity doesn't mean the finding is valid, and Info is set on every report, that doesn't qualify for Low or higher severity. For example, the issue can be Info and False, if the issue is indeed invalid.

4. **Protocol Team judging**. After the Engagement finishes, the protocol team has the ability to override any decision made by the Judge. If the protocol team invalidates an issue deemed as valid by the Judge, the issue will receive "Neutral" status and will not be accounted towards the Issues Ratio.
5. **Rewrite & Resubmit.** Once the Security Researcher submits an issue, it cannot be withdrawn/closed or edited. To update the issue, the Security Researcher needs to "Rewrite & Resubmit" it. This creates a new submission linked to the previous one. The original submission and all of its resubmissions form one chain.

   1. Rewrite & Resubmit is available only during the Audit Engine submission window, and only on the latest submission in the chain. A chain can have at most 5 resubmissions.
   2. The new submission replaces the previous one. Earlier versions are no longer judged, and their verdicts no longer count. If the previous version was already Accepted, that acceptance is replaced by the new version's verdict, even if the new version is Dismissed. Resubmit only if the new version is clearly better than the current one.
   3. The resubmission is judged under these guidelines like any other submission, on its own merits. The judge also sees the earlier versions, their verdicts and the diff from the previous version, and checks whether the rewrite fixes the problems found in the earlier judgments.
   4. Rewrite & Resubmit can only be used to improve the same finding, e.g., its explanation, impact, severity, PoC or recommended fix. The resubmission must keep the same root cause, vulnerable code path and attack vector as the earlier versions. If it describes a different issue, the judge marks it as **Too Different** and it is automatically Dismissed, even if the new issue is valid. A Too Different resubmission still replaces the earlier version, so an Accepted original is lost too. To report a different issue, submit it as a new issue.
   5. **Issues Ratio.** The whole chain counts as **one issue**, and only the verdict of its latest version is used:
      1. Numerator: +1 if the latest version is Accepted, +0 otherwise. A chain never adds more than 1 to the numerator, no matter how many times it's resubmitted.
      2. Denominator: +1 for the original submission and +0.5 for every resubmission.
      3. If the latest version is Neutral, the original's +1 is not counted, but each resubmission still adds +0.5 to the denominator.
6. The final decision by the Lead Judge cannot be disputed or escalated (except if "rewritten and resubmitted" during the Audit Engine submission window), so it's recommended to check and submit the best version of the report initially.


### III. Critical severity definition:

1. Direct theft of funds without limitations of external conditions and can be triggered at any moment. The loss of the affected party must be significant, excluding unclaimed yield/rewards.

**Guidelines for Significant Loss:**

* Users lose more than 20% *and* more than $100 of their principal.

### IV. High severity definition:

1. Direct loss of funds with considerable limitations of external conditions, i.e., requires specific but non-extreme conditions. The loss of the affected party must be considerable.

**Guidelines for Considerable Loss:**

* Users lose more than 1% *and* more than $10 of their principal.
* Users lose more than 1% *and* more than $10 of their yield.
* The protocol loses more than 1% *and* more than $10 of the fees.

### V. Medium severity definition:

1. Causes a loss of funds but requires certain external conditions or specific states, or a loss is highly constrained. The loss must be relevant to the affected party.
2. Breaks **core** contract functionality, which renders the contract useless or leads to loss of funds that's relevant to the affected party.

> Note: If a single attack can cause a 0.01% loss but can be replayed indefinitely, it will be considered a 100% loss and can be assigned higher severity, depending on the constraints.

**Guidelines for Relevant Loss:**

* Users lose more than 0.01% *and* more than $10 of their principal.
* Users lose more than 0.01% *and* more than $10 of their yield.
* The protocol loses more than 0.01% *and* more than $10 of the fees.

### VI. Low severity definition:

1. Causes a minor loss of funds only under extreme external conditions, or the loss is recoverable by admins.
2. Breaks contract functionality without a direct loss of funds, causing minor disruption of the protocol workflow or requiring admin intervention to resolve the issue.

**Guidelines for Minor Loss:**

* Users lose more than 0.001% *and* more than $1 of their principal.
* Users lose more than 0.001% *and* more than $1 of their yield.
* The protocol loses more than 0.001% *and* more than $1 of the fees.


> **Note**
> 
> Likelihood is not considered when identifying the severity and the validity of the report.

### VII. Info severity

Info is a catch-all severity for any issue that doesn't qualify for Low or higher severity. This includes issues that are technically valid but fall short of Low, as well as issues that are ultimately determined to be invalid. Info severity by itself does not indicate whether an issue is valid or correct. The issue's status (Accepted, Dismissed, or Neutral, see section "Audit Engine Mechanics") is determined by additional verdicts from the Lead Judge.

### VIII. Edge case reward distribution

In this Audit Engine Engagement, only Low-or-higher-severity issues are rewarded and considered in award distribution. However, if no valid Low-or-higher-severity issues are identified, the available guaranteed pot is distributed.

In this scenario, all participants who found at least one Accepted Info will receive an equal share of the guaranteed pot. For example, the engagement finishes with no Accepted Low or higher severity issues, but there are 200 participants who found at least one Accepted Info. These participants will receive an equal share of the guaranteed pot.

In case there are no Accepted Info issues, the Guaranteed pot will be distributed equally among all participants.

### IX. Proof of Concept requirements:

1. A coded and executable PoC (Proof of Concept) is mandatory for any Critical or High severity issue, and is heavily recommended for Medium severity issues. If the original report does not include a Proof of Concept (PoC), it can be considered invalid.

2. Issues that depend on front-running will get their severity downgraded if the deployment chain has a private mempool. High will be Medium, and Medium will be Low.

> For example, if we have a standard front-running slippage-related issue on DEX, which deserves High severity under normal circumstances (e.g. front-running on Eth Mainnet), should be viewed as Medium on chains with private mempool (e.g. Optimism). Also, the reports have to explain how the issue can happen with unintentional front-running, e.g. saying "the attacker will monitor the mempool looking for the victim's transaction" is invalid.

### X. List of Issue categories that are not considered valid:

1. **Gas optimizations:** The user/protocol ends up paying a little extra gas because of this issue.
2. **Incorrectly calculated/wrong values in emitted events** are not considered a valid issue.
3. Check to make sure input values are not zero addresses are **not** considered valid issues.
4. **User input validation to prevent user mistakes** is not considered a valid issue. However, if a user input could result in a major protocol malfunction or significant loss of funds for other parties (protocol or other users) and it qualifies for in-scope severity definitions, then it can be valid.
5. **Admin Input/call validation:**
   1. Admin could have an incorrect call order. Example: If an Admin forgets to `setWithdrawAddress()` before calling `withdrawAll()` This is not a valid issue.
   2. An admin action can break certain assumptions about the functioning of the code. Example: Pausing a collateral causes some users to be unfairly liquidated or any other action causing loss of funds. This is not considered a valid issue.
6. **If a protocol's smart contracts or admin addresses get added to a "blacklist"** and the functionality of the protocol is affected by this blacklist, this is not considered a valid issue.
7. **Front-running initializers** where there is no irreversible damage or loss of funds & the protocol could just redeploy and initialize again is not a valid issue.
8. **User getting blacklisted** by a token/contract causing **harm only to themselves** is **not** a valid issue.\
   However, if the malicious actor can use a blacklisted address and harm other parties (protocol or other users), and it qualifies for in- scope severity definitions, then it can be considered valid.
9. Issues assuming future opcode gas repricing are not considered to be valid issues.\
    **Use of call vs transfer** will be considered as a protocol design choice if there is no good reason why the call may consume more than 2300 gas without opcode repricings.
10. **Users accidentally or intentionally directly transferring any tokens** (native, ERC20, etc.) into the in-scope contracts, while it is not a part of the expected protocol operations, and the contract doesn't have a way to retrieve them, is **not** a valid issue and is considered a user mistake, if the user hurts themselves only. However, if it leads to hurting the protocol and/or other users, it may be considered a valid issue (if qualifies for in-scope severity definitions).
11. **Loss of airdrops** or any other rewards that are not part of the original protocol design is not considered a valid issue.
12. **Incorrect values in View functions** are by default considered **invalid**.\
    **Exception**: In case any of these incorrect values returned by the view functions are used as a part of a larger function which would result in loss of funds then it can be considered valid if it qualifies for in-scope severity definitions.
13. **Stale prices and Chainlink round completeness** Recommendations to implement round completeness or stale price checks for any oracle are invalid.

    > Exception: the recommendation to implement stale price checks **may** be valid. For [example](https://github.com/sherlock-audit/2024-12-mach-finance-judging/issues/41), the protocol may be using Pyth pull-based oracle, which requires requesting the price before using it. Hence, if we don't request the price first, or check it for staleness, then we can end up using very old price (e.g. from 1 hour/day ago).
14. Issues from the previous audits (available in known-issues) marked as acknowledged (not fixed) are not considered valid.
15. **Chain re-org** and **network liveness** issues are not valid. However, if the underlying protocol is blockchain and the malicious actor can force a chain re-org affecting the protocol and the users, it can be a valid issue if it qualifies for in-scope severity definitions.
16. Issues where users cannot safemint ERC721 tokens due to unsupported implementation are not valid.
17. **Future issues:** Issues that result out of a future integration/implementation that was not mentioned in the docs/README or because of a future change in the code (as a fix to another issue) are **not** valid issues.
18. Issues related to **tokens with non-standard behaviors**, such as [weird-tokens](https://github.com/d-xo/weird-erc20) are not considered valid by default. Tokens with decimals between 6 and 18 are not considered weird.
19. Using Solidity versions that support **EVM opcodes that don't work** on networks on which the protocol is deployed is not a valid issue beacause one can manage compilation flags to compile for past EVM versions on newer Solidity versions.
20. **Sequencers** are assumed to operate reliably without misbehavior or downtime. Vulnerabilities or attacks that rely on sequencers going offline or malfunctioning are invalid.
21. **Lack of storage gaps** in parent contracts are not considered valid issues.

### XI. List of Issue categories that are considered valid:

1. **EIP Compliance:** For issues related to EIP compliance, the protocol & codebase must show that there are important external integrations that would require strong compliance with the EIP's implemented in the code. The EIP must be in regular use or in the **final state** for EIP implementation issues to be considered valid. The EIP-related issues must qualify for Low or higher severity definitions to be considered valid.
2. **Identifies the core issue:** In case of issues that have a large number of duplicates, Issues that identify the core issue and show valid loss of funds should be grouped.
3. **Out of Gas:** Issues that result in Out of Gas errors either by the malicious user filling up the arrays or there is a practical call flow that results in OOG can be considered a valid issue depending on conditions and constraints. **Exception:** In case the array length is controlled by the trusted admin/owner or the issue describes an impractical usage of parameters to reach OOG state then these submissions would be considered as **low**.
4. **Chainlink Price Checks**: Issues related to minAnswer and maxAnswer checks on Chainlink's Price Feeds are considered low only if the Watson explicitly mentions the price feeds (e.g. USDC/ETH) for the in-scope tokens on the in-scope chains that require this check. **Additionally**, a proper attack path and at least medium severity impact must be included in the report. See [this](https://stackoverflow.com/questions/78558661/which-chainlinks-price-feeds-still-have-minanswer-and-maxanswer-checks) to know if min/maxAnswer are deprecated on the price feed.

### XII. Duplication guidelines:

The duplication guidelines assume we have a "target issue", and the "potential duplicate" of that issue needs to meet the following requirements to be considered a duplicate.

1. Identify the root cause
2. Identify at least a Low impact
3. Identify a valid attack path or vulnerability path

Only when the "potential duplicate" meets all three requirements will the "potential duplicate" be duplicated with the "target issue", and all duplicates will be awarded the highest severity identified among the duplicates.

Otherwise, if the "potential duplicate" doesn't meet all requirements, the "potential duplicate" will not be duplicated but could still be judged any other way (solo, a duplicate of another issue, invalid, or any other severity)

**Root cause groupings**

If the following issues appear in multiple places, even in different contracts. In that case, they may be considered to have the same root cause.

1. Issues with the same logic mistake.

   > Example: uint256 is cast to uint128 unsafely.
2. Issues with the same conceptual mistake.

   > Example: different untrusted external admins can steal funds.
3. Issues in the category
   * Slippage protection
   * Reentrancy
   * Access control
   * Front-run / sandwich ( issue A that identifies a front-run and issue B that identifies a sandwich can be duplicated )

If the underlying code implementations, impact or fixes are different, then they may be treated separately.

For the root cause categories above, the duplication should be based on the following groups:

1. Reentrancy:

   * [Reenter in the same function](https://github.com/sherlock-audit/2024-03-zap-protocol-judging/issues/157);
   * [Cross function reentrancy](https://github.com/sherlock-audit/2022-11-bullvbear-judging/issues/88) (in a different function inside the contract);
   * Cross contract reentrancy (in a different contract within the codebase);
   * [Read-only reentrancy](https://github.com/sherlock-audit/2022-11-bond-judging/issues/23).
   * [Cross-chain reentrancy](https://medium.com/immunefi/the-ultimate-guide-to-reentrancy-19526f105ac#8256).

   If several reports find different scenarios for the same type of reentrancy within the codebase, they should be considered to have the same root cause.
2. Front-running/sandwich/slippage protection:
   * Can be fixed by slippage protection;
   * Can be fixed by a commit-reveal mechanism (e.g. the user front-runs the admin, who's trying to blacklist them).

### XIII. Best practices:

1. Read the engagement `context/` and documents thoroughly.
2. Submit issues that are considered valid according to Sherlock guidelines based on your discretion
3. Do not submit multiple issues in a single submission. Even if the 2 completely different issues occur on the same line, please make sure to separately submit them.\
   Below is a valid example where multiple occurrences can be combined into one issue: [Example](https://github.com/sherlock-audit/2022-11-dodo-judging/issues/47).\
   Also, there could be multiple occurrences of an issue but they may need to be submitted separately as each occurrence does not need to be an obvious repetition like the `safeTransfer` example. Watsons must use their own discretion in such cases.
4. Be specific and sufficiently descriptive when describing an issue's impact. Bad: Loss of funds for the user Good: Loss of funds for users as there is no access control for the ‘withdraw’ function
5. **Do not add** unnecessarily **long code snippets** into the submission. Keep the code snippet limited to the scope of the impact, and be as descriptive as possible in the Vulnerability Detail sections.
6. Do not copy-paste issues from other engagements/contests/reports/past audits. They are extremely unlikely to be valid to the respective engagement.

This guide shall be regularly updated as more engagements are judged and with evolving Smart contract security principles, the judging standards are subject to change over time.

### XIV. Glossary

**Attack Path**: A sequence of steps or actions a malicious actor takes to cause losses or grief to the protocol or users and/or gain value or profit.

**Front-run**: There is operation A; if executed, it typically has no losses for anyone. If some other operation B executes before A, either in the same transaction or a separate transaction, there is a loss of some sort for either the protocol or some user(s) (it can be the same user)

**Root Cause**: The primary factor or a fundamental reason that imposes an unwanted outcome

**Sandwich**: A front-run, followed by operation C controlled by the attacker who also executed operation B. The goal of operation C is to revert the contract to its initial state.

**Vulnerability Path**: A sequence of steps showcasing how an issue causes losses or grief to the protocol or users through well-intended usage of the protocol.