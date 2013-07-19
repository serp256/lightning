#!/bin/bash

mkdir -p $1/android
mkdir -p $1/ios

mlmodule=$1;
mlmodule=`echo ${mlmodule:0:1} | tr  '[a-z]' '[A-Z]'`${mlmodule:1};

touch $1/$mlmodule.ml
touch $1/$mlmodule.mli
touch $1/android/$1_android.c
touch $1/android/Light$mlmodule.java
touch $1/ios/$1_ios.m
m4 -D __mlmodule__=$mlmodule -D __pluginname__=$1 Makefile.plugin > $1/Makefile

git add -f $1