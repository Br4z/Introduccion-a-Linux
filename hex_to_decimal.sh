#!/bin/bash


while read -r number; do
	echo "16x$number = 10x$(echo "obase=10; ibase=16; $number" | bc)"
done
