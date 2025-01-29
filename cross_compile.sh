#!/bin/bash

dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

mkdir -p $dir/out/
rm -f $dir/out/*

platforms=(
    "linux/arm"
    "linux/amd64"
    "linux/arm64"
    "linux/386"
    "darwin/amd64"
    "darwin/arm64"
    "windows/386"
    "windows/amd64"
    "windows/arm64")

for platform in "${platforms[@]}"
do
    platform_split=(${platform//\// })
    GOOS=${platform_split[0]}
    GOARCH=${platform_split[1]}
    output_name="farside"

    tar_name="farside_${GOOS}_${GOARCH}.tar.gz"
    if [ $GOOS = "darwin" ]; then
        tar_name="farside_macOS_${GOARCH}.tar.gz"
    fi

    if [ $GOOS = "windows" ]; then
        output_name+=".exe"
    fi

    compile_cmd="GOOS=$GOOS GOARCH=$GOARCH go build -ldflags='-s -w' -o $output_name ."
    echo "└ $compile_cmd"
    eval $compile_cmd
    if [ $? -ne 0 ]; then
        echo "An error has occurred! Aborting the script execution..."
        exit 1
    fi

    tar -czvf out/$tar_name $output_name
    rm -f $output_name
done
