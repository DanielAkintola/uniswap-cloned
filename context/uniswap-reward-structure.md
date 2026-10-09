# Uniswap engagement: reward structure

How rewards work on the Uniswap Audit Engine engagement: a guaranteed pot, per-family severity bonuses with caps, and a multiplier for issues found in live code.

---

## 1. Summary

The reward has three parts:

| Part | What it is | Who gets paid | Uniswap's maximum |
|---|---|---|---|
| A. Guaranteed pot | $20,000, always paid out | Every valid finding (Low, Medium, High, Critical), split by our usual points formula | $20,000 |
| B. Severity bonuses | A fixed amount per finding family, with a cap per severity | Every submitter in a Medium / High / Critical family, split equally | $400,000 (sum of caps) |
| C. Live-code multiplier | A ×1.15 multiplier (a 15% bonus) for issues in the latest live version of the code | Scales the issue's points in A and its family's bonus in B | Adds no money to A; never pushes B past a cap |

Severity bonus table

| Severity | Bonus per family | Cap for all families of this severity | Families before the cap kicks in |
|---|---|---|---|
| Low | none (pot only) | n/a | n/a |
| Medium | $5,000 | $50,000 | 10 |
| High | $25,000 | $100,000 | 4 |
| Critical | $100,000 | $250,000 | 2 (a 3rd family triggers the cap) |

Uniswap's maximum total payout = $20k (pot) + $50k + $100k + $250k = $420,000.

---

## 2. Terms

- Family: one root cause. A family is the canonical finding plus all of its duplicates, the same thing as a cluster in the platform.
- Submitter: anyone with a finding in a family (the canonical author or a duplicate author).
- Valid finding: an accepted finding from an accepted participant (security researchers and AI auditors). Families found only by Sherlock's internal model runs are not paid and do not use up a cap.
- Live code: the latest live version of the code, meaning the most recent version that is deployed. An issue is in live code only if it exists both in the latest live version and in the in-scope code. Older deployments stay onchain because they can't be removed, but they don't count: an issue that is fixed in the latest live version or in the in-scope code is not valid, even if an older deployment still has it. The Lead Judge (LJ) marks which families are in live code. The latest live deployments are listed in `live_deployments.md`.
- m: the live-code multiplier. It is 1.0 for a normal family and 1.15 for a live-code family. There is one multiplier value for the whole engagement.

---

## 3. Part A: Guaranteed pot ($20,000)

The $20k is always paid. It is split over all valid findings of every severity with our usual formula. Medium/High/Critical submitters get a share of it plus their severity bonus.

Note: 3% of the pot ($600) is a first blood pool. It goes to the earliest submitter in each family, in proportion to the family's points. The other 97% ($19,400) is split by points as described. The examples below leave out the first blood pool for simplicity and split the full $20k by points.

---

## 4. Part B: Severity bonuses (per family, capped)

Each Medium, High, and Critical family earns a bonus. All submitters in that family split it equally. If the bonuses for one severity would add up to more than that severity's cap, the cap is shared over the families instead.

### Formula (no live code)

```
per-family bonus = min(base bonus, cap / number of families)
per-submitter    = per-family bonus / submitters in the family
```

Each severity is computed separately. Mediums only compete with Mediums for the $50k, Highs only with Highs for the $100k, and so on.

---

## 5. Part C: Live-code multiplier

One multiplier `m` = 1.15 is applied in two places:

1. The guaranteed pot. The issue's points are multiplied by the bonus `m`.
2. Severity bonuses. The family's bonus is multiplied by the bonus `m`, but the severity cap still holds. Uniswap pays at most the cap, multiplier included.

### Formula (with live code)

Each family has a weight: `w = m` for live code, `w = 1` otherwise.

```
unit             = min(base bonus, cap / Σw)         Σw = sum of family weights for this severity
family bonus     = unit × w
per-submitter    = family bonus / submitters in the family
```

- Below the cap, a live family gets the full base × m (for example $5,750 for a Medium at ×1.15). The multiplier adds money here, up to the cap.
- At the cap, the cap is shared in proportion to the weights. A live family gets m × what a normal family gets, and the total is exactly the cap.

---

## 6. Worked examples

All amounts are USD, rounded to cents for display. Examples use m = 1.15. Researcher names are made up.

### Example 1: Basic case (several Lows, one Medium with 5 submitters, one solo High)

- 3 solo Lows: Ana, Ben, Cleo
- 1 Medium family found by 5 researchers: Dan, Eve, Finn, Gus, Hal
- 1 solo High: Ivy
- No live code

Pot ($20k):

| Family | Points | Per submitter |
|---|---|---|
| Low ×3 | 2 each | 2 |
| Medium (5 submitters) | 5 × 0.9⁴ = 3.2805 | 0.6561 |
| High (solo) | 20 | 20 |
| Total | 29.2805 | → $683.05 / point |

Bonuses:
- Medium: 1 family, under the cap → $5,000 / 5 submitters = $1,000 each
- High: 1 family, under the cap → $25,000 to Ivy

Payout:

| Researcher | Pot | Bonus | Total |
|---|---|---|---|
| Ana / Ben / Cleo (each) | 1,366.10 | 0 | 1,366.10 |
| Dan / Eve / Finn / Gus / Hal (each) | 448.15 | 1,000.00 | 1,448.15 |
| Ivy | 13,660.97 | 25,000.00 | 38,660.97 |
| Total | 20,000 | 30,000 | 50,000 |

### Example 2: Medium cap reached (12 Medium families, 2 submitters each)

- 12 families × $5k = $60k > $50k cap → per family = $50,000 / 12 = $4,166.67
- Each submitter = $4,166.67 / 2 = $2,083.33
- Total Medium bonus = exactly $50,000

Pot: each family has 5 × 0.9 = 4.5 points, so the total is 54 points → $370.37/point → $833.33 per submitter.
Each researcher gets $833.33 + $2,083.33 = $2,916.67.

### Example 3: Live-code Medium, below the cap

| Case | Normal | With live ×1.15 |
|---|---|---|
| Ana submits a solo Medium | $5,000 | $5,750 |
| Ana and Ben submit the same Medium | $2,500 each | $2,875 each |

### Example 4: Live-code Mediums at the cap (12 families, 6 live)

- Σw = 6 × 1.15 + 6 × 1.0 = 12.9
- unit = $50,000 / 12.9 = $3,875.97 (below the $5k base, so the cap applies)
- Normal family: $3,875.97
- Live family: $3,875.97 × 1.15 = $4,457.36
- Check: 6 × 4,457.36 + 6 × 3,875.97 ≈ $50,000 (the 2-cent gap is display rounding)

Pot: 6 × 5.75 + 6 × 5 = 64.5 points → $310.08/point.

| Researcher | Pot | Bonus | Total |
|---|---|---|---|
| Live Medium (each of 6) | 1,782.95 | 4,457.36 | 6,240.31 |
| Normal Medium (each of 6) | 1,550.39 | 3,875.97 | 5,426.36 |

### Example 5: The multiplier tips a severity over its cap

9 Medium families, 1 live: 8 × $5,000 + 1 × $5,750 = $45,750 ≤ $50k. Paid in full, no cap.

10 Medium families, 1 live: 9 × $5,000 + 1 × $5,750 = $50,750 > $50k. The cap applies:
- Σw = 9 + 1.15 = 10.15 → unit = $50,000 / 10.15 = $4,926.11
- Live family: $5,665.02; each normal family: $4,926.11
- Total = $50,000

Without the live family, 10 Mediums would each get exactly $5,000. The live family's extra 15% comes out of the other nine families, because cap is fixed.

### Example 6: Live-code multiplier in the guaranteed pot (4 Lows, 2 live)

- Live Lows: 2 × 1.15 = 2.3 points; normal Lows: 2 points
- Total = 2.3 × 2 + 2 × 2 = 8.6 points → $20,000 / 8.6 = $2,325.58 / point
- Live Low: 2.3 × 2,325.58 = $5,348.84
- Normal Low: 2 × 2,325.58 = $4,651.16
- Check: 2 × 5,348.84 + 2 × 4,651.16 = $20,000

### Example 7: Only one issue in the whole engagement

| Case | Pot | Bonus | Total |
|---|---|---|---|
| Ana submits the only finding, a Medium | $20,000 (all of it) | $5,000 | $25,000 |
| Same, but in live code | $20,000 (all of it; the multiplier makes no difference to a pool of one) | $5,750 | $25,750 |

---

## 7. Rules at a glance

1. The $20k pot is always paid in full: 3% to the first blood pool, and the rest split over all valid findings by points.
2. Every Medium/High/Critical family gets its bonus in addition to its pot share.
3. The bonus is split equally among the family's submitters. There is no duplicate decay and no first-finder premium.
4. When one severity's bonuses would exceed its cap, the cap is shared across that severity's families, weighted by the live multiplier.
5. The live multiplier:
   - moves pot money toward live findings (the pot does not grow);
   - adds money to bonuses below the cap;
   - only changes the split at the cap.
6. Severities are capped independently. Unused Medium cap does not move to Highs, and so on.
7. There is one multiplier for the whole engagement: ×1.15.

---
