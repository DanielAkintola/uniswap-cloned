# Setup

The download has empty `lib/` folders because git submodules are not included. Clone from GitHub instead; both repos are public.

## universal-router

```bash
git clone https://github.com/Uniswap/universal-router.git
cd universal-router
git checkout 26f89e69a88f8dbfd665e38cb3bede27ee03d508
git submodule update --init --recursive
yarn install
forge build
FORK_URL=<mainnet archive RPC URL> forge test
```

## v4-periphery

```bash
git clone https://github.com/Uniswap/v4-periphery.git
cd v4-periphery
git checkout 7ed84398b979827150306c8079271a2bc9b2a58b
git submodule update --init --recursive
forge build
forge test
```

## Notes

- In `universal-router`, run `yarn install` before `forge build`.
- Fork tests need `FORK_URL` set to a mainnet archive RPC. Without it, 7 of `universal-router`'s 26 test suites fail at setup.
