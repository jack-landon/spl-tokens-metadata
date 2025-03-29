#!/bin/bash

# Get the token ID by grinding for a keypair starting with "mnt" and extract the public key
token_id=$(solana-keygen grind --starts-with mnt:1 | grep "Public key" | awk '{print $3}')

# Check if token_id was successfully obtained
if [ -z "$token_id" ]; then
    echo "Error: Failed to generate token ID"
    exit 1
fi

# Create the token with metadata enabled
spl-token create-token --program-id TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb --enable-metadata "$token_id.json"

# Initialize metadata (replace these with your desired values)
input_name="Mountain Token"
input_ticker="MNT"
input_metadata="https://raw.githubusercontent.com/jack-landon/spl-tokens-metadata/refs/heads/main/lerd.json"
spl-token initialize-metadata "$token_id" "$input_name" "$input_ticker" "$input_metadata"

# Create an account for the token
spl-token create-account "$token_id"

# Mint 1,000,000 tokens
spl-token mint "$token_id" 1000000

# Transfer 100,000 tokens to the specified address
spl-token transfer "$token_id" 100000 DLVwzCBoJB6NSX3bkhPrLmCh213iiRfVNin2Ma6g3qFh --fund-recipient

echo "Token creation process completed. Token ID: $token_id"