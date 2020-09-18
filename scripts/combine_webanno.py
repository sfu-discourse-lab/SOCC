# This script operates directly on the "annotation" folder output by exporting a WebAnno project
# for SOCC, this folder is SOCC\annotated\Appraisal\curation
# Each of \annotation's sub-folders contains a TSV that contains the annotations for the given comment.
# This script puts all of those TSVs into one long file, appending one after the other. In that file,
# commented lines using '#' indicate when the source TSVs begin and end.

import os
from smart_open import smart_open
import re

# path to a folder containing only the WebAnno TSVs
projectpath = input('Path to project folder: (e.g. C:\\...\\curation)')
# directory to output
outputpath = input("Path to write new TSV to: (e.g. 'C:\\...\\newfile.tsv')")

# get the subfolders of /curation
folders = os.listdir(projectpath)
# since all TSVs should be named CURATION_USER.tsv, we need to record the folder name to know which comment is being annotated.
# I use an embedded list for this.
files = [[f, os.listdir(os.path.join(projectpath, f))] for f in folders]
# so for each file 'f' in files, f[0] is the folder that f is contained in, and f[1] is the name of f
# check that each folder contains exactly one CURATION_USER.tsv file
if any([len(f[1]) for f in files]) > 1:
    bad_folders = [f[0] for f in files if len(f[1]) > 1]
    raise Exception('Some folders have more than one file:', bad_folders)
else:
    # since they have exactly one entry each, there's no point in keeping the filename in a list
    files = [[f[0], f[1][0]] for f in files]
    # check that that file is CURATION_USER.tsv
    if any([f[1] != 'CURATION_USER.tsv' for f in files]):
        bad_names = [f[1] for f in files if f[1] != 'CURATION_USER.tsv']
        raise Exception('Expected files named CURATION_USER.tsv; unexpected file names found:', bad_names)
        for f in files:
            if f != 'CURATION_USER.tsv':
                print(f)
    else:
        print('Found curated annotations')

# start combining the files
verbose = False     # setting this to True may help troubleshooting
newfile = ''
for f in files:
    name = f[0]
    f_path = os.path.join(projectpath, f[0], f[1])
    # indicate the beginning and end of a comment, and what that comment's name is
    newfile = newfile + '#comment: ' + name + '\n'
    with smart_open(f_path, 'r', encoding='utf-8') as f_io:
        newfile = newfile + f_io.read() + '#end of comment\n\n'
    if verbose:
        print('processed', name)

# output
print('All files processed, writing to', outputpath)
with smart_open(outputpath, 'w') as output:
        output.write(newfile)
print('Finished writing.')