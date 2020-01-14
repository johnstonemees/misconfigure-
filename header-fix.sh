#!/bin/bash
​
if [ "$#" -ne 1 ]; then
  echo "Please input a file containing a list of header files"
  exit -1
fi
​
​
​
INPUT_FILE="$1"
​
cat "$INPUT_FILE" | while read -r header_file; do
  for line in $(cat -n "$header_file" | grep "#include" | grep -v "<" | awk '{print $1}'); do #get only the line numbers with the include directive
											      #filter against < > includes because we don't want system paths
​
       h_name=$(sed -n "${line}p" "$header_file" | awk '{print $2}' | sed 's/\"/ /g') #extract the header file name itself, strip quotes
       h_path="$(find . -name $h_name -type f)" # find the files path
       sed -i "${line}s|.*#include.*|#include \"$h_path\"|" "$header_file" #for a line in the header file, replace with absolute path
								       #use | as delimiter so sed can handle forward slashes in the path
  done
done
