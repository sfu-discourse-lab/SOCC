import glob
import re
from smart_open import smart_open

# set the directory of your exported project
webanno_project = input("Path to exported WebAnno project: (e.g. 'C:/.../curation')")
write_directory = input("Path to folder to write new TSVs to: (e.g. 'C:/.../clean_TSVs')")

def getcontents(directory):
    """
    Returns the file paths for all files in the specified path. Basically the same as glob.glob, but slightly changes
    the path and changes backslashes to forward slashes.

    :param directory: the path to a folder (without a '/' at the end)
    :return: a list of the contents of that folder
    """
    return [name.replace('\\', '/') for name in glob.glob(directory + '/*')]


# find the folders in your project
folders = getcontents(webanno_project)

# get the paths to each file in the project
files1 = [getcontents(doc) for doc in folders]
files = []
for i in range(len(files1)):
    try:
        files.append(files1[i][0])
    except:
        continue

# clean the files so they can be read as tsv's

# generate new names for cleaned files
commonsource = webanno_project + '/'
commonname = '/CURATION_USER.tsv'

cleannames = [name[-(len(name) - len(commonsource)):] for name in files]
cleannames = [name[:len(name) - len(commonname)] for name in cleannames]
cleannames = [name + '_cleaned.tsv' for name in cleannames]

# generate new directories for cleaned files
cleandirs = [write_directory + '/' + name for name in cleannames]


# actually clean those comments

def cleancomment(path):
    """
    Cleans a file of any lines beginning with '#' - these lines prevent the file from being read properly into a Pandas
    dataframe.

    :param path: the path to a file
    :return: the contents of the file, with any lines starting with '#' removed
    """
    newfile = []
    with smart_open(path, 'r') as f:
        for line in f.readlines():
            if re.match('#', line) is None:
                newfile.append(line)
    newfile2 = ''
    for line in newfile:
        for char in line:
            newfile2 = newfile2 + char
    return newfile2


def cleancomments(readdirs, writedirs, readnames=[]):
    """
    Cleans the comments in readdirs and writes them to writedirs. Be sure the two lists are the same length and order,
    or it will return an error.

    :param readdirs: a list of files to clean
    :param writedirs: a list of files to write to; i.e. paths to the new, clean files
    :param readnames: a list of names used to report which file has been cleaned. If unspecified, will not report that
        any files have been cleaned (but will still clean them)
    :return:
    """
    for i in range(max(len(readdirs), len(writedirs))):
        with smart_open(writedirs[i], 'w') as f:
            f.write(cleancomment(readdirs[i]))
            if readnames:
                print(readnames[i] + ' cleaned')


# Write cleaned comments to assigned folder
cleancomments(files, cleandirs, readnames=cleannames)
