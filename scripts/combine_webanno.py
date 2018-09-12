from glob import glob
from smart_open import smart_open
import re

# directory with TSVs
projectpath = input('Path to project folder: (e.g. C:/.../curation)')
# directory to output
outputpath = input("Path to folder to write new TSV to: (e.g. 'C:/.../newfile.tsv')")


def getcontents(directory):
    """
    Returns the file paths for all files in the specified path (directory). Identical to glob.glob() except that it
    converts '\\' to '/'
    """
    return [name.replace('\\', '/') for name in glob(directory + '/*')]


folders = getcontents(projectpath)
files = [getcontents(doc)[0] for doc in folders]

newfile = ''
for file in files:
    not_name = re.search(r'.*/', file).group()
    endlength = len(file[len(not_name):]) + 1
    beginlength = len(re.search(r'.*/', file[:-endlength]).group())
    name = file[beginlength:-endlength]
    newfile = newfile + '\n' + name + '\n'
    with smart_open(file, 'r') as f:
        newfile = newfile + f.read()
    print('processed', name)

# output
if outputpath:
    with smart_open(outputpath, 'w') as output:
        output.write(newfile)
    print('Combined everything!')
else:
    print("Didn't write anything. No output path was given.")
