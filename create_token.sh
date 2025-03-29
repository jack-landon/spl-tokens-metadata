#!/bin/bash

# Leave empty if you want to randomize the name, symbol and image
token_name=""
token_symbol=""
token_image=""
token_program_id=""

recipient=""
github_username=""

is_token_2022=true
token_amount=1000000


# Read configuration from config.json
CONFIG_FILE="./config.json"
if [ -f "$CONFIG_FILE" ]; then
    echo "Reading configuration from $CONFIG_FILE..."
    if command -v jq &> /dev/null; then
        recipient=$(jq -r '.recipient // empty' "$CONFIG_FILE")
        github_username=$(jq -r '.github_username // empty' "$CONFIG_FILE")
        config_token_amount=$(jq -r '.default_token_amount // empty' "$CONFIG_FILE")
        config_is_token_2022=$(jq -r '.default_is_token_2022 // empty' "$CONFIG_FILE")
        
        # Only use config values if they exist
        [ -n "$recipient" ] || echo "Warning: No recipient found in config, using default"
        [ -n "$github_username" ] || echo "Warning: No GitHub username found in config, using default"
        
        # Use config token amount if available
        if [ -n "$config_token_amount" ]; then
            token_amount=$config_token_amount
        fi

        # Use config token type if available
        if [[ "$config_is_token_2022" = true ]]; then
            is_token_2022=true
            token_program_id="TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb"
        else
            is_token_2022=false
            token_program_id="TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA"
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

echo "Recipient: $recipient"
echo "GitHub Username: $github_username"
echo "Token Amount: $token_amount"
echo "Is Token 2022: $is_token_2022"

exit 1

if [ "$token_name" == "" ] || [ "$token_symbol" == "" ]; then
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
    token_name=$(jq -r ".[$RANDOM_INDEX].name" "$JSON_FILE")
    token_symbol=$(jq -r ".[$RANDOM_INDEX].symbol" "$JSON_FILE")
fi

if [ "$token_image" == "" ]; then
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
            echo "Selected Image: $token_image"
        fi
    fi
fi

# Output the selected token
echo "Selected Token:"
echo "Name: $token_name"
echo "Symbol: $token_symbol"
echo "Image: $token_image"

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

echo "Adding changes to Git..."
git add .

echo "Committing changes..."
git commit -m "Added token $token_name"

echo "Pushing changes to remote repository..."
git push

metadata="https://raw.githubusercontent.com/$github_username/spl-tokens-metadata/refs/heads/main/tokens/$filename_safe_name.json"

echo "Metadata URL: $metadata"

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
spl-token create-token --program-id $token_program_id --enable-metadata "$token_id.json"

echo "Token created at address: $token_id"

# Initialize metadata
spl-token initialize-metadata "$token_id" "$token_name" "$token_symbol" "$metadata"

# Create an account for the token
echo "Creating token account..."
spl-token create-account "$token_id"

echo "Minting $token_amount tokens..."
spl-token mint "$token_id" $token_amount

echo "Transferring $token_amount tokens to $recipient..."
spl-token transfer "$token_id" $token_amount $recipient --fund-recipient

# Clean up the keypair file (optional)
rm "$filename"

echo "Token creation process completed. Token ID: $token_id"