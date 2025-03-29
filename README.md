# SPL Token Generator

## Instructions

1. Clone this repo:

```bash
git clone https://github.com/jack-landon/spl-tokens-metadata.git
```

2. Enter the repo directory:

```bash
cd spl-tokens-metadata
```

3. Install `jq`:

```bash
brew install jq
```

4. [Click here](https://github.com/new) to create a new repo on Github called `spl-tokens-metadata`, and follow the instructions.

5. Add your Solana Address and Github Username to config.json:

```json
{
  "recipient": "your address goes here",
  "github_username": "your github username goes here",
  ...
}
```

6. Make the program executable:

```bash
chmod +x create_token.sh
```

7. Mint a token:

```bash
./create_token.sh
```
