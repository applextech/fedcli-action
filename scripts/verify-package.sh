#!/bin/sh
set -eu

image_ref=$(sed -n 's/^FROM \(public\.ecr\.aws\/c1t8q5x5\/fedcli@sha256:[a-f0-9][a-f0-9]*\)$/\1/p' Dockerfile)

if [ -z "$image_ref" ]; then
  printf '%s\n' 'Dockerfile must pin the official FedCLI ECR Public image by SHA-256 digest.' >&2
  exit 1
fi

digest=${image_ref##*@}
if [ "${#digest}" -ne 71 ]; then
  printf '%s\n' 'FedCLI image digest must be a full sha256 value.' >&2
  exit 1
fi

grep -Fq "$image_ref" README.md
grep -Fq 'using: "docker"' action.yml
grep -Fq 'image: "Dockerfile"' action.yml
grep -Fq 'WHENEVER SQLERROR EXIT FAILURE' entrypoint.sh

printf '%s\n' "Validated action package against $image_ref"
