## docdelim.py
## September 11, 2015
## Vito D'Orazio
## vjdorazio@gmail.com
##
## Writes filelist.txt, a file that contains a list of all the text files.
## Note that this writes the names of all files listed in the directory provided by the user.
## python 3.4.3

import glob # for extracting list of files in a location
import collections # for counting duplicate lines in a document
import re # for checking if input is valid python regex
import sys # for exiting the script with sys.exit("Error message")

## Functions
def autoDelimit (file):
    with open(file) as infile:
        counts = collections.Counter(l.strip() for l in infile)
    for line, count in counts.most_common():
        if(count>1):
            if(line.isspace()) or not line:
                continue
            k=input("\nFor document " + file + ", is " + line + " your delimiter? Answer y/n, or answer skip to move to the next file without locating a delimiter: ")
            if(k=="skip"):
                return([file,"No delimiter",0])
            if( k == "y") or (k == "yes"):
                return([file,line,count])
                break
            else:
                continue
        else:
            print("\n I could not find a document delimiter.")
            return([file,"No delimiter",0])

## Main
myfiles = open("filelist.txt","w")

print("\n\nYou're going to tell me where your text files are, and I'm going to create a list of the names of all your files in that location. For example, you will input something like /Users/vjdorazio/documents/.")

while True:
    loc = input("\nPlease tell me the location of the text files: ")
    for name in glob.glob(loc + "*"):
        myfiles.write(name + "\n")
    k = input('Are there more files someplace else? Answer y/n: ')
    if (k == "n") or (k == "no"):
        break

myfiles.close()

myfiles = open("filelist.txt", "r")
myfiledelim = open("filedelim.txt", "w")
myfiledelim.write("File\tDelimiter\tDocuments\n")

print("\nI need to know where your documents begin within your files. The line of text in your file that signals the start of a new document is referred to as your document delimiter. For a typical LexisNexis download, the regex would be \s*\d+ of \d+ DOCUMENTS\s*")
k1 = 0
for file in myfiles:
    file = file.rstrip('\n')
    myfile = open(file, "r")
    if(k1 == 1):
        delim = input("\nFor file " + file + ", please enter a python regular expression or just a string that delimits your documents. If you'd like me to try to find it automatically, enter automate: ")
    elif(k1 == 0):
        delim = input("\nFor file " + file + ", please enter a python regular expression or just a string that delimits your documents. If you'd like me to try to find it automatically, enter automate: ")
        k1 = input("\nShould I use this delimiter for every file? Answer y/n: ")
        if(k1 == "n") or (k1 == "no"):
            k1 = 1
        else:
            k1 = 2

    if(delim=="automate"):
        myfile.close()
        stuff = autoDelimit(file)
        outdelim=stuff[1]
        count=stuff[2]
    else:
        count = 0
        try:
            re.compile(delim)
            is_valid = True
        except re.error:
            is_valid = False
        if(is_valid):
            myregex = re.compile(delim)
            for line in myfile:
                result = myregex.match(line)
                if(result != None):
                    count += 1
            outdelim=delim
        else:
            for line in myfile:
                line = line.rstrip('\n')
                if(delim == line):
                    count += 1
            outdelim=delim

    if(count==0):
        count=1 # if no delimiter is located, the entire file is assumed to be one document
    print("\nThe delimiter in " + file + " is " + outdelim + " and there are " + str(count) + " documents.")
    myfiledelim.write(file + "\t" + outdelim + "\t" + str(count) + "\n")


myfiles.close()
myfiledelim.close()





