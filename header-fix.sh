#!/bin/bash

if [ "$#" -ne 1 ]; then
  echo "Please input a file containing a list of header files"
  exit -1
fi

#still dealing with a bug with unset resolved path, my stat check code did not work
#perhaps beacuse stat was not receiving an argument beause resolved_path was unset
#and thus did not have an argument and therefore no status code to return
#okay so i was right the header is getting completely stripped out on some iterations
#fix that problem and you may have fixed the other problems
#okay so the problem is faulty cut code
#new idea, maybe it's not faulty cut code and its the initial extracted path
#okay bug fixed, the problem was using a less than or equal to conditional
#vs a less than conditional, such that cut behaved as cut -d / -f3-3 where it
#should be cut -d / -f2-3

#okay that's fixed but now we might have an issue with the
#path resolution code itself
#okay the path resolution code is fundamentally broken, 
#okay got closer to the issue, from extracted path...
#okay this is the case in which an include file does an include for a file
#that is not in that directory  

INPUT_FILE="$1"
BASE_PATH="/home/mailbox/ProjectCompartmentMisfire/mozilla-central/"
i=0 # for debugging

      #print each line of the file which we assume is full of header files

cat "$INPUT_FILE" | while read -r header_file; do

      #iterate through each line number of the included file within our header file, filter against < > paths


  for line in $(cat -n "$header_file" | grep "#include" | grep -v "<" | awk '{print $1}'); do 

      ################################################################################################################

      # SO FROM HERE WE WANT TO DO SORT OF A RECURSIVE RESOLVE UNTIL THE RELATIVE HEADER PATH IS CORRECT


       
        #extract the path
        extracted_path=$(sed -n "${line}p" "$header_file" | awk '{print $2}' | sed 's|\"||g')

        #get the # of words in the path
        word_c=$(echo "$extracted_path" | sed "s|/| |g" | wc -w)
          ((++word_c)) # testing, remove this after

        #strip the header from the header file we are reading within the source directory that contains other header file 
        #juxtaheader is the header we are going to test resolved_path AGAINST

          c=$(echo "$header_file" | sed 's|/| |g' | wc -w); ((--c))
          juxta_header=$(echo "$header_file" | cut -d/ -f1-"$c") 


       #remove path component left to right until it resolves

         i=1; #set i with this initial path
       while [ "$i" -lt "$word_c" ]; do

          #so what i've done here is wrapped the cut code in an if statement to see if this fixed the problem

          resolved_path=$(echo "$extracted_path" |  cut -d/ -f"$i"-"$word_c" | sed "s|^/||g") #THIS LINE IS FAULTY UNTIL OTHERWISE MENTIONED

         
          test_header="$juxta_header/$resolved_path"
          stat "$test_header" &> /dev/null #test if the path resolves
          STAT_CODE="$?"
          if [ "$STAT_CODE" -eq 0 ]; then #if it does, echo the return code which we know is 0
          break #hopefully this breaks out of JUST this while loop
          fi
       ((++i))
       done
         if [ "$STAT_CODE" -eq 1 ]; then
           missing_header=$(echo "$test_header" | awk -F/ '{print $NF}')
           resolved_path=$(find "$BASE_PATH" -name "$missing_header" -type f -print -quit)  
           
         fi
         i=1 #reset i

     #from here we need to splice in the RESOLVED_PATH into the appropriate line of the header file which 
     #we are reading, that will be a challenge.
     #we also need to handle the case in which the file is not found, then we need to invoke find

     #now, an important thing to note is that when it resolves
     #what we actually want to write, if we can, is the resolved_path, not the test header.



    ####################### DEBUG BLOCK #######################

    #echo "line: $line, juxta_header: $juxta_header, resolved_path: $resolved_path, header_file: $header_file"

    ####################### DEBUG BLOCK #######################


     sed -i "${line}s|.*#include.*|#include \"$resolved_path\"|" "$header_file"

     ###################################################################################################################
      




      
     
  done
done
