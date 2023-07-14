#!/bin/bash
#
# This script contains various utility functions for other scripts can use
#
#------------------------------------------------------------------------------

RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info () {
  echo -e "${BLUE}$1${NC}"
}

warning () {
  echo -e "${YELLOW}$1${NC}"
}

error () {
  echo -e "${RED}$1${NC}"
}
