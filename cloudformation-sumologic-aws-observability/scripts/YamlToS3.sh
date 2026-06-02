#!/bin/bash

# ─────────────────────────────────────────────
# CONFIGURATION
# ─────────────────────────────────────────────
VERSION="v3.0.0"
BUCKET_NAME="sumologic-appdev-aws-sam-apps"
S3_BASE_PATH="s3://${BUCKET_NAME}/aws-observability-versions/${VERSION}"
AWS_PROFILE="sumocontent"

# Common S3 options
COMMON_ARGS=(
    --recursive
    --include "*.template.yaml"
    --exclude '.*'
    --exclude '*/.*'
    --exclude '*.zip'
    --exclude '*.sh'
    --exclude '*/test/*'
    --acl public-read
    --profile "${AWS_PROFILE}"
)

# ─────────────────────────────────────────────
# FUNCTIONS
# ─────────────────────────────────────────────
upload_directory() {
    local src_dir=$1
    local dest_path="${S3_BASE_PATH}/"

    echo "Uploading ${src_dir}/ → ${dest_path}"

    aws s3 cp "${src_dir}/" "${dest_path}" "${COMMON_ARGS[@]}"

    if [[ $? -eq 0 ]]; then
        echo "Successfully uploaded: ${src_dir}"
    else
        echo "Failed to upload: ${src_dir}"
        return 1
    fi
}

upload_file() {
    local src_file=$1
    local dest_path="${S3_BASE_PATH}/"

    echo "Uploading ${src_file} → ${dest_path}"

    aws s3 cp "${src_file}" "${dest_path}" \
        --acl public-read \
        --profile "${AWS_PROFILE}"

    if [[ $? -eq 0 ]]; then
        echo "Successfully uploaded: ${src_file}"
    else
        echo "Failed to upload: ${src_file}"
        return 1
    fi
}

# ─────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────
echo "Starting S3 upload script..."
echo "   Version    : ${VERSION}"
echo "   Bucket     : ${BUCKET_NAME}"
echo "   Profile    : ${AWS_PROFILE}"
echo "   Destination: ${S3_BASE_PATH}"
echo "─────────────────────────────────────────"

if [[ "${AWS_PROFILE}" == 'sumocontent' ]]; then

    # Directories to upload
    UPLOAD_DIRS=(
        "modules"
        "utilities"
        "extensions"
    )

    # Track failures
    failed=0

    # Upload directories
    for dir in "${UPLOAD_DIRS[@]}"; do
        if [[ -d "../${dir}" ]]; then
            upload_directory "../${dir}" || ((failed++))
        else
            echo "Directory not found, skipping: ${dir}"
        fi
    done

    # Upload all matching master templates
    TEMPLATE_DIR="../templates"
    TEMPLATE_PATTERN="sumologic_observability*"
    template_count=0
    template_failed=0

    echo "Searching for templates: ${TEMPLATE_DIR}/${TEMPLATE_PATTERN}"

    while IFS= read -r -d '' template; do
        template_count=$((template_count + 1))
        echo "Uploading template: $(basename ${template})"
        upload_file "${template}" || ((template_failed++))
    done < <(find "${TEMPLATE_DIR}" -maxdepth 1 -name "${TEMPLATE_PATTERN}" -type f -print0 2>/dev/null)

    if [[ ${template_count} -eq 0 ]]; then
        echo "No templates found matching: ${TEMPLATE_DIR}/${TEMPLATE_PATTERN}"
        ((failed++))
    else
        echo "Processed ${template_count} template(s), Failed: ${template_failed}"
        failed=$((failed + template_failed))
    fi

    # Summary
    echo "─────────────────────────────────────────"
    if [[ ${failed} -eq 0 ]]; then
        echo "Upload complete for Master and Nested Templates"
        echo "   Bucket  : ${BUCKET_NAME}"
        echo "   Version : ${VERSION}"
        echo "   Path    : ${S3_BASE_PATH}"
    else
        echo "Upload completed with ${failed} failure(s)"
        exit 1
    fi

else
    echo "Skipping upload - AWS_PROFILE is '${AWS_PROFILE}'"
fi

echo "─────────────────────────────────────────"
echo "End S3 upload Script"