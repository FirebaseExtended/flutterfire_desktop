#!/bin/bash

BRANCH=$1

cd "$GITHUB_WORKSPACE" || exit 1
git clone https://github.com/flutter/flutter.git --depth 1 -b "$BRANCH" _flutter
{
  echo "$HOME/.pub-cache/bin";
  echo "$GITHUB_WORKSPACE/_flutter/bin";
  echo "$GITHUB_WORKSPACE/_flutter/.pub-cache/bin";
  echo "$GITHUB_WORKSPACE/_flutter/bin/cache/dart-sdk/bin";
} >> "$GITHUB_PATH"
