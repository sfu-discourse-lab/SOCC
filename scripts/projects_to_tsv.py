from smart_open import smart_open
import pandas as pd
import re
from io import StringIO

# find the comments
appraisal_comments_path = input('Path to combined Appraisal WebAnno formatted comments tsv'
                                '(e.g. C:\\...\\combined_appraisal_webanno.tsv): ')
negation_comments_path = input('Path to combined negation WebAnno formatted comments tsv'
                               '(e.g. C:\\...\\combined_negation_webanno.tsv): ')
mapping_csv = input("Path to your mapping of names e.g. 'C:\\...\\comment_counter_appraisal_mapping.csv'")
contox_path = input("Path to constructiveness and toxicity annotations e.g."
                    "'C:\\...\\SFU_constructiveness_toxicity_corpus.csv'")
writename = input('Name for the file that will be created (e.g. all_socc_annotations): ') + '.tsv'
writepath = input('Folder to write the new file to (e.g. C:\\...\\Documents\\): ') + writename
# what to put for blank entries:
blank_entry = '_'

# split the comments so that we can iterate over each individual one
if appraisal_comments_path:
    with smart_open(appraisal_comments_path, 'r') as f:
        comments_str = f.read()
    appraisal_comments_list = comments_str.split('#end of comment\n\n')
else:
    print("Not using Appraisal annotations as no path was provided.")

if negation_comments_path:
    with smart_open(negation_comments_path, 'r') as f:
        comments_str = f.read()
    negation_comments_list = comments_str.split('#end of comment\n\n')
else:
    print("Not using negation annotations as no path was provided.")

# these are the actual column headers for the TSV files
# some Appraisal TSVs do not have graduation, hence the need for two lists of names
appraisal_longheaders = ['sentpos', 'charpos', 'word', 'attlab', 'attpol', 'gralab', 'grapol']
appraisal_shortheaders = ['sentpos', 'charpos', 'word', 'attlab', 'attpol']
negation_shortheaders = ['sentpos', 'charpos', 'word', 'negation']
negation_longheaders = ['sentpos', 'charpos', 'word', 'negation', 'XNEG']
# some comments have no annotations
no_annotation = ['sentpos', 'charpos', 'word']
appraisal_possnames = [no_annotation, appraisal_shortheaders, appraisal_longheaders]
negation_possnames = [no_annotation, negation_shortheaders, negation_longheaders]

# labels that can be found in different columns
attlabs = ('Appreciation', 'Affect', 'Judgment')
attpols = ('pos', 'neu', 'neg')
gralabs = ('Force', 'Focus')
grapols = ('up', 'down')

neglabs = ('NEG', 'SCOPE', 'FOCUS', 'XSCOPE')
# create some tuples to show which columns go with which labels
# doesn't include polarity because we'll pull that out based on the label
# (each instance of Attitude should have both label and polarity)
appraisal_collabels = ((appraisal_longheaders[3], attlabs),
                       (appraisal_longheaders[5], gralabs),)
# this next tuple is within another tuple so that the same commands we need later will iterate correctly
negation_collabels = (('negation', neglabs),)

# more info to help process the TSVs
sentence_indicator = '#Text='  # what WebAnno TSVs have written to indicate the full text of a sentence
sent_startpos = len(sentence_indicator)  # where the text for a sentence would actually start
name_indicator = '#comment: '  # text added to the combined tsv to indicate the name of each comment
name_startpos = len(name_indicator)  # where the text for the comment name would actually start


def readprojfile_withblanks(source, project,
                            neg_possnames=negation_possnames, app_possnames=appraisal_possnames,
                            not_applicable=blank_entry):
    """
    Reads a WebAnno TSV into a pandas dataframe. One column is often read as full of NaN's due to the TSVs'
    original formatting, so this function drops any columns with NaN's. This function also adds blanks for any columns
    which are not included in the original TSV.

    :param source: the path to a WebAnno TSV
    :param possnames: the headers that may occur in the TSV, as a list of lists of headers.
        The function will check each list within possnames to see if its length is equal to the number of columns
    :param project: 'app' if Appraisal, 'neg' if negation.
    :param neg_possnames: a list of lists of possible headers for the negation TSVs
    :param app_possnames: a list of lists of possible headers for the Appraisal TSVs
    :param not_applicable: what to put for entries that are empty
    :return: a pandas dataframe containing the information in the original TSV
    """
    # set possnames
    if project == "neg" or project.lower() == "negation":
        possnames = neg_possnames
        project = "neg"
    elif project == "app" or project.lower() == "appraisal":
        possnames = app_possnames
        project = "app"
    else:
        print("Project type not recognized. Use 'neg' or 'att'.")
        possnames = None

    newdf = pd.read_csv(source, sep='\t', header=None)
    newdf = newdf.dropna(axis=1, how='all')
    for headers in possnames:
        if len(newdf.columns) == len(headers):
            newdf.columns = headers
    if all([len(newdf.columns) != i for i in [len(headers) for headers in possnames]]):
        print("No correct number of columns in", source)
    # add in missing columns
    if len(newdf.columns) != len(possnames[-1]):
        for column in possnames[-1]:
            if column not in newdf.columns:
                newdf[column] = not_applicable
    return newdf


# We will want the names to match accross annotations, so let's get the mapping in
if mapping_csv:
    mapping1 = pd.read_csv(mapping_csv)
    list1 = mapping1['appraisal_negation_annotation_file_name'].tolist()
    list2 = mapping1['comment_counter'].tolist()
    # dictionary of original to comment counter names
    mappingdict1 = {}
    for i in range(max(len(list1), len(list2))):
        mappingdict1[list1[i]] = list2[i]
    # same dictionary in reverse
    mappingdict2 = {}
    for i in range(max(len(list1), len(list2))):
        mappingdict2[list2[i]] = list1[i]

# go through the comments, extract the sentences, clean the comments so pandas can read them later, then build a
# pandas data frame combining each comment as it is done
if appraisal_comments_path and negation_comments_path:
    # Prepare a combined df
    appdf = pd.DataFrame()
    combined_sentences = pd.DataFrame(columns=('comment', 'sent'))
    # Do stuff with appraisal
    print('Processing appraisal comments')
    for comment in appraisal_comments_list:
        if comment:  # due to how the comments list is made, it ends in a '' which can't be read properly
            # extract sentences and clean them
            linelist = comment.split('\n')
            clean_comment_lines = []
            sentences = []
            lastmatch_sent = False    # whether the last line had the sentence text in it
            for line in linelist:
                # get the sentences and comment names and discard other commented lines
                if re.match('#', line):  # if WebAnno commented out the line
                    if re.match(sentence_indicator, line):  # if the line has the text for a sentence
                        # add that sentence to the sentences list
                        if not lastmatch_sent:
                            # Normally, each line with '#Text=' is a new sentence. Add the relevant part to the list:
                            sentences.append(line[sent_startpos:])
                        else:
                            # for some reason aboriginal_11 has 2 '#Text=' lines, but only one sentence.
                            # This conditional addresses that
                            sentences[-1] = sentences[-1] + line[sent_startpos:]
                        lastmatch_sent = True
                    else:
                        lastmatch_sent = False
                    if re.match(name_indicator, line):  # if the line has the text for a comment name
                        # set the name
                        # file extensions may vary between .txt and .tsv because of how files were managed in WebAnno.
                        # The extension is replaced so that names match across projects.
                        oldname = line[name_startpos:]
                        oldname = oldname[:-4] + '.txt'

                # if the line was not commented out, put it in the new "clean" list:
                else:
                    clean_comment_lines.append(line)
                    lastmatch_sent = False
            # Now that we have the sentences and comment name, get them into the combined sentences df
            # one file was misnamed in an earlier version of the Appraisal files. Let's fix that here:
            if oldname == 'aboriginal_16.txt':
                oldname = 'aboriginal_17.txt'
            # let's also add the comment counter name
            comment_counter = mappingdict1[oldname]
            sentences_df = pd.DataFrame()
            sentences_df['sent'] = sentences
            sentences_df['oldname'] = oldname
            sentences_df['comment_counter'] = comment_counter
            combined_sentences = combined_sentences.append(sentences_df)
            print('Processing comment', str(appraisal_comments_list.index(comment)) + ':', oldname)

            # put the comment into a pandas df
            clean_comment = '\n'.join(clean_comment_lines)
            clean_comment_buffer = StringIO(clean_comment)
            clean_df = readprojfile_withblanks(clean_comment_buffer, 'app')
            clean_df['oldname'] = oldname
            clean_df['comment_counter'] = comment_counter
            appdf = appdf.append(clean_df)

    # get the negation columns
    negdf = pd.DataFrame()
    for comment in negation_comments_list:
        if comment:  # due to how the comments list is made, it ends in a '' which can't be read properly
            # extract sentences and clean them
            linelist = comment.split('\n')
            clean_comment_lines = []
            # sentences list not needed since we have this from Appraisal
            for line in linelist:
                # get the sentences and comment names and discard other commented lines
                if re.match('#', line):  # if WebAnno commented out the line
                    if re.match(name_indicator, line):  # if the line has the text for a comment name
                        # set the name
                        oldname = line[name_startpos:]
                        # file extensions may vary between .txt and .tsv because of how files were managed in WebAnno.
                        # The extension is replaced so that names match across projects.
                        oldname = oldname[:-4] + '.txt'
                # if the line was not commented out, put it in the new "clean" list:
                else:
                    clean_comment_lines.append(line)
            print('Processing comment', str(negation_comments_list.index(comment)) + ':', oldname)
            # let's also add the comment counter name
            comment_counter = mappingdict1[oldname]
            # put the comment into a pandas df
            clean_comment = '\n'.join(clean_comment_lines)
            clean_comment_buffer = StringIO(clean_comment)
            clean_df = readprojfile_withblanks(clean_comment_buffer, 'neg')
            clean_df['oldname'] = oldname
            clean_df['comment_counter'] = comment_counter
            negdf = negdf.append(clean_df)

    # Combine appraisal and negation annotations
    app_commentlist = set(appdf['oldname'].tolist())  # list of unique comment names for App
    neg_commentlist = set(negdf['oldname'].tolist())  # and for neg
    # check that the same comments are in both
    if neg_commentlist != app_commentlist:
        if not all([i in neg_commentlist for i in app_commentlist]):
            for comment in neg_commentlist:
                if comment not in app_commentlist:
                    print(comment, 'is in negation but not Appraisal')
        if not all([i in app_commentlist for i in neg_commentlist]):
            for comment in app_commentlist:
                if comment not in neg_commentlist:
                    print(comment, 'is in Appraisal but not negation')
    combined_df = appdf
    combined_df['negation'] = blank_entry
    combined_df['XNEG'] = blank_entry
    for comment in app_commentlist:
        print('Combining Appraisal and negation annotations for', comment)
        combined_df.loc[combined_df.oldname == oldname, 'negation'] = negdf.loc[negdf.oldname == oldname, 'negation']
        combined_df.loc[combined_df.oldname == oldname, 'XNEG'] = negdf.loc[negdf.oldname == oldname, 'XNEG']

    # Separate the sentence numbers in combined_df
    sentence_numbers = []
    for i in combined_df['sentpos'].tolist():
        # find the number before a hyphen, return that number, then coerce it into an integer and add it to
        # sentence_numbers
        sentence_numbers.append(int(re.search(r'^.*-', i).group()[:-1]))
    combined_df['sentence'] = sentence_numbers

    # Read the constructiveness and toxicity df
    if contox_path:
        contox_columns = ('comment', 'is_constructive', 'is_constructive:confidence',
                          'toxicity_level', 'toxicity_level:confidence')
        contox_df = pd.read_csv(contox_path)
        # Sort the comment list so that the TSV is more easily navigable
        comment_counter_list = [mappingdict1[i] for i in app_commentlist]
        comment_counter_list.sort()
        # Put all the information together
        newstring = ''
        for comment in comment_counter_list:
            print('Adding constructiveness and toxicity to', comment)
            comment_slice = combined_df.loc[combined_df.comment_counter == comment]
            contox_slice = contox_df.loc[contox_df.comment_counter == comment]
            # .tolist()[0] is added to get a straightforward string out of the relevant entry
            comment_oldname = comment_slice['oldname'].tolist()[0]
            comment_is_constructive = contox_slice['is_constructive'].tolist()[0]
            comment_is_const_conf = contox_slice['is_constructive:confidence'].tolist()[0]
            comment_toxicity = contox_slice['toxicity_level'].tolist()[0]
            comment_tox_conf = contox_slice['toxicity_level:confidence'].tolist()[0]
            # Put the data describing the whole comment into one string
            # \n is replaced with | to make things more human-readable
            comment_prefix = '# comment= ' + comment_oldname + ' / ' + comment + '\n' + \
                             '# is_constructive= ' + comment_is_constructive.replace('\n', '|') + '\tconfidence= ' + \
                             str(comment_is_const_conf).replace('\n', '|') + '\n' + \
                             '# toxicity_level= ' + comment_toxicity.replace('\n', '|') + '\tconfidence= ' + \
                             str(comment_tox_conf).replace('\n', '|')
            # get the sentences for this comment
            sentences_slice = combined_sentences.loc[combined_sentences.comment_counter == comment]
            sentences = sentences_slice['sent'].tolist()
            # go through each sentence, get a slice for the rows of that sentence, put a header containing the sentence,
            # then put the annotated words after that
            comment_body = ''
            for i in set(comment_slice['sentence'].tolist()):
                small_slice = comment_slice.loc[comment_slice.sentence == i]
                small_slice = small_slice.drop(columns=['oldname', 'comment_counter', 'sentence'])
                comment_body = comment_body + '\n\n#text = ' + sentences[i-1] + '\n' + \
                               small_slice.to_string(index=False)
                # (i-1 because WebAnno starts counting at 1 but Python starts at 0)
            newstring = newstring + comment_prefix + comment_body + '\n\n\n'
        if writepath:
            with smart_open(writepath, 'w') as f:
                print('Writing new file...')
                f.write(newstring)
                print('New file written!')
        else:
            print('No write path was given, so no file will be generated.')
    else:
        print('No constructiveness/toxicity path was given, so this information won\'t show up')
else:
    print('Either Appraisal or negation path was missing. What can I do?')
