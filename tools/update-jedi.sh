#!/bin/bash

cd "$(git rev-parse --show-toplevel)"
cd external/jedi
git pull
cd ../../

cp -r external/jedi lib/external/jedi
rm lib/external/jedi/.git
rm lib/external/jedi/.gitignore

git add lib/external/jedi
git commit -m 'Automatic Commit: Updating bundled Jedi'
