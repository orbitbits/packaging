#!/usr/bin/env bash
set -euo pipefail

ruby tools/rb/generate_indexes.rb "${1:-public}"
