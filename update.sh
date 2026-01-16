#!/bin/bash
cd "$(dirname "$0")"
dpkg-scanpackages -m debs /dev/null > Packages
bzip2 -fks Packages
echo "Done."
