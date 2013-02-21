#!/bin/bash
##   process.sh
## This script has several checks to make sure everything is set up correctly.
## Be sure to check the PreText documentation for details.

## Directory structure check.
cd ..
if [[ ! -d "docs" ]] || [[ ! -d "process" ]] || [[ ! -d "output" ]] || [[ ! -d "PreText" ]]
then
    echo "Directory structure is NOT correct.  Should be four directories named docs, process, output, and PreText.  PreText... OUT"
    exit
fi
echo "Directory structure looks good."
cd ./PreText

## Number of arguments check.
if [[ -z $1 ]] || [[ -z $2 ]] || [[ -z $3 ]] || [[ -z $4 ]] || [[ -z $5 ]]
then
    echo "Incorrect number of arguments.  PreText...OUT"
    exit
fi
echo "Correct number of arguments."

## Argument names check.
if [ ! -f $1 ] && [[ "$1" != "NO" ]]
then
    echo "File "$1" does not exist.  PreText...OUT"
    exit
elif [ ! -f $2 ] && [[ "$2" != "NO" ]]
then
    echo "File "$2" does not exist.  PreText...OUT"
    exit
elif [ ! -f $3 ] && [[ "$3" != "NO" ]]
then
    echo "File "$3" does not exist.  PreText...OUT"
    exit
elif [[ $4 -lt 1 ]] || [[ $4 -gt 99 ]]
then
    echo "DFT must be a number between 1 and 99.  You entered "$4", I suggest 10."
    exit
fi
echo "Args "$1", "$2", "$3" look good."
echo "Document frequency thresholding set at "$4" percent."


echo -ne "The format(s) to be printed are NTFLONG (default format)"
IFS=',' read -ra ADDR <<< "$5"
for i in "${ADDR[@]}"; do
    if [[ "$i" == "NTFWIDE" ]] || [[ "$i" == "NTFSVM" ]] || [[ "$i" == "TFIDFLONG" ]] || [[ "$i" == "TFIDFWIDE" ]] || [[ "$i" == "TFIDFSVM" ]]
    then
        echo -ne ", $i "
    fi
done
echo ""
read -p "Is this correct?  Enter yes/no:"
[ "$REPLY" != "yes" ] && exit

echo "Sweet, moving on..."
## docs must either contain LN downloads OR a documents.txt file

cd ../docs
if [ -f "documents.txt" ]
then
    read -p "You have supplied a documents.txt file in the docs directory.  Carrying on..."
    echo "documents.txt" > files.list
    mv documents.txt ../process
    mv files.list ../process

    cd ../PreText
    cp * ../process
    ls * > PreText.list
    mv PreText.list ../process
    cd ../process

else
    ls * > files.list
    mv * ../process

    cd ../PreText
    cp * ../process
    ls * > PreText.list
    mv PreText.list ../process
    cd ../process

    perl LN_mdata_1.pl

    echo "Meta data extraction and processing formatting complete."
fi

echo "Beginning text preparation..."
perl text_tokens.pl $1 $2 $3

while read file ;
do mv "$file" ../docs ;
done < files.list

echo "Representing text as data..."

perl term_doc.pl $4 $5

mv documents.txt ../output
mv tokens.txt ../output
mv *.tsv ../output

count=`ls -1 *.dat 2>/dev/null | wc -l`
if [ $count != 0 ]
then
    mv *.dat ../output
fi


while read file ;
do mv "$file" ../PreText ;
done < PreText.list

echo "You ran PreText with arguments $1, $2, $3, $4, and $5 on the following list of files: " > _time.txt
while read file ;
do echo "$file" >> _time.txt ;
done < files.list

DATE=$(date +%Y%m%d)
TIME=$(date +%T)

mv _time.txt $DATE-$TIME.txt

rm *.list
