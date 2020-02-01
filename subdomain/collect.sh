cat results.txt | tr "<BR>" "\n" | grep ['^[:blank:]]' | sort | uniq
