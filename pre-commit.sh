#!/bin/bash

# Derived from https://github.com/depy/my-git-hooks/blob/master/run-rspec-test-pre-commit 
# Author: Tushar Dadlani

MACHINE=`uname`

# Colors for Linux and OS X
if [ $MACHINE = "Darwin" ]; then
    {
        GREEN='\x1B[0;32m'
        RED='\x1B[0;31m' 
        ENDCOLOR='\x1B[0m'
    }

elif [ $MACHINE = "Linux" ]; then 
    {
        GREEN='\e[0;32m'
        RED='\e[0;31m' 
        ENDCOLOR='\e[0m'
    }
fi

# Stash unstaged changes before running tests
git stash -q --keep-index



# Check for syntax errors in all models and controllers (not in views so far).
for file in `find app -name "*.rb"  -type f `
do
    ruby -c $file 2>&1> /dev/null || {
    echo "Fix syntax errors in your code and try again." && {
    git stash pop -q
    exit 1
    }  
}
    
done

# Run tests
RUN_TESTS_CMD='bundle exec rspec spec_no_rails'
read NUM_FAILS NUM_PASS <<< `${RUN_TESTS_CMD} --format=progress | grep "example"| grep "fail"| awk {'print $3,"\t", ($1 - $3) '} 2> /dev/null`

# Unstash
git stash pop -q

if [ $NUM_FAILS -ne 0 ] 
then
    printf  "${RED}Cannot commit! \n${NUM_FAILS} tests failed.\n" || exit 1
    printf "${GREEN}${NUM_PASS} tests passed.\n" || exit 1 
    printf "${ENDCOLOR}Run 'bundle exec rspec spec_no_rails' from your Rails root for more details.\n" 
    exit 1
else
    printf  "${GREEN}${NUM_PASS} tests passed in total.\n"
    printf  "You didn't break anything. Congrats!\n${ENDCOLOR}"
    exit 0
fi
