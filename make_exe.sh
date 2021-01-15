#!/bin/bash

LOVE_EXE_LOC="/home/quinlan/Downloads/love-11.3-win64"
LOVE_EXE_NAME="love.exe"
NAME="voidcrash"
EXE_NAME="$NAME.exe"

zip -9 -r $NAME assets src main.lua debugger.lua
mv $NAME.zip $NAME.love

cat $LOVE_EXE_LOC/$LOVE_EXE_NAME $NAME.love > $EXE_NAME
mkdir -p release
mv $EXE_NAME ./release/$EXE_NAME

cp $LOVE_EXE_LOC/*.txt ./release/
cp $LOVE_EXE_LOC/*.dll ./release/

zip -9 -r release.zip release
