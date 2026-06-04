#!/bin/bash

# ─────────────────────────────────────────────
# CONFIGURATION
# ─────────────────────────────────────────────
VERSION="v3.0.0"
BUCKET_NAME="sumologic-appdev-aws-sam-apps"
S3_BASE_PATH="s3://${BUCKET_NAME}/aws-observability-versions/${VERSION}"
AWS_PROFILE="sumocontent"

# Common S3 options for nested dirs
COMMON_ARGS=(
    --recursive
    --include "*.template.yaml"
    --exclude '.*'
    --exclude '*/.*'
    --exclude '*.zip'
    --exclude '*.sh'
    --exclude '*.DS_Store'
    --exclude '*/.DS_Store'
    --exclude '*/test/*'
    --acl public-read
    --profile "${AWS_PROFILE}"
)

# Format: "path:depth"
# nested = recursive all yaml files
# parent = top level yaml files only
UPLOAD_DIRS=(
    "../modules:nested"
    "../utilities:nested"
    "../extensions:nested"
    "../templates:parent"
)

# ─────────────────────────────────────────────
# FUNCTIONS
# ─────────────────────────────────────────────

count_templates_in_dir() {
    local dir=$1
    local depth=$2

    if [[ "${depth}" == "parent" ]]; then
        # ../templates - top level only, all yaml/json files
        find "${dir}" \
            -maxdepth 1 \
            -type f \
            \( -name "*.yaml" -o -name "*.template.yaml" -o -name "*.json" \) \
            ! -name ".*" \
            2>/dev/null | wc -l | tr -d ' '
    else
        # ../modules, ../utilities, ../extensions - all nested yaml/json files
        find "${dir}" \
            -type f \
            \( -name "*.yaml" -o -name "*.template.yaml" -o -name "*.json" \) \
            ! -name ".*" \
            ! -path "*/.*" \
            ! -path "*/test/*" \
            2>/dev/null | wc -l | tr -d ' '
    fi
}

upload_directory() {
    local src_dir=$1
    local depth=$2
    local dest_path="${S3_BASE_PATH}/"

    echo "INFO - Uploading [${depth}]: ${src_dir} -> ${dest_path}"

    if [[ "${depth}" == "parent" ]]; then
        aws s3 cp "${src_dir}/" "${dest_path}" \
            --recursive \
            --include "*.*.yaml" \
            --exclude '*/*' \
            --acl public-read \
            --profile "${AWS_PROFILE}"
    else
        aws s3 cp "${src_dir}/" "${dest_path}" "${COMMON_ARGS[@]}"
    fi

    if [[ $? -eq 0 ]]; then
        echo "INFO - [PASS] Uploaded: ${src_dir}"
        return 0
    else
        echo "ERROR - [FAIL] Failed: ${src_dir}"
        return 1
    fi
}

# ─────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────
echo "INFO - Starting S3 upload script"
echo "INFO - Version     : ${VERSION}"
echo "INFO - Bucket      : ${BUCKET_NAME}"
echo "INFO - Profile     : ${AWS_PROFILE}"
echo "INFO - Destination : ${S3_BASE_PATH}"
echo "-----------------------------------------"

if [[ "${AWS_PROFILE}" == 'sumocontent' ]]; then

    failed_dirs=0
    success_dirs=0
    total_templates=0
    failed_templates=0
    success_templates=0

    # ─────────────────────────────────────────
    # 1. Pre-count templates in all directories
    # ─────────────────────────────────────────
    echo "INFO - Pre-counting templates..."
    echo "-----------------------------------------"

    for entry in "${UPLOAD_DIRS[@]}"; do
        dir="${entry%%:*}"    # Extract path  (before ":")
        depth="${entry##*:}"  # Extract depth (after  ":")

        if [[ -d "${dir}" ]]; then
            count=$(count_templates_in_dir "${dir}" "${depth}")
            total_templates=$((total_templates + count))
            printf "INFO - [%-15s] [%-6s] Templates found: %s\n" "$(basename ${dir})" "${depth}" "${count}"
        else
            echo "WARN - Directory not found: ${dir}"
        fi
    done

    echo "-----------------------------------------"
    echo "INFO - Total templates to upload: ${total_templates}"
    echo "-----------------------------------------"

    # ─────────────────────────────────────────
    # 2. Upload all directories
    # ─────────────────────────────────────────
    echo "INFO - Uploading directories..."
    echo "-----------------------------------------"

    for entry in "${UPLOAD_DIRS[@]}"; do
        dir="${entry%%:*}"
        depth="${entry##*:}"

        if [[ -d "${dir}" ]]; then
            dir_template_count=$(count_templates_in_dir "${dir}" "${depth}")

            upload_directory "${dir}" "${depth}"

            if [[ $? -eq 0 ]]; then
                ((success_dirs++))
                success_templates=$((success_templates + dir_template_count))
            else
                ((failed_dirs++))
                failed_templates=$((failed_templates + dir_template_count))
            fi
        else
            echo "WARN - Directory not found, skipping: ${dir}"
        fi
    done

    # ─────────────────────────────────────────
    # 3. Summary
    # ─────────────────────────────────────────
    echo "========================================="
    echo "UPLOAD SUMMARY"
    echo "========================================="
    printf "%-30s %s\n" "  Total Directories  :" "${#UPLOAD_DIRS[@]}"
    printf "%-30s %s\n" "  Successful Dirs    :" "${success_dirs}"
    printf "%-30s %s\n" "  Failed Dirs        :" "${failed_dirs}"
    echo "-----------------------------------------"
    printf "%-30s %s\n" "  Total Templates    :" "${total_templates}"
    printf "%-30s %s\n" "  Successful         :" "${success_templates}"
    printf "%-30s %s\n" "  Failed             :" "${failed_templates}"
    echo "-----------------------------------------"
    echo "  Directory Breakdown:"
    for entry in "${UPLOAD_DIRS[@]}"; do
        dir="${entry%%:*}"
        depth="${entry##*:}"
        if [[ -d "${dir}" ]]; then
            count=$(count_templates_in_dir "${dir}" "${depth}")
            printf "    %-15s [%-6s] : %s templates\n" "$(basename ${dir})" "${depth}" "${count}"
        fi
    done
    echo "========================================="

    if [[ ${failed_dirs} -eq 0 ]]; then
        echo "INFO - [PASS] All uploads completed successfully"
        echo "INFO - Bucket  : ${BUCKET_NAME}"
        echo "INFO - Version : ${VERSION}"
        echo "INFO - Path    : ${S3_BASE_PATH}"
    else
        echo "ERROR - [FAIL] ${failed_dirs} dir(s) failed, ${failed_templates} template(s) not uploaded"
        exit 1
    fi

else
    echo "WARN - Skipping - AWS_PROFILE is '${AWS_PROFILE}', expected 'sumocontent'"
    exit 1
fi

echo "-----------------------------------------"
echo "INFO - End S3 upload Script"