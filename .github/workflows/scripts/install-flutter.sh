#!/bin/bash

BRANCH=$1

cd "$HOME" || exit 1
git clone https://github.com/flutter/flutter.git --depth 1 -b "$BRANCH" _flutter
{
  echo "$HOME/_flutter/bin";
  echo "$HOME/.pub-cache/bin";
  echo "$HOME/_flutter/.pub-cache/bin";
  echo "$HOME/_flutter/bin/cache/dart-sdk/bin";
} >> "$GITHUB_PATH"
