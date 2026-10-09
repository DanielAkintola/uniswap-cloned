# Cantina Uniswap v4 Security Competition (2024): out-of-scope list

The contest context (section 6.M) says the 2024 v4 competition's out-of-scope list still applies to this engagement. This file records that list so it doesn't have to be looked up on the competition page.

- Source: [Cantina competition page](https://cantina.xyz/competitions/e2cf6906-ec8b-4c78-a585-74ac90615659), "Out of Scope issues" section. Retrieved 2026-10-09.
- Competition dates: 6 Sep – 1 Oct 2024.

Items are paraphrased and keep the order of the original list.

1. Issues already reported in previous security reviews. The reports are in the audit folders of [v4-core](https://github.com/Uniswap/v4-core/tree/main/docs/security/audits), [v4-periphery](https://github.com/Uniswap/v4-periphery/tree/35e00119fc82730fd875abf5c4c5785f1f127e48/audits) and [universal-router](https://github.com/Uniswap/universal-router/tree/dev/audit).
2. Effects described in v4-core's [Known Effects of Hook Permissions](https://github.com/Uniswap/v4-core/blob/main/docs/security/Known_Effects_of_Hook_Permissions.pdf).
3. A v3 multi-hop swap whose later hop is in a low-liquidity pool can leave intermediate tokens in the router when the user's slippage limit is still met.
4. Permit2 calls succeed for a token address with no code.
5. Low-liquidity pools can break the custom-accounting invariant in swaps: if a pool can't fill the user's specified amount plus the hook's delta, the hook still ends up with its full delta and the user's amount changes.
6. A malicious token can drain every pool that uses that token, but not pools of other tokens.
7. In v3, `amountSpecified` was positive for exact-input and negative for exact-output. In v4 it is the reverse: negative for exact-input, positive for exact-output. It represents the change in the user's balance.
8. As in v3, the code assumes no token's total supply exceeds `type(uint128).max` (2^128 - 1).
9. Rebasing tokens don't work directly as v4 liquidity; only wrapped versions should be used. Wrapping can be automated with hooks and `BeforeSwapDelta`.
10. Admin / permissioned roles: the PoolManager owner can set the protocol fee controller. Even a malicious fee controller should not be able to prevent new pools from being initialized, or exceed the maximum allowed protocol fee on any pool.
11. Yield that accrues natively on Blast is lost.
12. 1 wei of a token may be left behind when removing liquidity from a v4 position (see [v3-core #570](https://github.com/Uniswap/v3-core/issues/570)).
