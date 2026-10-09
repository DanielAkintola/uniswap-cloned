# Universal Router 2.3.0: contest context

## 1. Overview

The Universal Router (UR) is Uniswap’s stateless swap router. A caller passes a string of one-byte commands plus one ABI-encoded input per command to `execute`. Commands swap on v2, v3 and v4 (v4 through the inherited `V4Router` action runner). They also pull tokens through Permit2, wrap and unwrap ETH, sweep or transfer router balances, call the v3/v4 position managers (migration), bridge through Across, and poke protocol-fee adapters. The router is immutable and ownerless, and is meant to hold no funds between transactions.

**New since the last full audits (2.1.x → 2.3.0).** Most bugs are likely to be here:

- **`RESOLVE` (0x15).** Reads an amount at execution time from a caller-chosen `IAmountResolver` (bounded `staticcall`) into a transient register. Later commands consume it via the `USE_RESOLVED_AMOUNT` sentinel (`type(uint128).max`).
- **`executeNested`.** Opt-in entrypoint that lets a contract that already opened a PoolManager unlock run `V4_SWAP` inside it. `execute` and `executeSigned` refuse to do this (`NestedExecutionNotPermitted`).
- **Protocol fee commands.** `V4_PROTOCOL_FEE_UPDATE` (0x16) and `V3_PROTOCOL_FEE_UPDATE` (0x17) are permissionless pokes of the governance fee adapter.
- **Payments and decoding.**
  - The resolved sentinel is accepted by every exact amount the router moves: Permit2 transfers (single and each batch detail), `WRAP_ETH`, `UNWRAP_WETH_EXACT`, the `ACROSS_V4_DEPOSIT_V3` `inputAmount` and the v4 `SETTLE`/`TAKE` amounts, alongside the swap amounts and `TRANSFER`. `PERMIT2_TRANSFER_FROM_BATCH` now issues one Permit2 `transferFrom` per detail.
  - `UNWRAP_WETH_EXACT` (0x0f) is new.
  - The v2 exact-output delivery check is new.
  - Command inputs are bounds-checked (`checkInputLength`, hardened `BytesLib` / `CalldataDecoder`).
  - Transient slots live in one table (`TransientSlots`).
  - The payments code was refactored.

**Actors**

- **Swappers.** EOAs and smart accounts calling `execute`.
- **Integrators.** Aggregators, vaults and zaps that call UR from contracts, including `executeNested` composers.
- **Relayers.** Submit signed routes.
- **Hooks.** Read `msgSender()` / `signedRouteContext()`.

There are no privileged roles.

**Core flows:** `UniversalRouter.execute(commands, inputs[, deadline])` → `Dispatcher.dispatch` per command → v2 pairs / v3 pools / `PoolManager.unlock` → `V4Router` actions. Variants:

- `executeSigned` (same path, with an EIP-712 signed context).
- `executeNested` (no unlock; runs inside the caller’s).
- `SwapProxy.execute` (plain ERC20 approval instead of Permit2, then forwards to UR).

## 2. Deployment, tokens, integrations

**Chains.** The same contracts are deployed on every chain in `deploy-addresses/`: Ethereum, Arbitrum, Base, Optimism, Polygon, BSC, Avalanche, Blast, Celo, Zora, Worldchain, Unichain, Soneium, Ink, Linea, XLayer, Monad, HyperEVM, Arc, MegaETH, Robinhood and Tempo. See `live_deployments.md`

- Requires EIP-1153 and `PUSH0` (cancun).
- Protocols that don’t exist on a chain point at `UnsupportedProtocol`.
- Arc has no WETH9 (it’s an `UnsupportedProtocol` stub), so WRAP/UNWRAP revert. Celo is deployed with wrapping disabled.
- Ethereum has a public mempool; the L2s are sequencer-ordered.

**Tokens.** Any standard ERC20 and native ETH (6–18 decimals are normal).

- Fee-on-transfer tokens are in scope, apart from the specific behaviours listed in section 6.
- Out of scope:
  - Rebasing tokens (use a wrapped version).
  - ERC777 and other transfer-hook tokens.
  - Tokens whose supply exceeds the limits in 6.M.
  - Any token that is malicious or reverts by design, when the harm is limited to routes that include it.

**Integrations.** All are trusted to behave correctly:

- v4 PoolManager; canonical v2/v3 factories and pools (addressed via CREATE2 init-code hashes).
- Permit2, WETH9.
- v3 NonfungiblePositionManager, v4 PositionManager.
- The Across SpokePool (immutable).
- Governance-installed protocol fee adapters (`PoolManager.protocolFeeController()` / v3 factory `owner()`).
- `PermissionsAdapterFactory`.

## 3. Trust model

**No admin.** UR is immutable, with no owner, pause, upgrade or rescue. Constructor parameters are deployment config and are assumed correct; there are no zero-address checks.

**The caller and their calldata are trusted for their own funds.**

- The command string can move anything the caller approved to UR via Permit2, to any address.
- A malicious frontend or integrator encoding a bad route is not a UR bug. The same applies to `SwapProxy`’s caller-supplied `router` argument.

**User-chosen route components** — tokens, pools, hooks, resolvers, recipients — are untrusted but scoped to the user who chose them. These findings are invalid:

- A malicious hook, token or resolver hurting the user whose route includes it, within that user’s own `amountOutMinimum` / `amountInMaximum` / per-hop bounds.
- A malicious token draining pools of that same token.

Harm to anyone else, or beyond those bounds, is valid.

**“User” means the locker.** That is `msg.sender` of the outermost `execute*`:

- It is `SwapProxy` for proxy calls.
- It is the submitter, not the signer, for `executeSigned`.
- It is the composer for `executeNested`.

`executeNested` callers are assumed to be the contract that opened the surrounding unlock (see 6.G).

## 4. Previous audits

All issues in these reports are known. Acknowledged/unfixed ones are expanded in section 6.

- ABDK, UR v1 (Nov 2022): `audit/ABDK_Uniswap_UniversalRouter_v_2_0.pdf`
- OpenZeppelin, v4-periphery + UR (Aug–Sep 2024): `audit/OpenZeppelin_audit_periphery_universal_router.pdf`
- Spearbit, UR (draft, Sep 2024): `audit/DRAFT_Spearbit_audit_UR.pdf`
- Spearbit, v4-periphery (draft, Sep 2024): `lib/v4-periphery/audits/DRAFT_Spearbit_audit_periphery.pdf`
- ABDK, v4-periphery + UR (draft, Sep 2024): `audit/DRAFT_ABDK_audit_periphery_universal_router.pdf`
- Cantina, Uniswap v4 Security Competition (Sep–Oct 2024): https://cantina.xyz/competitions/e2cf6906-ec8b-4c78-a585-74ac90615659
- OpenZeppelin, UR 2.1 + v4-periphery (Nov 2025): `audit/Universal Router 2.1 And V4 Periphery Audit.pdf`
- OpenZeppelin, SwapProxy + periphery per-hop changes (Feb–Mar 2026): `audit/Universal Router SwapProxy And Periphery Audit.pdf`
- OpenZeppelin, Permissioned Pools + fix reviews (Mar–Sep 2026), and Cantina, Permissioned Pools (2026): `lib/v4-periphery/audits/permissionedPools/`
- OpenZeppelin, UR 2.3.0 + v4-periphery diff (Sep–Oct 2026): `audit/Universal Router 2.3.0 And V4 Periphery Diff Audit.pdf`
- Uniswap bug bounty on Cantina (ongoing): https://cantina.xyz/bounties/f9df94db-c7b1-434b-bb06-d1360abdd1be

Dependencies (out of scope, but their documented behaviours apply): v4-core audits and Known Effects of Hook Permissions (`v4-core/docs/security/`), Permit2 audits.

## 5. Build, test, PoC

```bash
forge install && forge build      # UniversalRouter compiles with optimizer_runs = 1 (size)
forge test --isolate              # unit tests
FORK_URL=<mainnet rpc> forge test --isolate   # also runs the *.fork.t.sol / v2 fork tests
yarn && yarn test:hardhat         # hardhat integration + gas tests
```

Put PoCs in `test/foundry-tests/`.

- v4 and nested-unlock behaviour: copy the setup of `V4SwapWithinUnlock.t.sol`. It uses v4-core `Deployers` for a fresh PoolManager, pools and tokens, a Permit2 mock and `new UniversalRouter(RouterParameters{...})`.
- v2/v3: use `UniswapV2.t.sol` / `UniversalRouter.t.sol` (mainnet fork).
- `RESOLVE`: `Resolve.t.sol` with `mock/MockResolver.sol`.
- Permissioned pools: `permissionedPools/PermissionedV4.t.sol`.
- v4 plans: build them with `@uniswap/v4-periphery/test/shared/Planner.sol`.

## 6. Known issues, accepted risks and design decisions

Submissions matching any item below are invalid.

### A. Router custody and execution model

**Leftover balances belong to whoever spends them next.** UR holds no funds between transactions and never auto-refunds. A later caller can take any token or ETH left in UR at the end of a transaction with `SWEEP`, `TRANSFER`, `PAY_PORTION*`, `CONTRACT_BALANCE` or a v4 `SETTLE` from the router’s balance. Sources of leftovers:

- excess `msg.value`;
- unspent exact-output pre-funding;
- partial fills, and v3 intermediate tokens;
- portion dust;
- `UNWRAP_WETH_EXACT` remainders;
- donations, and forced ETH.

Routes must return everything in the same transaction.

**`FLAG_ALLOW_REVERT` only affects call-based commands:** `PERMIT2_PERMIT(_BATCH)`, `BALANCE_CHECK_ERC20`, `V3_POSITION_MANAGER_PERMIT/CALL`, `V4_INITIALIZE_POOL`, `V4_POSITION_MANAGER_CALL`, `RESOLVE`, the two fee pokes and `EXECUTE_SUB_PLAN`.

- Swaps, transfers, wraps, sweeps and Across revert the whole transaction regardless; wrap them in an allow-revert `EXECUTE_SUB_PLAN` instead.
- Even on call-based commands, checks before the call still hard-revert. Examples: `BALANCE_CHECK_ERC20` on a codeless token, migrator validation, the fee-controller lookup, input-length checks.
- `NestedExecutionNotPermitted` is never swallowed. Any callee the route chose that bubbles that exact 4-byte selector also hard-reverts an allow-revert sub-plan (self-griefing only).
- A call-based command to an address without code reports success. Example: a fee poke where the controller is unset.

**Input decoding is bounds-checked but not strict ABI.** Static fields are read with `calldataload`, trailing bytes are ignored, and `CalldataDecoder` masks offsets and lengths to 32 bits. Malformed input only affects the caller.

**Reentrancy.**

- `execute*` cannot be re-entered while a route is running. This includes hooks, tokens and native `TAKE` recipients calling UR.
- `EXECUTE_SUB_PLAN` is a self-call that bypasses the lock on purpose. It keeps the locker and signed context, does not forward `msg.value` (the ETH balance is shared), and its revert rolls back everything, including transient state.

**`execute(bytes,bytes[])` and `executeNested(bytes,bytes[])` have no deadline,** for composers that enforce their own.

**`BALANCE_CHECK_ERC20` checks an absolute balance** of any owner, not a delta.

**Unassigned command types** (0x18–0x20, 0x22–0x3f, 0x41–0x7f) revert `InvalidCommandType`.

**`ACROSS_V4_DEPOSIT_V3` bridges only from the router’s balance.**

- The amount is `CONTRACT_BALANCE`, a literal, or the resolved sentinel; there is no Permit2 pull. `outputAmount` is always the literal set when the route was built, so a `CONTRACT_BALANCE` or resolved input that comes in lower than expected can leave the deposit unfilled until `fillDeadline` (Across then refunds the depositor), and a higher one pays the extra to the relayer.
- `depositor` and `recipient` are passed raw, with no sentinel mapping.
- It approves the immutable SpokePool for the exact amount.
- It reverts where the native token isn’t ETH.

### B. Payments and Permit2

- **Codeless tokens “succeed”.** Permit2, UR’s `TRANSFER`/`PAY_PORTION` and `SwapProxy` all use solmate `SafeTransferLib`, so they succeed and move nothing for a token address with no code. `SWEEP` reverts on the `balanceOf`.
- **Permit signatures can be front-run.** This applies to Permit2 permits and v3 NPM permits. The route then reverts unless the permit command is allow-revert. With the flag set, it continues on the allowance the front-runner installed. Griefing only.
- **Permit2 pulls only from the locker.** `PERMIT2_TRANSFER_FROM*` uses `from = msgSender()`; there is no arbitrary `from`.
- **`TRANSFER` honours `CONTRACT_BALANCE` only for ERC20.** For ETH, `1 << 255` is taken literally and reverts; use `SWEEP` for ETH. Kept to avoid a breaking change.
- **ETH entry.** `receive()` accepts ETH only from WETH9 and the PoolManager. ETH can still arrive via `msg.value` or forced sends, and is then sweepable (A).
- **Portions round down.**
  - `PAY_PORTION`: `bips > 10_000` reverts.
  - `PAY_PORTION_FULL_PRECISION`: `portion > 1e18` reverts.
  - Dust stays in UR. A zero-amount portion reverts for tokens that reject zero transfers.
- **WETH handling.** `UNWRAP_WETH` unwraps the whole WETH balance (with a minimum); `UNWRAP_WETH_EXACT` leaves the remainder. The return value of `WETH9.transfer` is ignored (ABDK 2022 CVF-32).
- **Permissions adapters in balance commands.** `SWEEP` of a verified permissions adapter sweeps its underlying token. `TRANSFER`, `PAY_PORTION*` and `BALANCE_CHECK_ERC20` use the address as given, so naming the adapter reverts (or reads 0); name the underlying. Fails closed (OZ PermPools fix review N-01).

### C. Uniswap v2

- **Donations can trip per-hop bounds.** With a non-zero `minHopPriceX36`, anyone can transfer tokens to a pair in the path. That hop’s apparent input grows, its price gets worse, and the swap reverts. No funds are lost, and the donation can be recovered with `skim`. A sandwich can cause the same revert without a donation. The fix needs a new per-hop encoding and is deferred.
- **`amountIn == 0` (already paid)** swaps the pair’s whole excess balance, including third-party donations.
- **Exact-output.**
  - The input is computed from reserves, and delivery is checked at the recipient, so FoT or withholding tokens at any hop revert, as do share-rounding tokens such as stETH, which typically deliver 1-2 wei less (by design: exact means exact).
  - `getAmountIn` panics (no custom error) when `amountOut >= reserveOut`.
  - With per-hop checks enabled, a zero-input hop reverts with the pair’s generic error (OZ 2026 L-06).
- **Fixed fee and rounding.** The fee is hard-coded at 997/1000, and `getAmountIn` rounds up by +1 (ABDK 2022 CVF-18/19).
- **CREATE2 pair addresses.** Pairs are derived via CREATE2 without a factory lookup. A route through a non-existent pair transfers in, then reverts.

### D. Uniswap v3

- **Exact-input is not all-or-nothing.** Every hop swaps to the extreme price limit. If a later hop is low-liquidity, it partially fills and the unconsumed intermediate tokens stay in UR (sweepable). If the user’s `amountOutMinimum` is met, the route succeeds. Reported many times; by design.
- **`CONTRACT_BALANCE` exact-input includes tokens anyone sent to the router.** That enlarges the trade, which can trip `minHopPriceX36` and revert. The tokens are recoverable via `SWEEP`. Fix deferred (same as C).
- **`CONTRACT_BALANCE` with `payerIsUser = true`.** The amount is still read from the router’s balance, but it’s pulled from the user through Permit2. So a donation to the router enlarges the user’s trade, up to their Permit2 allowance. There is no real use case for this combination; same as v4 (E). v2 reverts on it.
- **Exact-output.** Output is all-or-nothing. The `MaxInputAmount` cap applies to the first trading hop’s input only; intermediate hops are bounded only by per-hop prices.
- **Fee-on-transfer.** v3 checks pool-reported amounts, so an FoT output token can deliver less than `amountOutMinimum` to the recipient; append `BALANCE_CHECK_ERC20` if needed. FoT input is unsupported (reverts).
- **Callback and path.**
  - The swap callback is authenticated only by the CREATE2-derived pool address. The ~2^80 address-collision attack is a known theoretical issue (v4 competition #244).
  - This derivation is why the contracts don’t work on zkSync-style chains, which have a separate port that is out of scope.
  - Without per-hop prices, trailing path bytes after one pool are ignored.

### E. Uniswap v4 (`V4SwapRouter` + `V4Router`, `DeltaResolver`, `BaseActionsRouter`, `CalldataDecoder`)

- **Supported actions.** `V4_SWAP` supports only the swap actions plus `SETTLE`, `SETTLE_ALL`, `TAKE`, `TAKE_ALL` and `TAKE_PORTION`. Everything else (`DONATE`, `MINT_6909`, `BURN_6909`, `CLEAR`, `SWEEP`, `WRAP`, `UNWRAP`, `CLOSE_CURRENCY`) reverts `UnsupportedAction` (OZ 2024 N-01, PermPools L-06).
- **Settlement.** Any non-zero delta at the end reverts the whole command; `FLAG_ALLOW_REVERT` does not help.
- **Delta sentinels.**
  - `OPEN_DELTA == 0` means “the whole open delta”, never “nothing”. Exact-input reads the input-currency credit; exact-output reads the output-currency debt.
  - `OPEN_DELTA` and the `*_ALL` actions see the router’s entire delta for the unlock, including anything left by earlier actions.
  - `CONTRACT_BALANCE` works only for `SETTLE` (swaps take `uint128`). It settles the router’s whole balance, including other people’s leftovers and donations.
  - With `payerIsUser = true`, it measures the router’s balance but pulls that amount from the user. There is no real use case (v4 competition #411).
  - Tokens sent straight to the PoolManager outside a v4 settle (e.g. `TRANSFER` / `PERMIT2_TRANSFER_FROM` with the PoolManager as recipient) are credited to whoever next calls `sync`/`settle`. This is v4-core flash-accounting design.
- **No ERC6909 fallback.** `TAKE` reverts if the PoolManager lacks the ERC20 balance (v4 competition #22).
- **Router-balance donation trips per-hop bounds.** The standard way to feed router-held tokens into v4 is `SETTLE(CONTRACT_BALANCE)` followed by `SWAP(OPEN_DELTA)`. Anyone who front-runs by sending tokens or ETH to UR enlarges that swap, which can trip `minHopPriceX36` and revert. The donor can sweep the tokens back (same class as C and D).
- **Native settlement ignores `payerIsUser`.** Native `SETTLE`/`SETTLE_ALL` always pays from UR’s ETH balance. Excess `msg.value` stays in UR (A).
- **Slippage bounds.**
  - Bounds exist only on swap actions, `SETTLE_ALL` (max) and `TAKE_ALL` (min). `SETTLE`, `TAKE` and `TAKE_PORTION` take none (Spearbit 2024 5.2.5).
  - `SETTLE_ALL` and `TAKE_ALL` always use `msgSender()` as payer or recipient (v4 competition #259/#434/#435).
  - Swap-level min/max are checked per swap action, not on what is finally taken.
  - `TAKE_PORTION` rounds down on the current credit.
  - No user `sqrtPriceLimit`.
  - Exact-input can partially fill: the user pays less than `amountIn`. If the input was pre-settled, the leftover credit makes the route revert.
  - Exact-output is all-or-nothing on every hop (`V4ExactOutputUnfilled`); over-delivery cannot happen.
  - A multi-hop route through a thin intermediate pool leaves intermediate credit and reverts, unless the plan takes it.
- **Low liquidity vs custom accounting.** If a pool can’t fill `userAmountSpecified + hookDeltaSpecified`, the hook still ends up with its full `hookDeltaSpecified` and the user’s amount is the one that changes.
- **Hook-funded exact-output.**
  - `amountInMaximum` and `minHopPriceX36` bound the caller’s net delta (what the user pays), not the pool’s gross input. A delta-returning hook can therefore subsidize input beyond the cap.
  - A hook may fund an exact-output hop’s entire input. `amountIn == 0` is accepted, the per-hop check is skipped, and the loop stops: upstream pools and their hooks never run. Any input the plan pre-funded stays in UR and must be swept (OZ 2.3.0 N-05).
  - A hook that over-funds the input, or takes more than the whole output, reverts (`SafeCastOverflow`).
- **Hook fees are part of the realized amounts.** Exact-output hook fees count toward `amountInMaximum`; exact-input hook fees reduce `amountOut` and the per-hop price.
- **Per-hop price (`minHopPriceX36`) is best-effort, not a slippage %.**
  - Computed as `amountOut * 1e36 / amountIn` on realized deltas, rounded down.
  - Exact-input divides by the requested `amountIn`.
  - A 0 entry or an empty array disables the check.
  - It can round to 0 for ratios above 1e36.
  - Final `amountOutMinimum` / `amountInMaximum` are the binding protection.
- **`TAKE` semantics.** `TAKE` can run before the input is paid, to any recipient. A native `TAKE` executes recipient code mid-unlock. `TAKE` to `address(0)` is not blocked.
- **Fee-on-transfer.**
  - Exact-output recipients receive `amountOut - fee`.
  - Exact-input checks `amountOutMinimum` before the `TAKE`, so FoT output can under-deliver.
  - FoT input reverts (`CurrencyNotSettled`).
- **Hooks reading `msgSender()` / `signedRouteContext()`** must check `sender == UR` and `msg.sender == PoolManager`. `msgSender()` is the immediate UR caller (proxy, relayer or composer), not the end user.
- **Unreachable edges.** `_getFullDebt` reverts on a delta of `type(int256).min`, which is unreachable (OZ 2024 N-02). Arithmetic is bounded by the supply assumption (M).

### F. `RESOLVE` / resolved amounts

- **The resolver is chosen by the route author and trusted for the value.**
  - It receives all gas but 1/64, so a gas-burning resolver can push the route out of gas.
  - Its revert data is dropped (`ExecutionFailed(i, "")`).
  - It reads state mid-route, which earlier commands or MEV may have moved. Caps still bound every consumer.
- **The literal amount `type(uint128).max` is unusable in sentinel-aware fields.** Only the fields listed in `Constants.USE_RESOLVED_AMOUNT` / README read the sentinel.
- **The register is scoped to the top-level `execute*` call (cleared when it returns) and shared with sub-plans** (OZ 2.3.0 L-04, by design).
  - Any number of commands can reuse it, including several `PERMIT2_TRANSFER_FROM_BATCH` details, which each receive the full resolved amount.
  - A `RESOLVE` inside a successful sub-plan overwrites the parent’s value for later parent commands.
  - A reverted allow-revert sub-plan restores the register to its earlier value rather than clearing it.
  - Plan authors must account for their sub-plans.
- **Failure handling.** A resolver that reverts, returns fewer than 32 bytes, or returns 0 fails the command and clears the register. A later consumer then reverts `ResolvedAmountUnset`.
- **Resolved values aren’t re-checked against other sentinels.** The sentinel is mapped before a command’s own `CONTRACT_BALANCE` check, so a resolved value of exactly `1 << 255` is treated as `CONTRACT_BALANCE`. `TRANSFER` (ERC20), router-paid v2 exact-in, v3 exact-in, `WRAP_ETH`, `ACROSS_V4_DEPOSIT_V3` and v4 `SETTLE` then act on the router’s whole balance. Values too large for a field revert instead (above `uint128` in v4, above `uint160` on Permit2 paths).

### G. Nested execution (`executeNested`)

- **Plain `execute` and `executeSigned` refuse to nest.** They revert `NestedExecutionNotPermitted` on `V4_SWAP` inside a foreign unlock, including inside an allow-revert sub-plan. Signed routes (`executeSigned`) can't run nested, since the signed version of `executeNested` was cut to save contract size.
- **`executeNested` shares the router’s v4 delta account** with every other call made inside the same outer unlock.
  - Debt left by one call can be paid by a later opted-in call’s `SETTLE`/`OPEN_DELTA`/`SETTLE_ALL`, and open credit can be taken.
  - Nothing onchain checks that the caller opened the unlock.
  - A contract that reaches `executeNested` from a function others can call, without opening the surrounding unlock itself, can have its funds used to settle other callers’ debts. This is a documented misuse and accepted by design (NatSpec on `IUniversalRouter.executeNested`).
- **Outside any unlock,** `executeNested` behaves like `execute`.
- **Other v4 commands inside a foreign unlock.** `V4_POSITION_MANAGER_CALL` reverts (`AlreadyUnlocked`). Pool initialization and the fee pokes work, and don’t touch router deltas.

### H. Signed routes (`executeSigned` / `RouteSigner`)

- **The signature is not an authorization over funds.** The payer is the submitter (the locker), never the signer. Signed routes exist so hooks can verify `intent`/`data`.
- **Coverage.** The signature doesn’t cover `msg.value`, resolved amounts or chain state. The signer is recovered, not compared, so consumers must check identity.
- **Submission and replay.**
  - With `verifySender = false`, anyone holding the signature can submit it; a front-runner can burn the nonce (griefing).
  - `nonce == type(uint256).max` disables replay protection until the deadline.
  - There is no nonce cancellation and no ERC-1271.
- **The signed context is publicly readable during execution.** Consumers must check `msg.sender == PoolManager` and `sender == UR`.

### I. `SwapProxy`

- **The locker is `SwapProxy`.**
  - `MSG_SENDER` recipients and `TAKE_ALL` send funds to the proxy, where they are stuck (no rescue).
  - `payerIsUser` pulls fail.
  - Any allowlist keyed on `msgSender()` that admits `SwapProxy` admits everyone.
- **The `router` argument is caller-supplied** (frontend trust; see 3).
- **No sweep and not payable.** The route must sweep to the user’s explicit address; native-input routes should call UR directly.
- **Token edge cases.**
  - A codeless token “transfers” successfully (OZ 2026 L-02, documented).
  - FoT tokens pay the fee twice, user → UR → pool (OZ 2026 N-03).
  - A token’s transfer callback runs while UR is unlocked and can call UR, e.g. to sweep the incoming tokens. Treated as user error for malicious tokens (OZ 2026 N-04).

### J. Migrator and position managers

- **`V4_POSITION_MANAGER_CALL` uses a denylist, not an allowlist.** It must be `modifyLiquidities` with no `INCREASE_LIQUIDITY`, `INCREASE_LIQUIDITY_FROM_DELTAS`, `DECREASE_LIQUIDITY` or `BURN_POSITION`. Every other PositionManager action passes, including the deprecated `MINT_POSITION_FROM_DELTAS` (its derived liquidity has no slippage bound), `TAKE*`, `SWEEP`, `CLEAR_OR_TAKE` and `BURN_6909`.
  - Users must never approve UR (as operator or per token) over v4 positions. Findings that need such an approval are invalid.
  - An allowlist was considered and rejected for gas and complexity.
- **Inside PositionManager actions, `msgSender()` is UR.**
  - A position minted to `MSG_SENDER` is owned by UR and permanently stuck.
  - PositionManager `SETTLE` with `payerIsUser` fails.
  - Use `TRANSFER`-to-PositionManager, then `SETTLE` from its balance, then `SWEEP`.
- **`V4_POSITION_MANAGER_CALL` forwards UR’s entire ETH balance.** Unused ETH stays in the PositionManager, where anyone can sweep it. Command order matters.
- **Funds parked in the PositionManager mid-migration are unprotected** while a later command hands control to external code, e.g. `V4_INITIALIZE_POOL` on a pool with a malicious `beforeInitialize` hook. This is user error (v4 competition #222/#269).
- **v3 migration commands.**
  - `V3_POSITION_MANAGER_PERMIT` only checks the selector, and the permit can be front-run.
  - `V3_POSITION_MANAGER_CALL` allows only `decreaseLiquidity`/`collect`/`burn`, by the token’s owner, approved address or operator.
  - The `collect` recipient is passed through raw.
  - A leftover approval to UR is not usable by third parties, because the caller itself must be authorized for the token. But a user who makes a generic call-forwarding contract their operator also authorizes anyone routing UR calls through that forwarder.

### K. Protocol fee commands (0x16, 0x17)

- **Permissionless.** Anyone can poke any pool. UR only forwards to the governance adapter’s (itself permissionless) `triggerFeeUpdate`.
  - In v4, activating a fee raises the swap fee for later swaps, so a user’s swap in a fresh pool can be preceded by a poke. The fee is governance’s intended value.
  - Fee-family latching by hooks is an adapter-side, out-of-scope issue (OZ fee-controller L-01, won’t fix).
- **Controller lookup.** It happens outside `FLAG_ALLOW_REVERT`, so the command reverts on a chain without that protocol.
- **Missing adapter.** If no v4 adapter is set, the call targets `address(0)` and is a no-op. For v3 the target is the factory `owner()`: if that isn’t a fee adapter, the call reverts (use the flag), and if it has no code, the call is a no-op.

### L. Permissioned pools (`PermissionedV4Router` via UR)

- **Adapter verification is permissionless.** Anyone can verify an adapter for 1 wei (OZ PermPools N-04).
  - UR trusts whichever adapter address the route names.
  - Canonical adapters are curated offchain.
  - An unverified adapter is just an ERC20.
- **Permission subject.** Checks run on `msgSender()`, not the recipient, payer or signer. Relayers, `SwapProxy`, smart accounts and EIP-7702 delegates therefore become the subject (OZ PermPools L-09). The underlying token’s own transfer rules are the final gate.
- **No “swap only” boundary.** A plan of `SETTLE` + `TAKE` with no swap still wraps or unwraps permissioned tokens, as long as swapping is enabled and the caller is allowed (Cantina PermPools 3.2.1, partially fixed).
- **Intermediate-hop adapters net to zero** and skip the router-level checks. Enforcement comes from the hook allowlist and the hook itself, both trusted.
- **Shared underlying.** When two verified adapters share an underlying, `SETTLE(CONTRACT_BALANCE)` on both is order-dependent and the transaction reverts (OZ PermPools L-01).
- **Truncation.** `_payPermissionedFromPayer` uses an unchecked `uint160(amount)`. It isn’t exploitable, because `wrapToPoolManager` requires the full amount (Cantina PermPools 3.4.1).
- **Other behaviours.**
  - `permissionsAdapterFactory == 0` disables permissioned handling.
  - Permission checks run even on zero-amount `TAKE`s.
  - `ALL_ALLOWED` is unused (OZ PermPools N-07).

### M. Token and math assumptions

- **Supply limits.** Token supply is assumed to fit `uint128` (v3/v4), `uint112` (v2) and `uint160` (Permit2 and the other `uint160` amount paths). Issues that need larger amounts are invalid. Examples:
  - casts or truncation above those limits;
  - phantom overflow in `BipsLibrary` or `PAY_PORTION_FULL_PRECISION` (`balance * portion`);
  - the unchecked v2 per-hop multiplication.
- **Rebasing tokens don’t work directly;** use wrapped versions. Yield that accrues natively on Blast is lost.
- **The 2024 v4 competition’s out-of-scope list still applies** (listed in `out-of-scope.md`).

### N. Deployment and code quality (acknowledged)

- **Build and slots.** UR is about 455 bytes under EIP-170 (24,121-byte runtime) and compiled with `optimizer_runs = 1`, so gas-for-size trade-offs are deliberate. Transient slots are fixed literals 1–7.
- **Lock and locker internals.** The lock treats `address(0)` as unlocked, and locker bits aren’t cleaned (documented). The `Lock` modifier contains `_` twice (ABDK 2024 CVF-2/3/20).
- **Style and duplication.** All acknowledged:
  - floating pragmas;
  - function ordering;
  - missing NatSpec and `@custom:security-contact`;
  - per-hop logic duplicated across v2/v3/v4;
  - post-increment loops;
  - redundant casts;
  - pool-address upper bits not cleaned (GH #290).
