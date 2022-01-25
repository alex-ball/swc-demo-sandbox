#!/usr/bin/env bash

cd ~/Downloads
wget "https://librarycarpentry.org/lc-shell/data/shell-lesson.zip"
mkdir ~/Desktop/shell-lesson
unzip shell-lesson.zip -d ~/Desktop/shell-lesson
rm -r ~/Desktop/shell-lesson/__MACOSX
