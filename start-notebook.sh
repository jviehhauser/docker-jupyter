#!/bin/bash

echo "Starting up Jupyter notebook"

set -e
jupyter notebook $*
