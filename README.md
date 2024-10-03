# TTG (Two Token Governance)

A TTG, "Two Token Governance" is a governance mechanism that uses token voting to maintain lists and manage communal property. As its name implies, it primarily optimizes for token holder participation. A TTG is primarily used for **permissioning actors** and should not be used for funding/financing decisions.

## Development

### Installation

You may have to install the following tools to use this repository:

- [foundry](https://github.com/foundry-rs/foundry) to compile and test contracts
- [lcov](https://github.com/linux-test-project/lcov) to generate the code coverage report
- [yarn](https://classic.yarnpkg.com/lang/en/docs/install/) to manage npm dependencies
- [slither](https://github.com/crytic/slither) to static analyze contracts

Install dependencies:

```bash
yarn
forge install
```

### Compile

Run the following command to compile the contracts:

```bash
forge compile
```

### Coverage

Forge is used for coverage, run it with:

```bash
yarn coverage
```

You can then consult the report by opening `coverage/index.html`:

```bash
open coverage/index.html
```

### Test

To run all tests:

```bash
forge test
```

Run test that matches a test contract:

```bash
forge test --mc <test-contract-name>
```

Test a specific test case:

```bash
forge test --mt <test-case-name>
```

To run slither:

```bash
yarn slither
```

### Code quality

[Prettier](https://prettier.io) is used to format Solidity code. Use it by running:

```bash
yarn prettier
```

[Solhint](https://protofire.github.io/solhint/) is used to lint Solidity files. Run it with:

```bash
yarn solhint
```

Or to autofix some issues:

```bash
yarn solhint-fix
```

### Documentation

Forge is used to generate the documentation. Run it with:

```bash
yarn doc
```

The command will generate the documentation in the `docs` folder and spinup a local server on port `4000` to view the documentation.

## TTG Smart Contract Architecture

<img width="1098" alt="ttg" src="https://github.com/MZero-Labs/ttg/assets/1220854/58866111-26f6-495d-8949-9cef00783f7c">





### X Financial Technologies

1. Visit our [website](https://x-financial-technologies.replit.app/)
2. Follow us on [X](https://x.com/amr_080)
3. Invest in [USDX](https://x-ledger.replit.app/)
4. Connect with us on [LinkedIn](https://www.linkedin.com/company/xfintech)

USDX is a tokenized US treasuries fund. We optimize cash management and yield for institutions.

### Why USDX?

Money market funds
1. Increased AUM
2. Enhanced liquidity
3. Reduced funding and cash flow volatility
4. Greater counterparty diversification
5. Support for capital preservation
6. Yield enhancement opportunities

Investors
1. Yield on idle cash balances
2. Low minimum investment
3. Instant mint and redemption 24/7/365
4. Frictionless collateral mobility

How is yield transferred to the tokenholder and how often?

USDX is available in two versions, an accumulating token (USDX) and a rebasing token (rUSDX). While both versions pay out yield upon redemption and accrue yield daily, the manner in which the accrual is represented differs.
For USDX, the accruing yield gets ‘accumulated’ into the token price. As the underlying investments accrue yield daily, we recognize this yield by increasing the Net Asset Value (NAV) of the underlying Fund, thereby increasing the NAV per USDX token. We typically update the price once every Business Day, generally at around 6pm ET.
rUSDX, on the other hand, is intended to maintain a price of $1.00 per token, with the accruing yield represented by the division of rUSDX tokens into more tokens via rebasing. See our support documentation to learn more.
As an example, let’s say you held 1 USDX token worth $100 and 100 rUSDX tokens worth $1.00 each. The next day the NAV per USDX token increased to $101 per token. After the price update and rebasing, your holdings of both rUSDX and USDX would be worth $101.00 each ($202.00 in total). You would still have a balance of 1 USDX token worth $101.00. However, due to the rebasing nature of rUSDX tokens, you would now hold 101 rUSDX tokens worth $1.00 per token.

Why tokenized money market funds?

Money Market Funds (MMFs) become more stable if investors can use their MMF shares directly as collateral, instead of selling them for cash. This reduces pressure on MMFs during market stress.
Traditional: Investor sells MMF shares to get cash for margin call, causing fund outflows.
Tokenized: Investor uses MMF shares/tokens directly as collateral, avoiding sale and fund outflows.
Tokenized Money Market Fund:
1. Investor buys tokenized MMF shares
2. Shares held digitally in investor's wallet
3. Investor can use tokens as collateral without selling
4. Yield accrues to tokens (via price increase or rebasing)
5. Investor sells or redeems tokens when needed
Traditional Money Market Fund:
1. Investor purchases MMF shares
2. Shares held in brokerage account
3. To use as collateral, investor must sell shares for cash
4. Yield typically distributed or reinvested
5. Investor redeems shares for cash when needed



