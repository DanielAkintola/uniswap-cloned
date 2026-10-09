# Uniswap engagement: live deployments (latest version)

The live-code multiplier in `uniswap-reward-structure.md` applies only to the **latest live version** of the code. This file lists which version that is and where it's deployed.

Compiled on 2026-10-09 from:

- the `universal-router` GitHub releases and `deploy-addresses/`
- Uniswap's deployments feed (`developers.uniswap.org/deployments.json`, generated 2026-09-22 from `Uniswap/contracts@a677c0d`)
- the v4 deployments docs page

The router addresses in sections 1 and 3 were checked onchain through public RPCs. Runtime size identifies the build: 2.2.0 is 23,233 bytes, 2.1.2 is 24,380 bytes.

---

## Summary

| | Universal Router | v4-periphery code inside it |
|---|---|---|
| Latest live version | 2.2.0 (tag `2.2.0`, commit `64027f3`, released 2026-09-18) | pinned at `a7af5b34` (2026-09-16) |
| Contest code (not deployed) | 2.3.0 (`dev-2.3.0` @ `26f89e6`), built on top of 2.2.0 | `dev-ur-2.3.0` @ `7ed8439` |

- 2.2.0 is deployed on Ethereum, Ink and HyperEVM. Every chain, including those three, also runs 2.1.2 (section 3).
- 2.2.0 = 2.1.x + v4 permissioned pools (`PermissionedV4Router`) + sweeping permissions-adapter currencies as their underlying.

2.2.0 is a newer version than 2.1.2, and it is the version that counts. 2.1.2 still carries most of the onchain volume, but it is the older version.

Every valid issue must exist in the contest code (2.3.0). An issue already fixed in 2.3.0 is not valid, even if a deployed version still has it.

- In 2.3.0 and in 2.2.0 (unfixed in both): counts as live code (×1.15). This holds whether or not 2.1.2 also has it.
- In 2.1.2 but fixed in 2.2.0 or 2.3.0: not valid.
- In 2.2.0 but already fixed in 2.3.0: not valid.
- Only in code new in 2.3.0: valid, but not live code.
- `SwapProxy`: unchanged in every version, so its issues count as live code.

---

## 1. Universal Router 2.2.0: latest live version

| Chain | Chain ID | Address |
|---|---|---|
| Ethereum | 1 | `0xab863E752Bf67D8DCDD929EaAe9Be9dc83Fb3BbB` |
| Ink | 57073 | `0x8BbCAEb326AD590521a921C9e457Ee09F336B48c` |
| HyperEVM | 999 | `0x9aFe3C497e19501DB228F28CdBdD29bC98F65DBa` |

- Source: tag [`2.2.0`](https://github.com/Uniswap/universal-router/releases/tag/2.2.0), built with solc 0.8.26, `optimizer_runs = 1`, Cancun EVM.
- `PermissionedV4Router` routing is enabled on all three: each router was deployed with a non-zero permissions adapter factory (read onchain from `PERMISSIONS_ADAPTER_FACTORY()`).

## 2. SwapProxy: live, the same in every version

`contracts/SwapProxy.sol` and `ISwapProxy.sol` are byte-identical in 2.1.1, 2.1.2, 2.2.0 and `dev-2.3.0`. Every SwapProxy deployment therefore runs the latest version.

| Address | Chains |
|---|---|
| `0x0000000085E102724e78eCd2F45DC9cA239Affad` | Ethereum, Arbitrum, Arc, Avalanche, Base, BNB Chain, Celo, HyperEVM, Ink, Linea, MegaETH, Monad, Optimism, Polygon, Robinhood Chain, Soneium, Unichain, World Chain, X Layer, Zora |
| `0x02E5be68D46DAc0B524905bfF209cf47EE6dB2a9` | Tempo |

## 3. Universal Router 2.1.2: previous version, not the latest

For reference only. 2.1.2 is older than 2.2.0. An issue that exists here but is fixed in 2.2.0 or in the contest code (2.3.0) is **not valid**. An issue that exists here and is still unfixed in both 2.2.0 and 2.3.0 counts as live code. Its `contracts/` folder is byte-identical to 2.1.1, and it pins v4-periphery `545a5d2` (#564), which `a7af5b34` already includes.

On Ethereum, Ink and HyperEVM, 2.1.2 runs alongside the newer 2.2.0 routers in section 1. On every other chain, 2.1.2 is the newest router deployed.

| Chain | Chain ID | Address |
|---|---|---|
| Arbitrum | 42161 | `0x2d01411773c8C24805306E89A41F7855C3c4Fe65` |
| Arc | 5042 | `0x8702463e73f74d0b6765aBceb314Ef07aCb92650` |
| Avalanche | 43114 | `0x661E93cca42AfacB172121EF892830cA3b70F08d` |
| Base | 8453 | `0xd6145b2D3F379919E8CdEda7B97e37c4b2Ca9c40` |
| Blast | 81457 | `0x661E93cca42AfacB172121EF892830cA3b70F08d` |
| BNB Chain | 56 | `0xDc264714F68d84CF29BC605589405E78bDBE7C9f` |
| Celo | 42220 | `0xe2023F3FA515cF070e07fD9d51c1d236e07843f4` |
| Ethereum | 1 | `0x23617e59A5925b2A4Bf75d73ff6711cD0b29De85` |
| HyperEVM | 999 | `0xeD270A1Bcdc63cf1356D695e7f40961d4819d6bF` |
| Ink | 57073 | `0x661E93cca42AfacB172121EF892830cA3b70F08d` |
| Linea | 59144 | `0xDc264714F68d84CF29BC605589405E78bDBE7C9f` |
| MegaETH | 4326 | `0xAedd1CF4C14e833140A61E9C0d2b73a64795c823` |
| Monad | 143 | `0xa6CE4F10d83dBdDAc17E68e1837ca9cE6a1b596e` |
| Optimism | 10 | `0xC09255D86DB563cBc11C2fCf4a0C512e160111B4` |
| Polygon | 137 | `0xDc264714F68d84CF29BC605589405E78bDBE7C9f` |
| Robinhood Chain | 4663 | `0x204FAca1764B154221e35c0d20aBb3c525710498` |
| Soneium | 1868 | `0x661E93cca42AfacB172121EF892830cA3b70F08d` |
| Tempo | 4217 | `0x182a927119D56008d921126764bF884221b10f59` |
| Unichain | 130 | `0xD1b797D92d87B688193A2B976eFc8D577D204343` |
| World Chain | 480 | `0xF025e0Fe9E331A0eF05c2ad3C4E9C64b625cda6f` |
| X Layer | 196 | `0x1cd182C94fcF42277B80DBB9060F88024809E61E` |
| Zora | 7777777 | `0xF025e0Fe9E331A0eF05c2ad3C4E9C64b625cda6f` |

## 4. v4-periphery

v4-periphery has no tags or releases, so "version" here means the commit the code was built from.

None of the in-scope periphery files is deployed as a standalone contract. They are all compiled into the Universal Router, so their live deployments are the 2.2.0 routers in section 1. Their live version is the periphery commit 2.2.0 pins: `a7af5b34`. All 19 files exist at that commit. `PermissionedV4Router` and the permissioned-pools interfaces and library are live only in the 2.2.0 routers, not in 2.1.2.

---
