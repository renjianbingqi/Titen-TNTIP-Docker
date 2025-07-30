#!/bin/bash

main() {
    git config core.filemode false
    git pull
    chmod +x ./_tntip.sh
    ./_tntip.sh "$@"
}

main "$@"