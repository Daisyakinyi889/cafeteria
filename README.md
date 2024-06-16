# Cafeteria Transaction System on Sui Blockchain
## Introduction

This project implements a cafeteria transaction system using the Sui blockchain. It features user registration, menu and order management, and enhanced payment processing functionalities. The smart contract is written in Sui Move, a language designed for secure and efficient blockchain applications.
## Overview

The Cafeteria Transaction System includes the following functionalities:

- **User Registration:** Register new users and manage their account balances and loyalty points.
-  **Menu and Order Management:** Create menu items, place orders, and manage order details.
- **Payment Processing:** Process payments using account balance or loyalty points, apply discounts, and handle partial payments.

## Modules and Functions
### User Registration Module

This module manages user accounts, including registration, balance management, and loyalty points.

- **User Structure:**

``` move
    struct User has key, store {
    id: UID,
    name: String,
    balance: Balance<SUI>,
    loyalty_points: u64,
}
```
- **register_user(name: String, ctx: &mut TxContext): User:**

Registers a new user with the provided name and initializes their balance and loyalty points to zero.

```move

public fun register_user(
    name: String,
    ctx: &mut TxContext,
): User
```

- **get_user_details(user: &User): (String, &Balance<SUI>, u64):**

Returns the user's name, balance, and loyalty points.

```move

public fun get_user_details(user: &User): (String, &Balance<SUI>, u64)
```

- **add_balance(user: &mut User, amount: Coin<SUI>):**

Adds the specified amount to the user's balance.

```move

public fun add_balance(user: &mut User, amount: Coin<SUI>)
```

- **add_loyalty_points(user: &mut User, points: u64):**

Adds the specified loyalty points to the user's account.

```move

public fun add_loyalty_points(user: &mut User, points: u64)
```

## Menu and Order Management Module

This module handles the creation of menu items and the placement and management of orders.

- **MenuItem Structure:**
```move
struct MenuItem has key, store {
    id: UID,
    name: String,
    price: u64,
}
 ```

- **Order Structure:**

```move

struct Order has key, store {
    id: UID,
    user: ID,
    items: vector<MenuItem>,
    total_price: u64,
    is_paid: bool,
    discount: u64,
}
```

- **create_menu_item(name: String, price: u64, ctx: &mut TxContext): MenuItem:**

Creates a new menu item with the given name and price.

```move

public fun create_menu_item(
    name: String,
    price: u64,
    ctx: &mut TxContext,
): MenuItem
```

- **place_order(user: &mut User, items: vector<MenuItem>, discount: u64, total_price: u64, ctx: &mut TxContext): Order:**
Places an order for the specified user, including the selected items and applying any discount.

```move

public fun place_order(
    user: &mut User,
    items: vector<MenuItem>,
    discount: u64,
    total_price: u64,
    ctx: &mut TxContext,
): Order
```

- **get_order_details(order: &Order): (&ID, &vector<MenuItem>, u64, bool, u64):**
Retrieves details of the specified order, including the user ID, items, total price, payment status, and discount applied.

```move

public fun get_order_details(order: &Order): (&ID, &vector<MenuItem>, u64, bool, u64)
```

### Payment Processing Module

This module provides functionalities for processing payments, applying discounts, and handling partial payments.

- **process_payment_with_balance(user: &mut User, order: &mut Order, reciepient: address, ctx: &mut TxContext):**

Processes the payment for the specified order using the user's balance. Adds loyalty points based on the total price of the order.

```move

public fun process_payment_with_balance(
    user: &mut User,
    order: &mut Order,
    reciepient: address,
    ctx : &mut TxContext,
)
```
- **process_payment_with_loyalty_points(user: &mut User, order: &mut Order, reciepient: address, ctx: &mut TxContext):**

Processes the payment for the specified order using the user's loyalty points.

```move

public fun process_payment_with_loyalty_points(
    user: &mut User,
    order: &mut Order,
    reciepient: address,
    ctx : &mut TxContext,
)
```

- **apply_discount(order: &mut Order, discount: u64):**
Applies a discount to the specified order.

```move

public fun apply_discount(order: &mut Order, discount: u64)
```

- **process_partial_payment(user: &mut User, order: &mut Order, reciepient: address, ctx: &mut TxContext, amount: u64):**

Processes a partial payment for the specified order using the given amount from the user's balance. If the total price reaches zero, the order is marked as paid, and loyalty points are added based on the partial payment amount.

```move

public fun process_partial_payment(
    user: &mut User,
    order: &mut Order,
    reciepient: address,
    ctx : &mut TxContext,
    amount: u64,
)
```


### Installation and Deployment
Before we proceed, we should install a couple of things. Also, if you are using a Windows machine, it's recommended to use WSL2.

On Ubuntu/Debian/WSL2(Ubuntu):
```
sudo apt update
sudo apt install curl git-all cmake gcc libssl-dev pkg-config libclang-dev libpq-dev build-essential -y
```
On MacOs:
```
brew install curl cmake git libpq
```
If you don't have `brew` installed, run this:
```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Next, we need rust and cargo:
```
curl https://sh.rustup.rs -sSf | sh
```

### Install Sui
If you are using Github codespaces, it's recommended to use pre-built binaries rather than building them from source.

To download pre-built binaries, you should run `download-sui-binaries.sh` in the terminal. 
This scripts takes three parameters (in this particular order) - `version`, `environment` and `os`:
- sui version, for example `1.15.0`. You can lookup a more up-to-date version available here [SUI Github releases](https://github.com/MystenLabs/sui/releases).
- `environment` - that's the environment that you are targeting, in our case it's `devnet`. Other available options are: `testnet` and `mainnet`.
- `os` - name of the os. If you are using Github codespaces, put `ubuntu-x86_64`. Other available options are: `macos-arm64`, `macos-x86_64`, `ubuntu-x86_64`, `windows-x86_64` (not for WSL).

To donwload SUI binaries for codespace, run this command:
```
./download-sui-binaries.sh "v1.18.0" "devnet" "ubuntu-x86_64"
```
and restart your terminal window.

If you prefer to build the binaries from source, run this command in your terminal:
```
cargo install --locked --git https://github.com/MystenLabs/sui.git --branch devnet sui
```

### Install dev tools (not required, might take a while when installin in codespaces)
```
cargo install --git https://github.com/move-language/move move-analyzer --branch sui-move --features "address32"

```

### Run a local network
To run a local network with a pre-built binary (recommended way), run this command:
```
RUST_LOG="off,sui_node=info" sui-test-validator
```

Optionally, you can run it from sources.
```
git clone --branch devnet https://github.com/MystenLabs/sui.git

cd sui

RUST_LOG="off,sui_node=info" cargo run --bin sui-test-validator
```

### Install SUI Wallet (optionally)
```
https://chrome.google.com/webstore/detail/sui-wallet/opcgpfmipidbgpenhmajoajpbobppdil?hl=en-GB
```

### Configure connectivity to a local node
Once the local node is running (using `sui-test-validator`), you should the url of a local node - `http://127.0.0.1:9000` (or similar).
Also, another url in the output is the url of a local faucet - `http://127.0.0.1:9123`.

Next, we need to configure a local node. To initiate the configuration process, run this command in the terminal:
```
sui client active-address
```
The prompt should tell you that there is no configuration found:
```
Config file ["/home/codespace/.sui/sui_config/client.yaml"] doesn't exist, do you want to connect to a Sui Full node server [y/N]?
```
Type `y` and in the following prompts provide a full node url `http://127.0.0.1:9000` and a name for the config, for example, `localnet`.

On the last prompt you will be asked which key scheme to use, just pick the first one (`0` for `ed25519`).

After this, you should see the ouput with the wallet address and a mnemonic phrase to recover this wallet. You can save so later you can import this wallet into SUI Wallet.

Additionally, you can create more addresses and to do so, follow the next section - `Create addresses`.


### Create addresses
For this tutorial we need two separate addresses. To create an address run this command in the terminal:
```
sui client new-address ed25519
```
where:
- `ed25519` is the key scheme (other available options are: `ed25519`, `secp256k1`, `secp256r1`)

And the output should be similar to this:
```
╭─────────────────────────────────────────────────────────────────────────────────────────────────╮
│ Created new keypair and saved it to keystore.                                                   │
├────────────────┬────────────────────────────────────────────────────────────────────────────────┤
│ address        │ 0x05db1e318f1e4bc19eb3f2fa407b3ebe1e7c3cd8147665aacf2595201f731519             │
│ keyScheme      │ ed25519                                                                        │
│ recoveryPhrase │ lava perfect chef million beef mean drama guide achieve garden umbrella second │
╰────────────────┴────────────────────────────────────────────────────────────────────────────────╯
```
Use `recoveryPhrase` words to import the address to the wallet app.


### Get localnet SUI tokens
```
curl --location --request POST 'http://127.0.0.1:9123/gas' --header 'Content-Type: application/json' \
--data-raw '{
    "FixedAmountRequest": {
        "recipient": "<ADDRESS>"
    }
}'
```
`<ADDRESS>` - replace this by the output of this command that returns the active address:
```
sui client active-address
```

You can switch to another address by running this command:
```
sui client switch --address <ADDRESS>
```
abd run the HTTP request to mint some SUI tokens to this account as well.

Also, you can top up the balance via the wallet app. To do that, you need to import an account to the wallet.

## Build and publish a smart contract

### Build package
To build tha package, you should run this command:
```
sui move build
```

If the package is built successfully, the next step is to publish the package:
### Publish package
```
sui client publish --gas-budget 100000000 --json
```
Here we do not specify the path to the package dir so it will use the current dir - `.`

After the contract is published we need to extract some object ids from the output. Here is the list of env variable that we source in the current shell and their values:
- `PACKAGE_ID` - the id of the published package. The json path to it is `.objectChanges[].packageId`
- `ORIGINAL_UPGRADE_CAP_ID` - the upgrade cap id that we might need if we find ourselves in the situation when we need to upgrade the contract. Path: `.objectChanges[].objectId` where `.objectChanges[].objectType` is  `0x2::package::UpgradeCap`
- `SUI_FEE_COIN_ID` the id of the SUI coin that we are going to use to pay the fee for the pool creation. Take any from the output of this command: `sui client gas --json`
- `ACCOUNT_ID1` - currently active address, assign the output of this command: `sui client active-address`. Repeat the same for the secondary account and assign the output to `ACCOUNT_ID1`
- `CLOCK_OBJECT_ID` - the id of the `Clock` object, default to `0x6`
- `BASE_COIN_TYPE` - the type of the SUI coin, default to `0x2::sui::SUI`
- `QUOTE_COIN_TYPE` - the type of the quote coin that we deployed for the sake of this tutorial. The coin is `WBTC` in the `wbtc` module in the `$PACKAGE_ID` package. So the value will look like this: `<PACKAGE_ID>::wbtc::WBTC`
- `WBTC_TREASURY_CAP_ID` it's the treasury cap id that is needed for token mint operations. In the publish output you should look for the object with `objectType` `0x2::coin::TreasuryCap<$PACKAGE_ID::wbtc::WBTC>` (replace `$PACKAGE_ID` with the actual package id) and this object also has `objectId` - that's the value that we are looking for.

