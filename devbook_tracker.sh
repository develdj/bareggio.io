#!/bin/bash

HOURLY_RATE=50  # Euro per hour

# Start tracking development time
start_time=$(date +%s)

# Start VSCode
code . &

# Get the PID of VSCode
VS_CODE_PID=$!

# Wait for VSCode to close
wait $VS_CODE_PID

# End tracking development time
end_time=$(date +%s)
elapsed_time=$((end_time - start_time))
formatted_time=$(printf '%02d:%02d:%02d' $((elapsed_time/3600)) $((elapsed_time%3600/60)) $((elapsed_time%60)))

# Read and increment total development time
total_time_file=".total_time"
if [ ! -f $total_time_file ]; then
  echo "0" > $total_time_file
fi
total_time=$(cat $total_time_file)
total_time=$((total_time + elapsed_time))
echo $total_time > $total_time_file
formatted_total_time=$(printf '%02d:%02d:%02d' $((total_time/3600)) $((total_time%3600/60)) $((total_time%60)))

# Calculate costs
partial_cost=$(echo "scale=10; $elapsed_time * $HOURLY_RATE / 3600" | bc)
total_cost=$(echo "scale=10; $total_time * $HOURLY_RATE / 3600" | bc)

# Log the time and cost spent
log_file=".time_log"
echo "Time spent on $(date '+%Y-%m-%d %H:%M:%S'): $formatted_time - Cost: €$partial_cost" >> $log_file
echo "Total development time: $formatted_total_time - Total cost: €$total_cost" >> $log_file

# Get the current date and time
datetime=$(date '+%Y-%m-%d %H:%M:%S')

# Count the number of commits in the repository
commit_count=$(git rev-list --count HEAD)

# Get a summary of the changes made
changes=$(git status --short | awk '{print $2}' | paste -sd "," -)

# Incremental version number
version_file=".version"
if [ ! -f $version_file ]; then
  echo "0.0.0" > $version_file
fi

# Read and increment version number
current_version=$(cat $version_file)
IFS='.' read -r -a version_parts <<< "$current_version"
((version_parts[2]++))
new_version="${version_parts[0]}.${version_parts[1]}.${version_parts[2]}"
echo $new_version > $version_file

# Create a commit message
commit_message="Auto commit $commit_count - Version $new_version - $datetime - Project: $PROJECT_DIR - Changes: $changes"

# Add all changes
git add . || {
    echo "Failed to stage changes."
    exit 1
}

# Commit with the generated message
git commit -m "$commit_message" || {
    echo "Failed to commit changes."
    exit 1
}

# Push the changes
git push || {
    echo "Failed to push changes."
    exit 1
}

echo "Commit message: $commit_message"
echo "Time spent on this commit: $formatted_time"
echo "Total development time: $formatted_total_time"
echo "Total cost: €$total_cost"
