#!/bin/bash

# Import Docker images from tar files
# Each tar file should be named in the format: registry_repository_tag.tar
# After import, the image will have the original name and tag

set -e  # Exit on any error

echo "Starting Docker image import process..."

# Find all tar files in current directory
tar_files=$(ls *.tar 2>/dev/null || echo "")

if [ -z "$tar_files" ]; then
  echo "No tar files found in current directory."
  exit 0
fi

echo "Found tar files: $tar_files"

# Process each tar file
for tar_file in $tar_files; do
  echo "Processing $tar_file..."
  
  # Remove .tar extension
  image_name_without_ext="${tar_file%.tar}"
  
  # Split by underscore to get parts
  IFS='_' read -ra PARTS <<< "$image_name_without_ext"
  
  # Get registry (first part)
  registry="${PARTS[0]}"
  
  # Get tag (last part)
  tag="${PARTS[-1]}"
  
  # Get repository parts (everything in between)
  # If there are only 2 parts, then there's no middle repository path
  if [ "${#PARTS[@]}" -eq 2 ]; then
    repository=""
  else
    # Join middle parts with /
    unset PARTS[0]  # Remove first element
    unset PARTS[${#PARTS[@]}-1]  # Remove last element
    repository=$(IFS=/; echo "${PARTS[*]}")
  fi
  
  # Construct the full image reference
  if [ -n "$repository" ]; then
    image_reference="${registry}/${repository}:${tag}"
  else
    image_reference="${registry}:${tag}"
  fi
  
  echo "Loading image: $image_reference"
  
  # Load the image from tar file
  if docker load -i "$tar_file"; then
    echo "Successfully loaded $tar_file"
    
    # Verify the image was loaded correctly
    if docker image inspect "$image_reference" >/dev/null 2>&1; then
      echo "Verified: Image $image_reference is available"
    else
      echo "Warning: Could not verify image $image_reference after loading"
    fi
  else
    echo "Error: Failed to load $tar_file"
    exit 1
  fi
  
  echo "Finished processing $tar_file"
  echo "----------------------------------------"
done

echo "All images processed successfully!"