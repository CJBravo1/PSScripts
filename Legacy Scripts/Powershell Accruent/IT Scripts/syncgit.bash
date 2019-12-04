#!/bin/bash

git pull --all

echo "Enter your Commit Message"
echo "If no Changes have been made by you, Press ENTER"
read "cMessage"

git add *
git commit -a -m "$cMessage"

git push origin master
