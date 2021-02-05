#!/bin/sh

match_case=".template.yaml"

walk_dir() {
  shopt -s nullglob dotglob

  for pathname in "$1"/*; do
    if [ -d "$pathname" ]; then
      walk_dir "$pathname"
    else
      if [[ "${pathname}" == *"${match_case}"* ]]; then
        echo "**************** Performing Checks for ${pathname} ****************"

        output=$(cfn-lint ${pathname})
        echo "Validation complete for File -> app with Output as "
        echo "${output}"

        output=$(cfn_nag ${pathname})
        echo "Security Validation complete for File -> app with Output as "
        echo "${output}"

        echo "**************** Checks Complete for ${pathname} ****************"
        echo
        echo
      fi
    fi
  done
}

cd ..\/

walk_dir "apps/"
