# Solana Token Generator

First, complete the [setup](#setup), and then **generate a new token by simply running this in your terminal** ✨:

```bash
./create_token.sh
```

## Table of Contents

- [Before You Start](#before-you-start)
- [Setup](#setup)
- [Additional Flags](#additional-flags)

## Before You Start

If you are on Windows, you must have wsl to run this program.
<br />
[Click here for wsl installation instructions](https://learn.microsoft.com/en-us/windows/wsl/install).

### 1. Check you have all dependencies installed

Run these to check you have both dependencies installed.

```bash
solana --version
jq --version
```

<details>
<summary>
If either of these aren't installed, click here to expand installation instructions.
</summary>

#### 1. Solana CLI

Install the Solana CLI by running:

```bash
curl --proto '=https' --tlsv1.2 -sSfL https://solana-install.solana.workers.dev | bash
```

[Visit the official Solana installation guide if you have any issues](https://solana.com/docs/intro/installation).

#### 2. jq

Install the lightweight `jq` package by running:

```bash
# macOS
brew install jq

# Linux (Debian/Ubuntu) and WSL
sudo apt install jq
```

</details>

### 2. Confirm you are logged into Github in your CLI

To check if you're already logged in to GitHub:

```bash
gh auth status
```

<details>
<summary>
If you don't have `gh` installed, click here for installation instructions
</summary>

Install `gh` by running the following:

```bash
# macOS
brew install gh
```

For WSL and Linux users, [click here to install the Github CLI](https://github.com/cli/cli/blob/trunk/docs/install_linux.md)

</details>

<br />

If you're not logged in, authenticate with:

```bash
gh auth login
```

Follow the prompts to complete authentication. This will allow the script to push metadata to your GitHub repository.

### 3. Ensure your Solana CLI account is funded

Find your CLI account _address_ to fund by running:

```bash
solana address
```

Check your balance by running:

```bash
solana balance
```

If you are deploying to devnet, you can get an airdrop by running:

```bash
solana airdrop 2
```

If this doesn't work, visit the [Solana Devnet Faucet](https://faucet.solana.com/)

### 4. Delete the `tokens` folder

If there is a `tokens` folder, feel free to delete it, or the contents inside it.<br />
This will eventually be populated with the metadata of tokens you create.<br />
If it is full, it means it is full of tokens that have been created by someone else.

## Setup

### 1. Clone this repo

```bash
git clone https://github.com/jack-landon/spl-tokens-metadata.git
```

### 2. Enter the repo directory

```bash
cd spl-tokens-metadata
```

### 3. Create a PUBLIC repo on Github to house the token metadata

[Click here](https://github.com/new) to create a new _public_ repo on Github called `spl-tokens-metadata`, and follow the instructions.<br />
This program will push each new token's metadata to this repo.

> This must be public, otherwise the token metadata will not be able to be fetched

### 4. Add your Solana Address and Github Username to config.json

```js
{
  "recipient": "your address goes here",
  "github_username": "your github username goes here",
  // Other propterties..
}
```

Feel free to update the other properties to taste.

### 5. Make the `create_token.sh` program executable

```bash
chmod +x create_token.sh
```

Now that everything is setup, you only need to run one command.

### 6. Mint a token ✨

```bash
./create_token.sh
```

## Additional Flags

If you don't want to use randomized values, or would like to overwrite the defaults set out in `config.json`, you can add any of these flags:

- --token_name
- --token_symbol
- --token_image
- --rpc_url
- --recipient
- --github_username
- --token_amount
- --decimals

Use any of these flags, followed by their corresponding value to overwrite the defaults.

For example:

```bash
./create_token.sh --token_name Beautiful --token_symbol BEAUT --token_amount 5000000000
```

Note: If you want to use multi-word values, surround them in double quotes ("").<br />
For example:

```bash
# ❌ Without Quotes... Outputs 'Three'
./create_token.sh --token_name Three Word Token

# ✅ With Quotes: Outputs 'Three Word Token'
./create_token.sh --token_name "Three Word Token"
```
