#!/bin/bash

# Script for generating auto-generated CSharp files from proto files
#
# First, clean the output directory
rm -rf build/gen

# Then, create the output directory
mkdir -p build/gen

# Finally, compile the proto files
protoc --proto_path=. --csharp_out=build/gen --csharp_opt=file_extension=.g.cs,base_namespace ansys/api/discovery/v*/**.proto
