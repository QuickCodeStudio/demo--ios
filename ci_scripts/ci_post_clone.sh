#!/usr/bin/env bash
# Xcode Cloud: allow SPM build plugins (swift-openapi-generator) without interactive trust.
set -euo pipefail
defaults write com.apple.dt.Xcode IDESkipPackagePluginFingerprintValidatation -bool YES
echo "ci_post_clone: OpenAPIGenerator plugin fingerprint validation skipped"
