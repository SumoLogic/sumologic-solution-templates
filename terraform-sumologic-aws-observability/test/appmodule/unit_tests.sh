#!/bin/bash

echo "Check requirements"

function check_command()
{
    local cmd="$1"
    if ! command -v ${cmd} > /dev/null 2>&1; then
        echo "This requires ${cmd} command, please install it first."
        if [[ "$1" == "terraform" ]]; then
            echo "You can install using this command on Mac: brew install terraform, Windows: choco install terraform and by downloading binary on other systems."
        elif [[ "$1" == "tflint" ]]; then
            echo "You can install using this command on Mac: brew install tflint, Windows: choco install tflint and by downloading binary on other systems."
        fi
        exit 1
    fi
}

for cmd in terraform tflint; do
    echo -e "\t- Check command \"$cmd\" exists."
    check_command $cmd
done

cd ..

echo "\t- Tflint"
tflint

echo "\t- Check terraform init"
terraform init

echo "\t- Check terraform validate"
terraform validate

echo "\t- Check terraform fmt"
terraform fmt -write=false -diff=true -check=true

echo "Done. Please review any errors above."
