#!/bin/bash

# Leave empty if you want to randomize the name, symbol and image
token_name=""
token_symbol=""
token_image=""
token_program_id=""
rpc_url=""
recipient=""
github_username=""

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --token_name)
      token_name="$2"
      shift 2
      ;;
    --token_symbol)
      token_symbol="$2"
      shift 2
      ;;
    --token_image)
      token_image="$2"
      shift 2
      ;;
    --rpc_url)
      rpc_url="$2"
      shift 2
      ;;
    --recipient)
      recipient="$2"
      shift 2
      ;;
    --github_username)
      github_username="$2"
      shift 2
      ;;
    --token_amount)
      token_amount=$2
      shift 2
      ;;
    *)
      # Skip unknown option
      shift
      ;;
  esac
done

# Read configuration from config.json
CONFIG_FILE="./config.json"
if [ -f "$CONFIG_FILE" ]; then
    echo "Reading configuration from $CONFIG_FILE..."
    if command -v jq &> /dev/null; then
        config_recipient=$(jq -r '.recipient // empty' "$CONFIG_FILE")
        config_github_username=$(jq -r '.github_username // empty' "$CONFIG_FILE")
        config_token_amount=$(jq -r '.token_amount // empty' "$CONFIG_FILE")
        config_is_token_2022=$(jq -r '.is_token_2022 // empty' "$CONFIG_FILE")
        config_is_devnet=$(jq -r '.is_devnet // empty' "$CONFIG_FILE")
        
        # Only use config values if they exist
        if [ -z "$recipient" ]; then
            recipient=$(echo "$config_recipient" | tr -d '"')
        else
            echo "Error: No defined recipient."
            exit 1
        fi

        if [ -z "$github_username" ]; then
            github_username=$(echo "$config_github_username" | tr -d '"')
        else
            echo "Error: No defined github_username."
            exit 1
        fi
        
        if [ -z "$token_amount" ]; then
            # Use config token amount if available
            if [ -n "$config_token_amount" ]; then
                token_amount=$config_token_amount
            else
                echo "Warning: No found token_amount, so minting default amount."
                token_amount=1000000
            fi
        fi

        # Use config token type if available
        if [[ "$config_is_token_2022" = true ]]; then
            token_program_id="TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb"
        else
            token_program_id="TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"
        fi

        # Use config token type if available
        if [ -z "$rpc_url" ]; then
            if [[ "$config_is_devnet" = true ]]; then
                rpc_url="https://api.devnet.solana.com"
            else
                rpc_url="https://api.mainnet-beta.solana.com"
            fi
        fi
    else
        echo "Warning: jq not installed. Cannot parse config.json. Using default values."
    fi
else
    echo "Warning: $CONFIG_FILE not found."
    exit 1
fi

# Use default values if config didn't provide values
if [ -z "$recipient" ] || [ -z "$github_username" ]; then
    echo "No Value for reipient or github_username found in config.json."
    exit 1
fi

if [ -z "$token_name" ] || [ -z "$token_symbol" ]; then
    # Randomly select a name and symbol from the JSON file
    echo "Randomizing token name and symbol..."
    # Path to your JSON file
    JSON_FILE="./content/names.json"

    # Check if jq is installed (we'll use it to parse JSON)
    if ! command -v jq &> /dev/null; then
        echo "Error: jq is not installed. Please install it (e.g., 'sudo apt install jq' on Ubuntu)."
        exit 1
    fi

    # Check if the JSON file exists
    if [ ! -f "$JSON_FILE" ]; then
        echo "Error: $JSON_FILE not found."
        exit 1
    fi

    # Get the total number of items in the JSON array
    TOTAL_ITEMS=$(jq length "$JSON_FILE")

    # Generate a random index
    RANDOM_INDEX=$(( RANDOM % TOTAL_ITEMS ))

    # Extract the name and symbol at the random index
    if [ -z "$token_name" ]; then
        token_name=$(jq -r ".[$RANDOM_INDEX].name" "$JSON_FILE")
    fi

    if [ -z "$token_symbol" ]; then
        token_symbol=$(jq -r ".[$RANDOM_INDEX].symbol" "$JSON_FILE")
    fi
fi

if [ -z "$token_image" ]; then
    # Get a random image from images.json
    IMAGES_FILE="./content/images.json"
    if [ ! -f "$IMAGES_FILE" ]; then
        echo "Warning: $IMAGES_FILE not found. Using default empty image."
        token_image=""
    else
        # Get total number of images
        TOTAL_IMAGES=$(jq length "$IMAGES_FILE")
        if [ $TOTAL_IMAGES -eq 0 ]; then
            echo "Warning: No images found in $IMAGES_FILE. Using default empty image."
            token_image=""
        else
            # Select random image
            IMAGE_INDEX=$(( RANDOM % TOTAL_IMAGES ))
            token_image=$(jq -r ".[$IMAGE_INDEX]" "$IMAGES_FILE")
        fi
    fi
fi

# Output the selected token
echo "Token Name: $token_name"
echo "Token Symbol: $token_symbol"
echo "Token Image: $token_image"
echo "Token Program ID: $token_program_id"
echo "RPC URL: $rpc_url"
echo "Recipient: $recipient"
echo "GitHub Username: $github_username"
echo "Token Amount: $token_amount"

# Make the json file
filename_safe_name=$(echo "$token_name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
cat > tokens/$filename_safe_name.json << EOF
{
  "name": "$token_name",
  "symbol": "$token_symbol",
  "description": "The $token_name token.",
  "image": "$token_image",
  "attributes": [
    {
      "trait_type": "Speed",
      "value": "100"
    }
  ]
}
EOF

echo "Created token metadata JSON file"

if ! git add .; then
  echo "Error: Failed to add changes to Git"
  exit 1
fi

if ! git commit -m "Added token $token_name"; then
  echo "Error: Failed to commit changes"
  exit 1
fi

echo "Pushing changes to remote repository..."
if ! git push; then
  echo "Error: Failed to push to GitHub. The metadata won't be accessible. Aborting token creation."
  exit 1
fi

metadata="https://raw.githubusercontent.com/$github_username/spl-tokens-metadata/refs/heads/main/tokens/$filename_safe_name.json"

# File to store grind output
output_file="grind_output.txt"

# Remove any existing output file to start fresh
rm -f "$output_file"

# Run the grind command and wait for it to complete
echo "Starting solana-keygen grind..."
solana-keygen grind --starts-with m:1 > "$output_file" 2>&1

# Extract the filename from the last line of the output
filename=$(tail -n 1 "$output_file" | grep "Wrote keypair to" | awk '{print $4}')

echo "Grind completed. Output file: $output_file and filename: $filename"

# Check if the filename was extracted and the file exists
if [ -z "$filename" ] || [ ! -f "$filename" ]; then
    echo "Error: Failed to extract keypair filename or file not found"
    echo "Last few lines of output:"
    tail -n 5 "$output_file"
    rm "$output_file"
    exit 1
fi

echo "Keypair file generated: $filename"

# Extract the token_id by removing ".json" from the filename
token_id=$(echo "$filename" | sed 's/\.json$//')

# Check if token_id was successfully extracted
if [ -z "$token_id" ]; then
    echo "Error: Failed to extract token ID from filename"
    rm "$output_file"
    rm "$filename"
    exit 1
fi

# Clean up temporary file
rm "$output_file"

echo "Token ID extracted: $token_id"

echo "Token Program ID: $token_program_id"

# Create the token with metadata enabled
spl-token create-token --program-id $token_program_id --enable-metadata "$token_id.json" --decimals 50 --url $rpc_url

echo "Token created at address: $token_id"

# Initialize metadata
spl-token initialize-metadata "$token_id" "$token_name" "$token_symbol" "$metadata"

spl-token create-account "$token_id"

spl-token mint "$token_id" $token_amount

spl-token transfer "$token_id" $token_amount $recipient --fund-recipient

# Clean up the keypair file (optional)
rm "$filename"

# Add colorful emphasis to final output messages
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
RESET='\033[0m'

echo -e "\n${GREEN}${BOLD}=== TOKEN CREATION COMPLETED SUCCESSFULLY ===${RESET}"
echo -e "${YELLOW}${BOLD}Token Created:${RESET} $token_name ($token_id)"
echo -e "${BLUE}${BOLD}Minted:${RESET} $token_amount $token_symbol to $recipient"
echo -e "${YELLOW}${BOLD}Metadata URL:${RESET} $metadata\n"