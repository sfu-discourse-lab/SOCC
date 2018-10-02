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
writename = input('Name for the file that will be created (e.g. all_socc_annotations): ') + '.csv'
writepath = input('Folder to write the new file to (e.g. C:\\...\\Documents\\): ') + writename
# what to put for blank entries:
blank_entry = 'None'

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

# go through the comments, extract the sentences, clean the comments so pandas can read them later, then build a
# pandas data frame combining each comment as it is done

# these are the actual column headers for the TSV files
# some Appraisal TSVs do not have graduation, hence the need for two lists of names
appraisal_longheaders = ['sentpos', 'charpos', 'word', 'attlab', 'attpol', 'gralab', 'grapol']
appraisal_shortheaders = ['sentpos', 'charpos', 'word', 'attlab', 'attpol']
negation_headers = ['sentpos', 'charpos', 'word', 'negation']
# some comments have no annotations
no_annotation = ['sentpos', 'charpos', 'word']
appraisal_possnames = [no_annotation, appraisal_shortheaders, appraisal_longheaders]
negation_possnames = [no_annotation, negation_headers]

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

# use the mapping csv to provide comment counter names in addition to old names
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


def readprojfile(source, project):
    """
    Reads a WebAnno TSV into a pandas dataframe. One column is often read as full of NaN's due to the TSVs'
    original formatting, so this function drops any columns with NaN's.

    :param source: the path to a WebAnno TSV
    :param possnames: the headers that may occur in the TSV, as a list of lists of headers.
        The function will check each list within possnames to see if its length is equal to the number of columns
    :param project: 'app' if Appraisal, 'neg' if negation.
    :return: a pandas dataframe containing the information in the original TSV
    """
    # set possnames
    if project == "neg" or project.lower() == "negation":
        possnames = negation_possnames
        project = "neg"
    elif project == "app" or project.lower() == "appraisal":
        possnames = appraisal_possnames
        project = "app"
    else:
        print("Project type not recognized. Use 'neg' or 'att'.")
        possnames = None

    newdf = pd.read_csv(source, sep='\t', header=None)
    newdf = newdf.dropna(axis=1, how='all')
    if (project == "neg" or project.lower() == "negation") \
            and len(newdf.columns) == 5:  # Neg annotations with arrows have an extra column we won't use
        newdf = newdf.loc[:, 0:3]  # so we'll just delete it
    for headers in possnames:
        if len(newdf.columns) == len(headers):
            newdf.columns = headers
    if all([len(newdf.columns) != i for i in [len(headers) for headers in possnames]]):
        print("No correct number of columns in", source)
    return newdf


def getlabinds_df(dataframe, correspondences, dfname="dataframe", verbose=False):
    """
    Gets the unique labels, including indices, that appear in a dataframe so that they can be searched later.

    :param dataframe: a pandas dataframe
    :param correspondences: a list or tuple of columns and labels like collabels
    :param dfname: a name for the dataframe, used for reporting when one or more columns doesn't show up
    :param verbose: a boolean; if True, tells you when a dataframe is missing a column
    :return: a list of the form [(index of column),(list of unique labels including index of that label, e.g.
    ['Appreciation','Appreciation[1]','Appreciation[2]'])
    """
    newdict = {}
    for entry in range(len(correspondences)):
        if correspondences[entry][0] in dataframe.columns:
            searchedlist = dataframe[correspondences[entry][0]].tolist()
            splitlist = [i.split('|') for i in searchedlist]
            foundlist = []
            for e in splitlist:  # each element in splitlist is currently a list
                for i in e:  # so i is a string
                    foundlist.append(i)  # so now foundlist is a list of strings
            foundlist = set(foundlist)  # convert to set so we have uniques only
            foundlist = [label for label in foundlist]  # convert foundlist back to a list
            newdict[correspondences[entry][0]] = foundlist
        else:
            if verbose:
                print(dfname, "does not include column", correspondences[entry][0])
    return newdict


def lookup_label(dataframe, column, label, commentid="dataframe", not_applicable=None, verbose=False):
    """
    Looks in the dataframe for rows matching the label and returns them.

    :param dataframe: A pandas dataframe
    :param column: which column in the dataframe to look in for the labels
    :param label: which label to look for in the column
    :param commentid: the name of the comment; the new row will have this as its first entry
    :param bothids: whether to include both comment names (e.g. aboriginal_1 and source_xx_xx)
    :param not_applicable: what to put in a cell if there is no data (e.g. something un-annotated)
    :param verbose: whether to tell you when it's done
    :param clean_suffix: the suffix appended to clean files. Default assumes you cleaned them with clean_comments.py
    :return: a list that can be used as a new row or rows. If the label has no index (e.g. 'Appreciation' or '_'), then
        all rows with those labels will be returned. If it has an index (e.g. 'Appreciation[3]'), then one row
        representing that annotated span will be returned.
        The fields in the list are, by column:
            - the comment ID
            - which sentence the span starts in
            - which sentence it ends in
            - which character it starts on
            - which character it ends on
            - which words are in the span
            - the Attitude label for the span
            - the Attitude polarity for the span
            - the graduation label for the span
            - the graduation polarity for the span
    """
    # determine if we're looking at attitude, graduation, or negation
    if 'att' in column:
        layer = 'att'
    elif 'gra' in column:
        layer = 'gra'
    elif column == 'negation':
        layer = 'neg'
    else:
        layer = 'unknown'

    # Check that both label and polarity columns are present
    if ('attlab' in dataframe.columns) ^ ('attpol' in dataframe.columns):
        if 'attlab' in dataframe.columns:
            print(commentid, 'has attlab column but no attpol column')
        if 'attpol' in dataframe.columns:
            print(commentid, 'has attpol column but no attlab column')
    if ('gralab' in dataframe.columns) ^ ('grapol' in dataframe.columns):
        if 'gralab' in dataframe.columns:
            print(commentid, 'has gralab column but no grapol column')
        if 'grapol' in dataframe.columns:
            print(commentid, 'has grapol column but no gralab column')

    # look for labels with brackets (e.g. 'Appreciation[3]')
    if '[' in label:
        mask = [(label in i) for i in dataframe[column].tolist()]
        founddf = dataframe[mask]
        # get the sentence(s) of the label
        foundsentstart = int(re.search(r'^.*-', founddf['sentpos'].tolist()[0]).group()[:-1])
        foundsentend = int(re.search(r'^.*-', founddf['sentpos'].tolist()[-1]).group()[:-1])

        # get the character positions for the new row
        # look at which character the label starts in
        foundcharstart = int(re.search(r'^.*-', founddf['charpos'].tolist()[0]).group()[:-1])
        # look at which character the label ends in
        foundcharend = int(re.search(r'-.*$', founddf['charpos'].tolist()[-1]).group()[1:])

        # concatenate the words for the new row
        foundwords = ''
        for word in founddf['word']:
            foundwords = foundwords + word + ' '
        foundwords = foundwords[:-1]

        # get the labels for the new row
        # in case of pipes, figure out which one is the real label
        posslabels = founddf[column].tolist()
        posslabels = posslabels[0]
        posslabels = posslabels.split('|')
        labelindex = posslabels.index(label)

        # now look through the columns and find the appropriate labels
        # Each column is converted to a list. The first item in the list is used to find the label.
        # This item is split by '|' in case of stacked annotations.
        # Before, we found the index of the label we want. We get the found label from this index.
        if layer == 'att':
            if 'attlab' in founddf.columns:
                foundattlab = founddf['attlab'].tolist()[0].split('|')[labelindex]
                # We want to cut off the index (e.g. 'Appreciation[3]' -> 'Appreciation')
                # search() finds everything up to the '[', and .group()[:-1] returns what it found, minus the '['
                foundattlab = re.search(r'^.*\[', foundattlab).group()[:-1]
            else:
                foundattlab = not_applicable
            if 'attpol' in founddf.columns:
                foundattpol = founddf['attpol'].tolist()[0].split('|')[labelindex]
                foundattpol = re.search(r'^.*\[', foundattpol).group()[:-1]
            else:
                foundattpol = not_applicable
            foundgralab = not_applicable
            foundgrapol = not_applicable
        elif layer == 'gra':
            if 'gralab' in founddf.columns:
                foundgralab = founddf['gralab'].tolist()[0].split('|')[labelindex]
                foundgralab = re.search(r'^.*\[', foundgralab).group()[:-1]
            else:
                foundgralab = not_applicable
            if 'grapol' in founddf.columns:
                foundgrapol = founddf['grapol'].tolist()[0].split('|')[labelindex]
                foundgrapol = re.search(r'^.*\[', foundgrapol).group()[:-1]
            else:
                foundgrapol = not_applicable
            foundattlab = not_applicable
            foundattpol = not_applicable
        elif layer == 'neg':
            if 'negation' in founddf.columns:
                foundneglab = founddf['negation'].tolist()[0].split('|')[labelindex]
                foundneglab = re.search(r'^.*\[', foundneglab).group()[:-1]
            else:
                foundneglab = not_applicable
        else:
            print(label, "I can't tell which label this is.")

        # put all that together into a list for a new row
        if layer == 'att' or layer == 'gra':
            foundrow = [commentid, foundsentstart, foundsentend, foundcharstart, foundcharend,
                        foundwords, foundattlab, foundattpol, foundgralab, foundgrapol]
        elif layer == 'neg':
            foundrow = [commentid, foundsentstart, foundsentend, foundcharstart, foundcharend,
                        foundwords, foundneglab]
        else:
            print("I couldn't make a new row because I don't know which label this is")
        if verbose:
            print('Done with comment', commentid, "label", label)
        return foundrow

    # look for unlabelled spans (i.e. label '_')
    elif label == '_':
        if layer == 'neg':
            mask = [(label in i) for i in dataframe[column].tolist()]
            founddf = dataframe[mask]
        # If the layer is Attitude or Graduation, check for spans with a label but no polarity or vice versa
        # and be sure that any spans returned as unlabelled have no label or polarity
        elif layer == 'att' or layer == 'gra':
            attmask = []
            gramask = []
            if 'attlab' in dataframe.columns and 'attpol' in dataframe.columns:
                mask1 = [(label in i) for i in dataframe['attlab'].tolist()]
                mask2 = [(label in i) for i in dataframe['attpol'].tolist()]
                for i in range(len(mask1)):
                    if mask1[i] is not mask2[i]:
                        print('row', i, 'has mismatched Attitude labels')
                attmask = [a and b for a, b in zip(mask1, mask2)]
            if 'gralab' in dataframe.columns and 'grapol' in dataframe.columns:
                mask3 = [(label in i) for i in dataframe['gralab'].tolist()]
                mask4 = [(label in i) for i in dataframe['grapol'].tolist()]
                for i in range(len(mask3)):
                    if mask3[i] is not mask4[i]:
                        print('row', i, 'has mismatched Graduation labels')
                gramask = [a and b for a, b in zip(mask3, mask4)]
            if attmask and not gramask:
                mask = attmask
            elif gramask and not attmask:
                mask = gramask
            elif attmask and gramask:
                mask = [a and b for a, b in zip(attmask, gramask)]
            elif not attmask and not gramask:  # this will return all rows if there's no attlab or
                mask = [True for i in range(len(dataframe))]  # gralab, since there's no annotations at all.
            founddf = dataframe[mask]
        else:
            print("Layer unrecognized when looking for unlabelled spans")
        # find the sentences
        sentences = []
        for i in range(len(founddf['sentpos'])):
            sentences.append(
                int(  # we want to do math on this later
                    re.search(
                        r'^.*-', founddf['sentpos'].tolist()[i]  # finds whatever comes before a '-'
                    ).group()[:-1]  # returns the string it found
                ))

        # find the character positions
        charpositions = []
        for i in range(len(founddf['charpos'])):
            charpositions.append(
                (int(re.search(r'^.*-', founddf['charpos'].tolist()[i]).group()[:-1]),
                 int(re.search(r'-.*$', founddf['charpos'].tolist()[i]).group()[1:]))
            )

        # find all the words
        allfoundwords = founddf['word'].tolist()

        # find consecutive unlabelled words
        foundspans = []
        span_number = -1
        last_match = False
        for i in range(len(allfoundwords)):
            if i - 1 in range(len(allfoundwords)):  # if this isn't the first word
                # check if this word came right after the last one
                if sentences[i - 1] == sentences[i] and \
                        (charpositions[i - 1][-1] == (charpositions[i][0] - 1) or \
                         charpositions[i - 1][-1] == (charpositions[i][0])):
                    if not last_match:  # if this is not a continuation of the previous span
                        span_number += 1  # keep track of the number we're on (index of foundspans)
                        # add the row for this span to foundspans
                        if layer == 'att' or layer == 'gra':
                            foundspans.append([commentid,  # comment ID
                                               sentences[i - 1],  # sentence start
                                               sentences[i],  # sentence end
                                               charpositions[i - 1][0],  # character start
                                               charpositions[i][-1],  # character end
                                               allfoundwords[i - 1] + ' ' + allfoundwords[i],  # words
                                               not_applicable,  # Labels are all assumed to be absent.
                                               not_applicable,  # Per earlier code, it should tell you if that is
                                               not_applicable,  # not actually the case.
                                               not_applicable, ])
                        elif layer == 'neg':
                            foundspans.append([commentid,  # comment ID
                                               sentences[i - 1],  # sentence start
                                               sentences[i],  # sentence end
                                               charpositions[i - 1][0],  # character start
                                               charpositions[i][-1],  # character end
                                               allfoundwords[i - 1] + ' ' + allfoundwords[i],  # words
                                               not_applicable])
                        last_match = True  # record these two i's as contiguous

                    else:  # (this word is a continuation of the previous span)
                        foundspans[span_number].pop(4)  # remove the ending char position so we can replace it
                        oldwords = foundspans[span_number].pop(4)  # remove the words from the span to replace it
                        foundspans[span_number].insert(4, charpositions[i][-1])  # add the last character of this word
                        foundspans[span_number].insert(5, oldwords + ' ' + allfoundwords[i])  # add the words together

                else:
                    last_match = False  # record these two i's as non-contiguous
                    # check if this is the first pair of words we're looking at
                    if i == 1:  # i would equal 1 bc we skip i=0 (since we looked backwards)
                        # if i=1 and the first and second words are non-contiguous, we need to add
                        # the first word to foundspans.
                        if layer == 'att' or layer == 'gra':
                            foundspans.append([commentid,  # comment ID
                                               sentences[i - 1],  # sentence start
                                               sentences[i - 1],  # sentence end
                                               charpositions[i - 1][0],  # character start
                                               charpositions[i - 1][-1],  # character end
                                               allfoundwords[i - 1],  # word
                                               not_applicable,  # Labels are all assumed to be absent.
                                               not_applicable,  # Per earlier code, it should tell you if that is
                                               not_applicable,  # not actually the case.
                                               not_applicable, ])
                        elif layer == 'neg':
                            foundspans.append([commentid,  # comment ID
                                               sentences[i - 1],  # sentence start
                                               sentences[i - 1],  # sentence end
                                               charpositions[i - 1][0],  # character start
                                               charpositions[i - 1][-1],  # character end
                                               allfoundwords[i - 1],  # word
                                               not_applicable])
                    # look ahead to see if the next word is a continuation of this span:
                    if i + 1 in range(len(sentences)):
                        if sentences[i + 1] != sentences[i] and charpositions[i + 1][-1] != (charpositions[i][0] + 1):
                            span_number = span_number + 1  # if so, keep track of the index
                            if layer == 'att' or layer == 'gra':
                                foundspans.append([commentid,  # comment ID
                                                   sentences[i],  # sentence start
                                                   sentences[i],  # sentence end
                                                   charpositions[i][0],  # character start
                                                   charpositions[i][-1],  # character end
                                                   allfoundwords[i],  # word
                                                   not_applicable,  # Labels are all assumed to be absent.
                                                   not_applicable,  # Per earlier code, it should tell you if that is
                                                   not_applicable,  # not actually the case.
                                                   not_applicable, ])
                            elif layer == 'neg':
                                foundspans.append([commentid,  # comment ID
                                                   sentences[i],  # sentence start
                                                   sentences[i],  # sentence end
                                                   charpositions[i][0],  # character start
                                                   charpositions[i][-1],  # character end
                                                   allfoundwords[i],  # word
                                                   not_applicable])
                        # else: the loop continues
                    else:  # if there is no following word and this one isn't a continuation, it's its own word.
                        span_number = span_number + 1
                        if layer == 'att' or layer == 'gra':
                            foundspans.append([commentid,  # comment ID
                                               sentences[i],  # sentence start
                                               sentences[i],  # sentence end
                                               charpositions[i][0],  # character start
                                               charpositions[i][-1],  # character end
                                               allfoundwords[i],  # word
                                               not_applicable,  # Labels are all assumed to be absent.
                                               not_applicable,  # Per earlier code, it should tell you if that is
                                               not_applicable,  # not actually the case.
                                               not_applicable, ])
                        elif layer == 'neg':
                            foundspans.append([commentid,  # comment ID
                                               sentences[i],  # sentence start
                                               sentences[i],  # sentence end
                                               charpositions[i][0],  # character start
                                               charpositions[i][-1],  # character end
                                               allfoundwords[i],  # word
                                               not_applicable])  # no negation
        if verbose:
            print('Done with comment', commentid, "label", label)
        return foundspans

    # look for one-word annotated spans (e.g. 'Appreciation'
    elif ((label in attlabs) or
          (label in attpols) or
          (label in gralabs) or
          (label in grapols) or
          (label in neglabs)):
        # create subset dataframe - stricter than other conditions
        mask = [(label == i) for i in dataframe[column].tolist()]
        founddf = dataframe[mask]
        # find the sentences
        sentences = []
        for i in range(len(founddf['sentpos'])):
            sentences.append(
                int(  # we want to do math on this later
                    re.search(
                        r'^.*-', founddf['sentpos'].tolist()[i]  # finds whatever comes before a '-'
                    ).group()[:-1]  # returns the string it found, minus 1 character from the end
                ))

        # find the character positions
        charpositions = []
        for i in range(len(founddf['charpos'])):
            charpositions.append(
                (int(re.search(r'^.*-', founddf['charpos'].tolist()[i]).group()[:-1]),
                 int(re.search(r'-.*$', founddf['charpos'].tolist()[i]).group()[1:]))
            )

        # find the words
        allfoundwords = founddf['word'].tolist()

        # in case of pipes, figure out which one is the real label
        posslabels = founddf[column].tolist()
        posslabels = posslabels[0]
        posslabels = posslabels.split('|')
        labelindex = posslabels.index(label)

        # now look through the columns and find the appropriate labels
        # Each column is converted to a list. The first item in the list is used to find the label.
        # This item is split by '|' in case of stacked annotations.
        # Before, we found the index of the label we want. We get the found label from this index.
        foundspans = []
        for i in range(len(founddf)):
            # since these are one word long, the starting and ending sentences are the same.
            foundsentstart = sentences[i]
            foundsentend = foundsentstart

            # find the characters the word starts and ends with
            foundcharstart = charpositions[i][0]
            foundcharend = charpositions[i][1]

            # find the word
            foundwords = allfoundwords[i]

            if layer == 'att':
                if 'attlab' in founddf.columns:
                    foundattlab = founddf['attlab'].tolist()[0].split('|')[labelindex]
                else:
                    foundattlab = not_applicable
                if 'attpol' in founddf.columns:
                    foundattpol = founddf['attpol'].tolist()[0].split('|')[labelindex]
                else:
                    foundattpol = not_applicable
                foundgralab = not_applicable
                foundgrapol = not_applicable
            elif layer == 'gra':
                if 'gralab' in founddf.columns:
                    foundgralab = founddf['gralab'].tolist()[0].split('|')[labelindex]
                else:
                    foundgralab = not_applicable
                if 'grapol' in founddf.columns:
                    foundgrapol = founddf['grapol'].tolist()[0].split('|')[labelindex]
                else:
                    foundgrapol = not_applicable
                foundattlab = not_applicable
                foundattpol = not_applicable
            elif layer == 'neg':
                if 'negation' in founddf.columns:
                    foundneglab = founddf['negation'].tolist()[0].split('|')[labelindex]
                else:
                    foundneglab = not_applicable
            else:
                print(label, "I can't tell which label this is.")

            # put all that together into a list for a new row
            if layer == 'att' or layer == 'gra':
                foundrow = [commentid, foundsentstart, foundsentend, foundcharstart, foundcharend,
                            foundwords, foundattlab, foundattpol, foundgralab, foundgrapol]
            elif layer == 'neg':
                foundrow = [commentid, foundsentstart, foundsentend, foundcharstart, foundcharend,
                            foundwords, foundneglab]
            else:
                print("I couldn't make a new row because I don't know which label this is")
            # add that row to foundspans
            foundspans.append(foundrow)

        if verbose:
            print('Done with comment', commentid, "label", label)
        return foundspans

    else:
        print('Your label was not recognized')


# more info to help process the TSVs
sentence_indicator = '#Text='  # what WebAnno TSVs have written to indicate the full text of a sentence
sent_startpos = len(sentence_indicator)  # where the text for a sentence would actually start
name_indicator = '#comment: '  # text added to the combined tsv to indicate the name of each comment
name_startpos = len(name_indicator)  # where the text for the comment name would actually start
# set up the data frame to be filled in
new_df_columns = ('comment',
                  'comment_counter',
                  'sentstart',
                  'sentend',
                  'charstart',
                  'charend',
                  'span',
                  'attlab',
                  'attpol',
                  'gralab',
                  'grapol',
                  'neglab',)
new_df = pd.DataFrame(columns=new_df_columns)

# combine negation and Appraisal annotations
if appraisal_comments_path and negation_comments_path:
    # Do stuff with appraisal
    print('Processing appraisal comments')
    new_appraisal_df = new_df
    sentences_df = pd.DataFrame()
    for comment in appraisal_comments_list:
        if comment:  # due to how the comments list is made, it ends in a '' which can't be read properly
                        # extract sentences and clean them
            linelist = comment.split('\n')
            clean_comment_lines = []
            sentences = []
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
                        lastmatch_sent=False
                    if re.match(name_indicator, line):  # if the line has the text for a comment name
                        # set the names
                        oldname = line[name_startpos:]
                        if mappingdict1 or mappingdict2:
                            # get the comment_counter name - note that file extensions may vary between .txt and .tsv
                            # because of how files were managed in WebAnno, hence the replacement of the extension
                            newname = oldname[:-4] + '.txt'
                            if newname in mappingdict1:
                                newname = mappingdict1[newname]
                            elif newname in mappingdict2:
                                newname = mappingdict2[newname]
                # if the line was not commented out, put it in the new "clean" list:
                else:
                    clean_comment_lines.append(line)
            # put the sentences into a df and add them to the existing df
            new_sentences_df = pd.DataFrame()
            new_sentences_df['span'] = sentences
            print('Processing comment', oldname)

            # put the comment into a pandas df
            clean_comment = '\n'.join(clean_comment_lines)
            clean_comment_buffer = StringIO(clean_comment)
            clean_df = readprojfile(clean_comment_buffer, 'app')
            # Find which labels occur in the sentence
            labinds = getlabinds_df(clean_df, appraisal_collabels)
            foundrows = []
            for i in range(len(appraisal_collabels)):
                searchcolumn = appraisal_collabels[i][0]  # which column to look in
                if searchcolumn in clean_df.columns:
                    searchlabels = labinds[searchcolumn]  # which labels to look for in that column
                    for searchlabel in searchlabels:
                        if searchlabel != '_':  # don't include blank spans
                            foundstuff = lookup_label(clean_df,
                                                      searchcolumn,
                                                      searchlabel,
                                                      commentid=oldname,
                                                      not_applicable=blank_entry,
                                                      verbose=False)
                            if '[' in searchlabel:  # in this case, foundstuff is one row of data
                                foundrows.append(foundstuff)
                            else:  # in this case, foundstuff is many rows of data
                                for row in foundstuff:
                                    foundrows.append(row)
            # make a dataframe with all the info we just added so that we can add it to the master df
            foundrows_df = pd.DataFrame(foundrows, columns=('comment',
                                                            'sentstart',
                                                            'sentend',
                                                            'charstart',
                                                            'charend',
                                                            'span',
                                                            'attlab',
                                                            'attpol',
                                                            'gralab',
                                                            'grapol',))
            # add in the comment_counter name
            if mappingdict1 or mappingdict2:
                foundrows_df['comment_counter'] = newname
            # flesh out the new sentences df
            for column in new_df_columns:
                if column in ('charstart', 'charend', 'attlab', 'attpol', 'gralab', 'grapol', 'neglab'):
                    new_sentences_df[column] = blank_entry
                elif column in ('sentstart', 'sentend'):
                    # fill in the sentence positions
                    new_sentences_df[column] = [i for i in range(1, len(sentences) + 1)]
                elif column == 'comment':
                    new_sentences_df[column] = oldname
                elif column == 'comment_counter':
                    new_sentences_df[column] = newname
            # we want to include character positions
            # read the TSV and make a new quick DF of sentences and characters
            # this will let us find which character #'s a sentence starts and ends with
            sentchar_df = pd.DataFrame(columns=('sentence', 'charstart', 'charend'))
            # prepare "sentence" column
            sentence_numbers = []
            for i in clean_df['sentpos'].tolist():
                # find the number before a hyphen, return that number, then coerce it into an integer and add it to
                # sentence_numbers
                sentence_numbers.append(int(re.search(r'^.*-', i).group()[:-1]))
            sentchar_df['sentence'] = sentence_numbers
            # prepare "charstart" and "charend" columns
            charstarts = []
            charends = []
            for i in clean_df['charpos'].tolist():
                charstarts.append(int(re.search(r'^.*-', i).group()[:-1]))
                charends.append(int(re.search(r'-.*$', i).group()[1:]))
            sentchar_df['charstart'] = charstarts
            sentchar_df['charend'] = charends
            # add in character position info to the dataframe
            new_sents_charstarts = []
            new_sents_charends = []
            for i in new_sentences_df['sentstart']:
                startlist = sentchar_df.loc[sentchar_df.sentence == i, 'charstart'].tolist()
                endlist = sentchar_df.loc[sentchar_df.sentence == i, 'charend'].tolist()
                new_sentences_df.loc[new_sentences_df.sentstart == i, 'charstart'] = min(startlist)
                new_sentences_df.loc[new_sentences_df.sentstart == i, 'charend'] = max(endlist)
            sentences_df = sentences_df.append(new_sentences_df)
            # add this comment's information to the Appraisal df
            foundrows_df['neglab'] = blank_entry
            new_appraisal_df = new_appraisal_df.append(foundrows_df)

    # Do the same for negation
    print('Processing negation comments')
    new_negation_df = new_df
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
                # if the line was not commented out, put it in the new "clean" list:
                else:
                    clean_comment_lines.append(line)
            print('Processing comment', oldname)

            # put the comment into a pandas df
            clean_comment = '\n'.join(clean_comment_lines)
            clean_comment_buffer = StringIO(clean_comment)
            clean_df = readprojfile(clean_comment_buffer, 'neg')
            # Find which labels occur in the sentence
            labinds = getlabinds_df(clean_df, negation_collabels)
            foundrows = []
            for i in range(len(negation_collabels)):
                searchcolumn = negation_collabels[i][0]  # which column to look in
                if searchcolumn in clean_df.columns:
                    searchlabels = labinds[searchcolumn]  # which labels to look for in that column
                    for searchlabel in searchlabels:
                        if searchlabel != '_':  # don't include blank spans
                            foundstuff = lookup_label(clean_df,
                                                      searchcolumn,
                                                      searchlabel,
                                                      commentid=oldname,
                                                      not_applicable=blank_entry,
                                                      verbose=False)
                            if '[' in searchlabel:  # in this case, foundstuff is one row of data
                                foundrows.append(foundstuff)
                            else:  # in this case, foundstuff is many rows of data
                                for row in foundstuff:
                                    foundrows.append(row)
            # make a dataframe with all the info we just added so that we can add it to the master df
            foundrows_df = pd.DataFrame(foundrows, columns=('comment',
                                                            'sentstart',
                                                            'sentend',
                                                            'charstart',
                                                            'charend',
                                                            'span',
                                                            'neglab',))
            # add in the comment_counter name
            if mappingdict1 or mappingdict2:
                foundrows_df['comment_counter'] = newname
            # make blank columns to smooth the appending process
            for column in ('attlab', 'attpol', 'gralab', 'grapol',):
                foundrows_df[column] = blank_entry
            new_negation_df = new_df.append(foundrows_df)

    # combine all those dataframes
    new_df = new_df.append(new_appraisal_df)
    new_df = new_df.append(new_negation_df)
    new_df = new_df.append(sentences_df)
    # sort by which character the row starts with, then which character it ends at
    # this means that it will read chronologically, with longer spans appearing first
    new_df = new_df.sort_values(by=['comment', 'charstart', 'charend'],
                                ascending=[True, True, False])
else:
    print("Can't combine only one project.")

# add in the constructiveness and toxicity annotations
if contox_path:
    # make empty columns in new_df
    contox_columns = ('is_constructive', 'is_constructive:confidence', 'toxicity_level', 'toxicity_level:confidence')
    for column in contox_columns:
        new_df[column] = 'error'
    contox_df = pd.read_csv(contox_path)
    length_error = []      # in case there are any duplicate rows in the contox_df
    for column in contox_columns:
        for comment in contox_df['comment_counter']:
            if len(contox_df.loc[contox_df.comment_counter == comment, column]) > 1:
                length_error.append(comment)
                print('Length error for', comment)
            print('Adding', column, 'to', comment)
            new_df.loc[new_df.comment_counter == comment, column] = \
                contox_df.loc[contox_df.comment_counter == comment, column].tolist()[0]
            # .tolist()[0] was added to get a straightforward string out of the relevant entry
    if length_error:
        print('Duplicate rows found. You may want to check these comments:')
        for i in length_error:
            print(i)
else:
    print('Not adding constructiveness and toxicity as no path to it was given.')

# write the df
if writepath:
    new_df.to_csv(writepath)
    print('New dataframe written to', writepath)
else:
    print('Not writing to file as no file path was specified.')