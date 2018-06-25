# code is still in development

library(tokenizers)   # used to re-calculate number of words for graphs
library(ggplot2)      # makes graphs
library(reshape2)     # prepares data for graphing
library(viridis)      # color schemes for graphs
library(gridExtra)    # compare 2 graphs in one plot

# start global timer
global.time = proc.time()

###### Getting the annotation dataframes ######
# start timer
timer = proc.time()

# Read files
setwd("C:/Users/lcava/Documents/_My Actual Folders/Research/Discourse Processing/socc_comments/re_downloaded")
appraisal.annotations <- read.csv("combined_appraisal_comments.csv", stringsAsFactors=FALSE)
negation.annotations <- read.csv("combined_negation_comments.csv", stringsAsFactors=FALSE)

setwd("C:/Users/lcava/Documents/_My Actual Folders/Research/Discourse Processing/socc_comments/analysis")
contox.annotations <- read.csv("SFU_constructiveness_toxicity_corpus.csv")

# remove the extra column
appraisal.annotations <- appraisal.annotations[,2:length(appraisal.annotations)]
negation.annotations <- negation.annotations[,2:length(negation.annotations)]

# Check for any blank appraisal.annotations
mismatches = subset(appraisal.annotations,
                    appraisal.annotations$attlab == "*" | appraisal.annotations$attpol == "*" | appraisal.annotations$gralab == "*" | appraisal.annotations$grapol == "*")

# Add a column for whether there is an annotation or not
appraisal.annotations$att = appraisal.annotations$attlab != "None" & appraisal.annotations$attpol != "None"
appraisal.annotations$gra = appraisal.annotations$gralab != "None" & appraisal.annotations$grapol != "None"

# remove constructiveness annotations not annotated for Appraisal
contox.annotations = subset(contox.annotations, comment_counter %in% appraisal.annotations$comment_counter)
## Make constructiveness + toxicity annotations more code-friendly
# change is_constructive for better graph legibility
contox.annotations$is_constructive = as.character(contox.annotations$is_constructive)
contox.annotations[contox.annotations$is_constructive == 'yes',]$is_constructive = 'constructive'
contox.annotations[contox.annotations$is_constructive == 'no',]$is_constructive = 'non-constructive'
# coerce toxicity into characters
contox.annotations$toxicity_level = as.character(contox.annotations$toxicity_level)
contox.annotations$toxicity_level.confidence = as.character(contox.annotations$toxicity_level.confidence)
# make a new column for the second-most popular toxicity annotation
contox.annotations$toxicity_level_2 = contox.annotations$toxicity_level
contox.annotations$toxicity_level.confidence_2 = contox.annotations$toxicity_level.confidence
# toxicity_level and toxicity_level.confidence now have only the most popular option
# toxicity_level_2 and toxicity_level.confidence_2 have the info for #2
# or, if there's no second choice, they copy the info from the most popular
df = contox.annotations[nchar(contox.annotations$toxicity_level) > 1,]
for (i in as.numeric(rownames(df))){
  contox.annotations$toxicity_level_2[i] =
    strsplit(contox.annotations$toxicity_level[i], '\n')[[1]][2]
  contox.annotations$toxicity_level.confidence_2 =
    strsplit(contox.annotations$toxicity_level.confidence[i], '\n')[[1]][2]
  contox.annotations$toxicity_level[i] =
    strsplit(contox.annotations$toxicity_level[i], '\n')[[1]][1]
  contox.annotations$toxicity_level.confidence[i] =
    strsplit(contox.annotations$toxicity_level.confidence[i], '\n')[[1]][1]
}
# make toxicity levels numeric
contox.annotations$toxicity_level = as.numeric(contox.annotations$toxicity_level)
contox.annotations$toxicity_level.confidence = as.numeric(contox.annotations$toxicity_level.confidence)
contox.annotations$toxicity_level_2 = as.numeric(contox.annotations$toxicity_level_2)
contox.annotations$toxicity_level.confidence_2 = as.numeric(contox.annotations$toxicity_level.confidence_2)

# check timer
proc.time() - timer

###### Overlaying negation ######
# start timer
timer = proc.time()

## check that all comment names match
appraisal.comments = unique(as.character(appraisal.annotations$comment))
negation.comments = unique(as.character(negation.annotations$comment))
comment.matching = data.frame(comment = c(appraisal.comments, negation.comments),
                              appraisal = NA,
                              negation = NA)
comment.matching$appraisal = comment.matching$comment %in% appraisal.comments
comment.matching$negation = comment.matching$comment %in% negation.comments
comment.matching$both = comment.matching$appraisal && comment.matching$negation

# comments not in either
# subset(comment.matching, !both)
# comments in only appraisal
# subset(comment.matching, appraisal & !negation)
# comments in only negation
# subset(comment.matching, !appraisal & negation)
# aboriginal_16 and _17 are actually the same
appraisal.annotations[appraisal.annotations$comment == 'aboriginal_16_cleaned.tsv',]$comment = 'aboriginal_17_cleaned.tsv'
# With that adjustment, all of those subsets have no rows, so all comments in one df are in the other.

## add in a column to appraisal.annotations to show whether there is a NEG keyword in the span
appraisal.annotations$NEG = FALSE
negdf = subset(negation.annotations, label=='NEG')

# Mark $NEG as TRUE if there's a NEG keyword there
bar = txtProgressBar(style=3)
for (i in 1:length(negdf$label))
{
  appdf = appraisal.annotations[appraisal.annotations$comment == negdf$comment[i],]
  for (j in 1:length(appdf$comment))
  {
    if (negdf$charend[i] > appdf$charstart[j] & negdf$charend[i] <= appdf$charend[j])
    {
      appraisal.annotations[appraisal.annotations$comment == negdf$comment[i],]$NEG[j] = T
    }
  }
  setTxtProgressBar(bar, value=i/length(negdf$label))
}
close(bar)

## do the same thing for FOCUS
appraisal.annotations$FOCUS = FALSE
focusdf = subset(negation.annotations, label=='FOCUS')

# Mark $FOCUS as TRUE if there's a FOCUS keyword there
bar = txtProgressBar(style=3)
for (i in 1:length(focusdf$label))
{
  appdf = appraisal.annotations[appraisal.annotations$comment == focusdf$comment[i],]
  for (j in 1:length(appdf$comment))
  {
    if (focusdf$charend[i] > appdf$charstart[j] & focusdf$charend[i] <= appdf$charend[j])
    {
      appraisal.annotations[appraisal.annotations$comment == focusdf$comment[i],]$FOCUS[j] = T
    }
  }
  setTxtProgressBar(bar, value=i/length(negdf$label))
}
close(bar)

# check timer
proc.time() - timer
###### Getting basic counts ######
# start timer
timer = proc.time()

# So that we can count them later, get subsets of "appraisal.annotations" by label
# Attitude labels
attrows = subset(appraisal.annotations, attlab != "None")
approws = appraisal.annotations[appraisal.annotations$attlab=="Appreciation",]
judrows = appraisal.annotations[appraisal.annotations$attlab=="Judgment",]
affrows = appraisal.annotations[appraisal.annotations$attlab=="Affect",]
# Attitude polarities
posrows = appraisal.annotations[appraisal.annotations$attpol=="pos",]
negrows = appraisal.annotations[appraisal.annotations$attpol=="neg",]
neurows = appraisal.annotations[appraisal.annotations$attpol=="neu",]
# Graduation labels
grarows = subset(appraisal.annotations, gralab != "None")
forcerows = appraisal.annotations[appraisal.annotations$gralab=="Force",]
focusrows = appraisal.annotations[appraisal.annotations$gralab=="Focus",]
# Graduation polarities
upgradrows = appraisal.annotations[appraisal.annotations$grapol=="up",]
downgradrows = appraisal.annotations[appraisal.annotations$grapol=="down",]

## Appraisal
# get simple counts
# Attitude labels
appcount = length(approws$attlab)
judcount = length(judrows$attlab)
affcount = length(affrows$attlab)
# Attitude polarities
poscount = length(posrows$attpol)
negcount = length(negrows$attpol)
neucount = length(neurows$attpol)
# Graduation labels
forcecount = length(forcerows$gralab)
focuscount = length(focusrows$gralab)
# Graduation polarities
upgradcount = length(upgradrows$grapol)
downgradcount = length(downgradrows$grapol)

# Make dataframes to put counts of matched labels and polarities in
attcounts = data.frame(row.names = c("neg", "pos", "neu", "total"))
gracounts = data.frame(row.names = c("up", "down", "total"))

# put in counts for Attitude
attcounts$appreciation = c(
  length(approws[approws$attpol=="neg",]$attlab),  # count of negative appreciation
  length(approws[approws$attpol=="pos",]$attlab),  # count of positive appreciation
  length(approws[approws$attpol=="neu",]$attlab),  # count of neutral appreciation
  length(approws$attlab)                           # count of all appreciation
)

attcounts$judgment = c(
  length(judrows[judrows$attpol=="neg",]$attlab),
  length(judrows[judrows$attpol=="pos",]$attlab),
  length(judrows[judrows$attpol=="neu",]$attlab),
  length(judrows$attlab)
)

attcounts$affect = c(
  length(affrows[affrows$attpol=="neg",]$attlab),
  length(affrows[affrows$attpol=="pos",]$attlab),
  length(affrows[affrows$attpol=="neu",]$attlab),
  length(affrows$attlab)
)

attcounts$total = attcounts$appreciation + attcounts$judgment + attcounts$affect

# put in counts for Graduation
gracounts$force = c(
  length(forcerows[forcerows$grapol=="up",]$gralab),
  length(forcerows[forcerows$grapol=="down",]$gralab),
  length(forcerows$gralab)
)

gracounts$focus = c(
  length(focusrows[focusrows$grapol=="up",]$gralab),
  length(focusrows[focusrows$grapol=="down",]$gralab),
  length(focusrows$gralab)
)

gracounts$total = gracounts$force + gracounts$focus

## Negation
negcounts = data.frame( row.names = c("neg", "pos", "neu", "all pols"))
# a function to count the percentage of spans with negation given a DF
countnegs <- function(df){
  length(rownames(subset(df, NEG == TRUE))) / length(rownames(df))
}
# get the counts
negcounts$app = c(
  countnegs(subset(approws, attpol == "neg")),
  countnegs(subset(approws, attpol == "pos")),
  countnegs(subset(approws, attpol == "neu")),
  countnegs(approws)
)
negcounts$jud = c(
  countnegs(subset(judrows, attpol == "neg")),
  countnegs(subset(judrows, attpol == "pos")),
  countnegs(subset(judrows, attpol == "neu")),
  countnegs(judrows)
)
negcounts$aff = c(
  countnegs(subset(affrows, attpol == "neg")),
  countnegs(subset(affrows, attpol == "pos")),
  countnegs(subset(affrows, attpol == "neu")),
  countnegs(affrows)
)
negcounts$all.labs = c(
  countnegs(subset(attrows, attpol == "neg")),
  countnegs(subset(attrows, attpol == "pos")),
  countnegs(subset(attrows, attpol == "neu")),
  countnegs(attrows)
)

# check timer
proc.time() - timer

###### Getting counts based on article ######
appraisal.annotations$article = NA
bar = txtProgressBar(style=3)
for (i in 1:length(appraisal.annotations$article)){
  appraisal.annotations$article[i] = strsplit(appraisal.annotations$comment[i], '_')[[1]][1]
  setTxtProgressBar(bar, value=i/length(appraisal.annotations$span))
}
close(bar)

# create a df for article-based counts
article.counts = data.frame(article = unique(appraisal.annotations$article))
# fill it in
article.counts$app = NA
article.counts$jud = NA
article.counts$aff = NA

article.counts$pos = NA
article.counts$neu = NA
article.counts$neg = NA

for (i in 1:length(article.counts$article)){
  article.counts$app[i] = sum(subset(appraisal.annotations, article == article.counts$article[i])$attlab == 'Appreciation')
  article.counts$jud[i] = sum(subset(appraisal.annotations, article == article.counts$article[i])$attlab == 'Judgment')
  article.counts$aff[i] = sum(subset(appraisal.annotations, article == article.counts$article[i])$attlab == 'Affect')
  
  article.counts$pos[i] = sum(subset(appraisal.annotations, article == article.counts$article[i])$attpol == 'pos')
  article.counts$neg[i] = sum(subset(appraisal.annotations, article == article.counts$article[i])$attpol == 'neg')
  article.counts$neu[i] = sum(subset(appraisal.annotations, article == article.counts$article[i])$attpol == 'neu')
}

# total Attitude
article.counts$att = article.counts$app + article.counts$jud + article.counts$aff

# Percentages of labels
article.counts$apppct = article.counts$app/article.counts$att
article.counts$judpct = article.counts$jud/article.counts$att
article.counts$affpct = article.counts$aff/article.counts$att

# Percentages of polarities
article.counts$pospct = article.counts$pos/article.counts$att
article.counts$negpct = article.counts$neg/article.counts$att
article.counts$neupct = article.counts$neu/article.counts$att

###### Finding stacked spans ######
# start timer
timer = proc.time()

# find and mark stacked spans
print("Looking for stacked spans.")
appraisal.annotations$stacky = F
look = 7     # how far ahead to look
bar = txtProgressBar(style=3)
for(i in 1:length(appraisal.annotations$span))
{
  for(n in 1:look)
  {
    # check that there is an appropriate next row to look at
    if (match(i+n, 1:length(appraisal.annotations$span), nomatch=FALSE))
    {
      if( # if there's overlap in character position between this and the 'next'
          appraisal.annotations$charstart[i+n] <= appraisal.annotations$charend[i]
          & appraisal.annotations$comment[i+n] == appraisal.annotations$comment[i]
          # and there is some annotation for both rows
          & (appraisal.annotations$att[i+n] | appraisal.annotations$gra[i+n])
          & (appraisal.annotations$att[i] | appraisal.annotations$gra[i])
          )
      {
        appraisal.annotations$stacky[i] = T
        appraisal.annotations$stacky[i+n] = T
      }
    }
  }
  setTxtProgressBar(bar, value=i/length(appraisal.annotations$span))
}
close(bar)
stacked.spans = subset(appraisal.annotations, stacky)
appraisal.annotations$stacky <- NULL
stacked.spans$stacky <- NULL

stacked.spans = stacked.spans[order(stacked.spans$comment, stacked.spans$charstart),]
rownames(stacked.spans) <- NULL

# add column for which spans contain which
look = 10
stacked.spans$contains = 0
bar = txtProgressBar(style=3)
for(i in 1:length(stacked.spans$span))
{
  stacked.spans$contains[i] = 0
  for(n in 1:look)
  {
    if(match(i+n, 1:length(stacked.spans$span), nomatch=FALSE))
    {
      if(stacked.spans$charstart[i+n] <= stacked.spans$charend[i] &
         stacked.spans$comment[i+n] == stacked.spans$comment[i]) # same thing as before checking for overlap
      {
        stacked.spans$contains[i+n] = i
      }
      if(stacked.spans$charstart[i+n] == stacked.spans$charstart[i] &
         stacked.spans$charend[i+n] == stacked.spans$charend[i] &
         stacked.spans$comment[i+n] == stacked.spans$comment[i]) # same thing as before checking for overlap
      {
        stacked.spans$contains[i] = i + n
      }
    }
    if(match(i-n, 1:length(stacked.spans$span), nomatch=FALSE))
    {
      if (stacked.spans$charstart[i] <= stacked.spans$charend[i-n] # but looking backwards too
          & stacked.spans$comment[i-n] == stacked.spans$comment[i])
      {
        stacked.spans$contains[i-n] = i
      }
      if (stacked.spans$charstart[i] == stacked.spans$charstart[i-n] &
          stacked.spans$charend[i] == stacked.spans$charend[i-n] &
          stacked.spans$comment[i-n] == stacked.spans$comment[i]){
        stacked.spans$contains[i] = i-n
      }
    }
  }
  setTxtProgressBar(bar, value=i/length(stacked.spans$span))
}
close(bar)

stacked.spans$contained.by = 0
bar = txtProgressBar(style=3)
for(i in 1:length(stacked.spans$span))
{
  stacked.spans$contained.by[i] = 0
  for(n in 1:look)
  {
    if(match(i-n, 1:length(stacked.spans$span), nomatch=FALSE))
    {
      if (stacked.spans$charstart[i] <= stacked.spans$charend[i-n] & # looking backwards only
          stacked.spans$comment[i-n] == stacked.spans$comment[i])
      {
        stacked.spans$contained.by[i] = i-n
      }
      if (stacked.spans$charstart[i] == stacked.spans$charstart[i-n] &
          stacked.spans$charend[i] == stacked.spans$charend[i-n] &
          stacked.spans$comment[i] == stacked.spans$comment[i-n])
      {
        stacked.spans$contained.by[i-n] = i
      }
    }
  }
  setTxtProgressBar(bar, value=i/length(stacked.spans$span))
}
close(bar)

# find labels + polarities for the contained span
stacked.spans$contained.attlab = NA
stacked.spans$contained.attpol = NA
stacked.spans$contained.gralab = NA
stacked.spans$contained.grapol = NA
bar = txtProgressBar(style=3)
for (i in 1:length(stacked.spans$comment)){
  if (stacked.spans$contains[i] != 0){
    stacked.spans$contained.attlab[i] = stacked.spans$attlab[stacked.spans$contains[i]]
    stacked.spans$contained.attpol[i] = stacked.spans$attpol[stacked.spans$contains[i]]
    stacked.spans$contained.gralab[i] = stacked.spans$gralab[stacked.spans$contains[i]]
    stacked.spans$contained.grapol[i] = stacked.spans$grapol[stacked.spans$contains[i]]
  }
  setTxtProgressBar(bar, value=i/length(stacked.spans$comment))
}
close(bar)

stacks = na.omit(stacked.spans)
stacks$att.samepol = stacks$attpol == stacks$contained.attpol
stacks$att.samelab = stacks$attlab == stacks$contained.attlab
stacks$gra.samepol = stacks$grapol == stacks$contained.grapol
stacks$gra.samelab = stacks$gralab == stacks$contained.gralab

# check timer
proc.time() - timer

#### Stacked Graduation ####
# start timer
timer = proc.time()

# get a data.frame of all spans with graduation and the attitude spans that contain them
print("Looking for stacked graduation.")
graduation = stacked.spans[0,]
look = 6     # how far ahead to look
bar = txtProgressBar(style=3)
for(i in 1:length(stacked.spans$span))
{
  for(n in 1:look)
  {
    # look ahead, if we see a grad annotation for this comment and an attitude one for an overlapping future one then we can include them
    if (match(i+n, 1:length(stacked.spans$span), nomatch=FALSE))
    {
      if(stacked.spans$charstart[i+n] <= stacked.spans$charend[i]  # if the charstart for the 'next' is less than charend for this one
         & stacked.spans$comment[i+n] == stacked.spans$comment[i]  # and the two are in the same comment
         & (stacked.spans$gralab[i] != "None" | stacked.spans$grapol[i] != "None")  # and there's a graduation annotation in this row
         & (stacked.spans$attlab[i+n] != "None" | stacked.spans$attpol[i+n] != "None") # and an attitude annotation in the 'next' one
         )
      {
        graduation = rbind(stacked.spans[i,], graduation)  # then add this row to the df (graduation annotation)
        graduation = rbind(stacked.spans[i+n,], graduation) # and the 'next' one (attitude annotation)
      }
    }
    # look behind for the same thing
    if (match(i-n, 1:length(stacked.spans$span), nomatch=FALSE))
    {
      if(stacked.spans$charstart[i] <= stacked.spans$charend[i-n]  # if the charstart for this one is greater than charend for the 'previous' one
         & stacked.spans$comment[i-n] == stacked.spans$comment[i]  # and the two are in the same comment
         & (stacked.spans$gralab[i] != "None" | stacked.spans$grapol[i] != "None")  # and there's a graduation annotation in this row
         & (stacked.spans$attlab[i-n] != "None" | stacked.spans$attpol[i-n] != "None") # and an attitude annotation in the 'previous' one
      )
      {
        graduation = rbind(stacked.spans[i,], graduation)  # then add this row to the df (graduation annotation)
        graduation = rbind(stacked.spans[i-n,], graduation) # and the 'previous' one (attitude annotation)
      }
    }
  }
  setTxtProgressBar(bar, value=i/length(stacked.spans$span))
}
close(bar)

graduation = unique(graduation)
graduation = graduation[order(graduation$comment, graduation$charstart),]
graduation.oldnames = graduation # this df's rownames will be indices for the appraisal.annotations df
rownames(graduation) = 1:length(graduation$span)

# find graduation spans with ambiguous scopes
graduation.ambig = graduation[0,]
look = 5
bar = txtProgressBar(style=3)
for(i in 1:length(graduation$span))
{
  for(n in 1:look)
  {
    if (match(i+n, 1:length(graduation$span), nomatch=FALSE))
    {
      if(graduation$contains[i] != 0 # look for matching scopes, signaling ambiguity
         & graduation$contains[i] == graduation$contains[i+n])
      {
        # add this row to graduation.ambig
        graduation.ambig = rbind(graduation[i,], graduation.ambig)
        # and the next one
        graduation.ambig = rbind(graduation[i+n,], graduation.ambig)
        # and the one of which this is the scope
        graduation.ambig = rbind(graduation[graduation$contains[i],], graduation.ambig)
      }
    }
  }
  setTxtProgressBar(bar, value=i/length(graduation$span))
}
close(bar)

graduation.ambig = unique(graduation.ambig)
# order the rows properly
neworder = c()
for (i in 1:length(rownames(graduation.ambig))) neworder[i] = strtoi(rownames(graduation.ambig)[i])
graduation.ambig = graduation.ambig[order(neworder),]

# this doesn't include cases where there's multiple graduation in one attitude, e.g. graduation[53:57,]

# check timer
proc.time() - timer
###### Getting counts by comment ######
# start timer
timer = proc.time()

# make a dataframe with one column, each of which is a unique comment id
comment.counts = data.frame(unique(appraisal.annotations$comment))
colnames(comment.counts) = 'comment'

#### using the comment IDs, fill in comment length and count
### start by making empty columns
# comment_counter name
comment.counts$comment_counter = NA

# length info
comment.counts$charlength = NA
comment.counts$wordlength = NA
comment.counts$sentlength = NA

# attitude info
comment.counts$att = NA

comment.counts$appneg = NA
comment.counts$apppos = NA
comment.counts$appneu = NA

comment.counts$judneg = NA
comment.counts$judpos = NA
comment.counts$judneu = NA

comment.counts$affneg = NA
comment.counts$affpos = NA
comment.counts$affneu = NA

# graduation info
comment.counts$gra = NA

comment.counts$forceup = NA
comment.counts$forcedown = NA

comment.counts$focusup = NA
comment.counts$focusdown = NA

# constructiveness and toxicity
comment.counts$is_constructive = NA
comment.counts$is_constructive.confidence = NA
comment.counts$toxicity_level = NA
comment.counts$toxicity_level.confidence = NA

### then fill them in
## starting with basic counts

bar = txtProgressBar(style=3)
for (i in 1:length(comment.counts$comment)){
  # subset the Appraisal annotations df
  df = appraisal.annotations[appraisal.annotations$comment == comment.counts$comment[i],]
  # set comment_counter
  comment.counts$comment_counter[i] = df$comment_counter[1]
  # length by word
  comment.counts$charlength[i] = max(df$charend)
  # length by word
  words = paste(df$span, collapse = '')
  words.tokenized = tokenize_words(words, simplify = TRUE)
  comment.counts$wordlength[i] = length(words.tokenized)
  # length by sentence
  comment.counts$sentlength[i] = max(df$sentend)
  # counts for attitude
  comment.counts$att[i] = length(df[df$attlab != 'None' |
                                      df$attpol != 'None',]$attlab)
  comment.counts$appneg[i] = length(df[df$attlab == 'Appreciation' &
                                         df$attpol == 'neg',]$attlab)
  comment.counts$apppos[i] = length(df[df$attlab == 'Appreciation' &
                                         df$attpol == 'pos',]$attlab)
  comment.counts$appneu[i] = length(df[df$attlab == 'Appreciation' &
                                         df$attpol == 'neu',]$attlab)
  
  comment.counts$judneg[i] = length(df[df$attlab == 'Judgment' &
                                         df$attpol == 'neg',]$attlab)
  comment.counts$judpos[i] = length(df[df$attlab == 'Judgment' &
                                         df$attpol == 'pos',]$attlab)
  comment.counts$judneu[i] = length(df[df$attlab == 'Judgment' &
                                         df$attpol == 'neu',]$attlab)
  
  comment.counts$affneg[i] = length(df[df$attlab == 'Affect' &
                                         df$attpol == 'neg',]$attlab)
  comment.counts$affpos[i] = length(df[df$attlab == 'Affect' &
                                         df$attpol == 'pos',]$attlab)
  comment.counts$affneu[i] = length(df[df$attlab == 'Affect' &
                                         df$attpol == 'neu',]$attlab)
  # counts for graduation
  comment.counts$gra[i] = length(df[df$gralab != 'None' |
                                          df$grapol != 'None',]$gralab)
  comment.counts$forceup[i] = length(df[df$gralab == 'Force' &
                                          df$grapol == 'up',]$gralab)
  comment.counts$forcedown[i] = length(df[df$gralab == 'Force' &
                                            df$grapol == 'down',]$gralab)
  
  comment.counts$focusup[i] = length(df[df$gralab == 'Focus' &
                                          df$grapol == 'up',]$gralab)
  comment.counts$focusdown[i] = length(df[df$gralab == 'Focus' &
                                            df$grapol == 'down',]$gralab)
  # subset the constructiveness/toxicity df
  df = subset(contox.annotations, comment_counter == comment.counts$comment_counter[i])
  comment.counts$is_constructive[i] = df$is_constructive
  comment.counts$is_constructive.confidence[i] = df$is_constructive.confidence
  comment.counts$toxicity_level[i] = df$toxicity_level
  comment.counts$toxicity_level.confidence[i] = df$toxicity_level.confidence
  setTxtProgressBar(bar, value=i/length(comment.counts$comment))
}
close(bar)

## aggregate info
comment.counts$app = comment.counts$appneg + comment.counts$apppos + comment.counts$appneu
comment.counts$jud = comment.counts$judneg + comment.counts$judpos + comment.counts$judneu
comment.counts$aff = comment.counts$affneg + comment.counts$affpos + comment.counts$affneu

comment.counts$pos = comment.counts$apppos + comment.counts$affpos + comment.counts$judpos
comment.counts$neg = comment.counts$appneg + comment.counts$affneg + comment.counts$judneg
comment.counts$neu = comment.counts$appneu + comment.counts$affneu + comment.counts$judneu

comment.counts$force = comment.counts$forcedown + comment.counts$forceup
comment.counts$focus = comment.counts$focusdown + comment.counts$focusup

comment.counts$up = comment.counts$focusup + comment.counts$forceup
comment.counts$down = comment.counts$focusdown + comment.counts$forcedown

## and percent aggregate info
comment.counts$apppct = comment.counts$app/comment.counts$att
comment.counts$judpct = comment.counts$jud/comment.counts$att
comment.counts$affpct = comment.counts$aff/comment.counts$att

comment.counts$negpct = comment.counts$neg/comment.counts$att
comment.counts$pospct = comment.counts$pos/comment.counts$att
comment.counts$neupct = comment.counts$neu/comment.counts$att

comment.counts$forcepct = comment.counts$force/comment.counts$gra
comment.counts$focuspct = comment.counts$focus/comment.counts$gra

comment.counts$uppct = comment.counts$up/comment.counts$gra
comment.counts$downpct = comment.counts$down/comment.counts$gra

## Graduation/att
comment.counts$gra.att = comment.counts$gra/comment.counts$att

# check timer
proc.time() - timer

##### Count details #####
# start timer
timer = proc.time()

### Att polarity
## pos vs neg
comment.counts$posratio = (comment.counts$pos/(comment.counts$pos + comment.counts$neg) -
                             comment.counts$neg/(comment.counts$pos + comment.counts$neg))
comment.counts$catpos = comment.counts$posratio > 0
comment.counts$catneg = comment.counts$posratio < 0
# how many negative spans in positive comments?
df = subset(comment.counts, catpos, select = c('comment', 'pos', 'neg', 'neu', 'catpos'))
length(df$comment)
# 134 total comments
sum(df$neg) + sum(df$pos)
# 797 total neg or pos spans
sum(df$neg)
# 219 = 27% neg in pos comments
sum(df$pos)
# 578 = 73% pos in pos comments
sum(df$neu)
# 10 neu in pos comments

# how many positive spans in negative comments?
df = subset(comment.counts, catneg, select = c('comment', 'pos', 'neg', 'neu', 'catneg'))
length(df$comment)
# 823 total comments
sum(df$neg) + sum(df$pos)
# 5394 pos or neg spans
sum(df$pos)
# 928 = 17% pos in neg comments
sum(df$neg)
# 4466 = 83% neg in neg comments

## comments with neu
df = subset(comment.counts, select = c("comment", "pospct", "negpct", "neupct",'catpos','catneg'))
df = df[df$neupct > 0,]   # filters out comments with no neu spans
# how many are there?
length(df$comment)
# 168
# how many totally positive (aside from neu)?
length(subset(df, negpct == 0)$comment)
# 3 = 2%
# how many are mostly positive?
length(subset(df, catpos)$comment)
# 24 = 14%
# mostly negative?
length(subset(df,catneg)$comment)
# 117 = 67%
# totally negative (aside from neu)?
length(subset(df, pospct == 0)$comment)
# 16 = 10%
# truly balanced?
length(subset(df,!catpos & !catneg)$comment)
# 15 = 9%

# check timer
proc.time() - timer

###### Analyzing negation ######
# start timer
timer = proc.time()

## Dataframe of Attitude and Graduation spans with some focus of negation in them
## only including the smallest span
# start with a subset df of Att + Gra spans with focus
focusdf = subset(appraisal.annotations, (!(attlab %in% c('None', '*')) | 
                                              !(gralab %in% c('None', '*'))) &
                                            FOCUS)
rownames(focusdf) <- NULL
# get stacking info from stacked.spans
focusdf$contains = NA
focusdf$contained.by = NA
focusdf$stackrow = NA
bar = txtProgressBar(style=3)
for (i in 1:length(focusdf$span)){
  # find this span in stacked.spans
  foundrow = subset(stacked.spans, comment == focusdf$comment[i] &
                      charstart == focusdf$charstart[i] &
                      charend == focusdf$charend[i] &
                      attlab == focusdf$attlab[i])
  # if the span is actually in stacked.spans
  if (nrow(foundrow) > 0){
    # copy the info
    focusdf$contains[i] = foundrow$contains
    focusdf$contained.by[i] = foundrow$contained.by
    focusdf$stackrow[i] = as.numeric(rownames(foundrow))
    setTxtProgressBar(bar, value=i/length(focusdf$span))
  }
}
close(bar)

# find container spans and any spans they contain, then delete all but the smallest span
# start with a subset df of those that are stacked spans
focusdf$stackid = NA
df = subset(focusdf,!is.na(stackrow))
stackiter = 0
for (i in as.numeric(rownames(df))){
  # look for spans containing this one
  searchterm = paste('^', focusdf$stackrow[i], '$', sep='')
  containedid = grep(searchterm, focusdf$contained.by)
  containerid = grep(searchterm, focusdf$contains)
  # check for an existing stackid
  if (!is.na(focusdf$stackid[i])){
    currentid = focusdf$stackid[i]
  } else if (any(!is.na(containerid))){
    for (j in containedid){
      if (!is.na(focusdf$stackid[j])){
        currentid = focusdf$stackid[j]
      }
    }
  } else if (any(!is.na(containerid))){
    for (j in containerid){
      if (!is.na(focusdf$stackid[j])){
        currentid = focusdf$stackid[j]
      }
    }
  } else {
    stackiter <- stackiter + 1
    currentid <- stackiter
  }
  # put the correct stackid in whichever relevant fields exist
  focusdf$stackid[i] = currentid
  if (length(containedid) > 0) focusdf$stackid[containedid] = currentid
  if (length(containerid) > 0) focusdf$stackid[containerid] = currentid
}

# find the stackids that are not unique
df = data.frame(table(focusdf$stackid))
foundids = subset(df, Freq > 1)$Var1   # stackids that occur more than once
df = subset(focusdf, stackid %in% foundids)

# iterate over those stacks. The smallest span is always the one with the highest row number
df$keep = F
for (i in 1:length(df)){
  # we want to keep only the last row for each stackid
  if (df$stackid[i+1] != df$stackid[i]) df$keep[i] <- T
}

# remove appropriate rows from focusdf
rows_to_remove = subset(df, !keep)
rows_to_remove = as.numeric(rownames(rows_to_remove))
focusdf = focusdf[-rows_to_remove,]

# check timer
proc.time() - timer
#### global timer end ####
proc.time() - global.time
###### Visualization #####
# often need to reshape the comment counts so that they work with ggplot; melt() does this
# see http://seananderson.ca/2013/10/19/reshape/ for more info on that
## aesthetic variable setting:
fill.alpha = .5
line.color = "black" # used for histograms
txtsize = 28
palette = viridis(n=3, option= "plasma")
##### By comment #####
#### General plots per word ####
df = subset(comment.counts, select = c("comment"))
#df$attrate = comment.counts$att/comment.counts$wordlength
df$grarate = comment.counts$gra/comment.counts$wordlength
df = melt(df)
# as density plot
ggplot(data = df, mapping=aes(value, fill=variable)) + geom_density(alpha = fill.alpha)

#### Attitude ####

## Percentages of attitude polarity
# somewhat answers: do comments tend to have spans with the same polarity in them?
df = subset(comment.counts, select = c("comment", "pospct", "negpct", "neupct"))
df = df[df$pospct > 0 | df$negpct > 0 | df$neupct >0,]   # filters out comments with no pos, neu, or neg spans
df = melt(df)
# as histogram
ggplot(data=df,mapping=aes(value, fill = variable, color = line.color)) +
  geom_histogram(data = df[df$variable=="pospct",], color = line.color, aes(fill = variable), alpha = fill.alpha) +
  geom_histogram(data = df[df$variable=="negpct",], color = line.color, aes(fill = variable), alpha = fill.alpha) +
  geom_histogram(data = df[df$variable=="neupct",], color = line.color, aes(fill = variable), alpha = fill.alpha) +
  labs(title = "Attitude polarity by comment", x = "Percentage") +
  scale_fill_discrete(name="Polarity",
                      breaks=c("pospct", "negpct", "neupct"),
                      labels=c("Positive", "Negative", "Neutral")) +
  theme(text = element_text(size=txtsize))

# as density plot
ggplot(data=df,mapping=aes(value, fill = variable)) +
  geom_density(alpha = fill.alpha, bw =.025) +
  labs(title = "Attitude polarity by comment", x = "Percentage") +
  scale_fill_manual(name="Polarity",
                    values = palette,
                    breaks=c("negpct", "pospct", "neupct"),
                    labels=c("Negative", "Positive", "Neutral")) +
  theme(text = element_text(size=txtsize))

## Same plot, but looking only at comments with neu
df = subset(comment.counts, select = c("comment", "pospct", "negpct", "neupct"))
df = df[df$neupct > 0,]   # filters out comments with no neu spans
df = melt(df)
# as density plot
ggplot(data=df,mapping=aes(value, fill = variable)) +
  geom_density(alpha = fill.alpha) +
  labs(title = "Attitude polarity by comment, only comments with neutral spans", x = "Percentage") +
  scale_fill_manual(name="Polarity",
                    values = palette,
                    breaks=c("negpct", "pospct", "neupct"),
                    labels=c("Negative", "Positive", "Neutral")) +
  theme(text = element_text(size=txtsize))
# as histogram
ggplot(data=df,mapping=aes(value)) +
  geom_histogram(data = df[df$variable=="pospct",], color = line.color, aes(fill = variable), alpha = fill.alpha) +
  geom_histogram(data = df[df$variable=="negpct",], color = line.color, aes(fill = variable), alpha = fill.alpha) +
  geom_histogram(data = df[df$variable=="neupct",], color = line.color, aes(fill = variable), alpha = fill.alpha) +
  labs(title = "Polarity by comment", x = "Percentage") +
  scale_fill_discrete(name = "Polarity",
                      breaks=c("pospct", "negpct", "neupct"),
                      labels=c("Positive", "Negative", "Neutral")) +
  theme(text = element_text(size=txtsize))

## looking only at comments with neu, pospct - negpct
df = subset(comment.counts, neupct > 0, select = c("comment", "neupct", "posratio"))
# density plot
ggplot(mapping=aes(df$posratio)) + geom_density(fill = "purple", alpha = fill.alpha) +
  labs(title = "Positivity of comment attitudes", x="percent of positive spans minus percent of negative spans") +
  theme(text = element_text(size=txtsize))
# histogram
ggplot(mapping=aes(df$posratio)) + geom_histogram() +
  labs(title = "Positivity of comment attitudes", x="percent of positive spans minus percent of negative spans") +
  theme(text = element_text(size=txtsize))

## Ignoring neutral spans, positive pct - negative pct
# attempts to further answer whether comments favor one polarity of span
df = subset(comment.counts, select = c("comment", "pos", "neg", "posratio"))
df = df[df$pos > 0 | df$neg > 0,]   # filters out comments with no pos or neg spans
ggplot(mapping=aes(df$posratio)) + geom_density(fill = "purple", alpha = fill.alpha) +
  labs(title = "Positivity of comment attitudes", x="percent of positive spans minus percent of negative spans") +
  theme(text = element_text(size=txtsize))

## Percentages of attitude label
# this gives an idea of how prevalent the different labels are
df = subset(comment.counts, select = c("comment", "apppct", "judpct", "affpct"))
df = df[df$apppct > 0 | df$judpct > 0,]   # filters out comments with no app or jud spans
df = melt(df)
# as density plot
ggplot(data=df,mapping=aes(value, fill=variable)) +
  geom_density(alpha = fill.alpha) +
  labs(title = "Attitude label by comment", x = "Percentage") +
  scale_fill_manual(name="Label",
                    values = palette,
                    breaks=c("apppct", "judpct", "affpct"),
                    labels=c("Appreciation", "Judgment", "Affect")) +
  theme(text = element_text(size=txtsize))

# as histogram
ggplot(data=df,mapping=aes(value)) +
  geom_histogram(data = df[df$variable=="apppct",], color = line.color, aes(fill = variable), alpha = fill.alpha) +
  geom_histogram(data = df[df$variable=="judpct",], color = line.color, aes(fill = variable), alpha = fill.alpha) +
  geom_histogram(data = df[df$variable=="affpct",], color = line.color, aes(fill = variable), alpha = fill.alpha) +
  labs(title = "Polarity by comment") +
  scale_fill_discrete(name="Polarity",
                      breaks=c("apppct", "judpct", "affpct"),
                      labels=c("Appreciation", "Judgment", "Affect")) +
  theme(text = element_text(size=txtsize))

## Same thing but without affect:
# lets us see that judgment and appreciation have similar distributions
df = subset(comment.counts, select = c("comment", "apppct", "judpct"))
df = df[df$apppct > 0 | df$judpct > 0,]   # filters out comments with no app or jud spans
df = melt(df)
# as density plot
ggplot(data=df,mapping=aes(value, fill=variable))  +
  geom_density(alpha = fill.alpha) +
  labs(title = "Attitude label by comment, affect excluded", x = "Percentage") +
  scale_fill_manual(name="Label",
                    values = palette,
                    breaks=c("apppct", "judpct", "affpct"),
                    labels=c("Appreciation", "Judgment", "Affect")) +
  theme(text = element_text(size=txtsize))
# as histogram
ggplot(data=df,mapping=aes(value)) +
  geom_histogram(data = df[df$variable=="apppct",], color = line.color, aes(fill = variable), alpha = fill.alpha) +
  geom_histogram(data = df[df$variable=="judpct",], color = line.color, aes(fill = variable), alpha = fill.alpha) +
  labs(title = "Type of Attitude by comment") +
  scale_fill_manual(name="Label",
                    values = palette,
                    breaks=c("apppct", "judpct", "affpct"),
                    labels=c("Appreciation", "Judgment", "Affect")) +
  theme(text = element_text(size=txtsize))

## Ignoring affect, apprec pct - jud pct
# attempts to further answer whether comments favor one polarity of span
df = subset(comment.counts, select = c("comment", "app", "jud"))
df = df[df$app > 0 | df$jud > 0,]   # filters out comments with no app or jud spans
df$appratio = (df$app/(df$app + df$jud) - df$jud/(df$app + df$jud))
# density plot
ggplot(mapping=aes(df$appratio)) + geom_density(fill = "purple", alpha = fill.alpha) +
  labs(title = "Preference of comments for Appreciation over Judgment", x="percent of Appreciation spans minus percent of Judgment spans") +
  theme(text = element_text(size=txtsize))
# histogram with few bins
ggplot(data=df,mapping=aes(appratio)) +
  geom_histogram(color = line.color, fill="purple", alpha = fill.alpha, bins=9) +
  labs(title = "Preference of comments for Appreciation over Judgment", x="percent of Appreciation spans minus percent of Judgment spans") +
  theme(text = element_text(size=txtsize))

## Same idea, but looking only at comments with affect (so with affect included)
# shows that even in comments with affect, the percentage is low, and there's about even amounts of judgment and appreciation
df = subset(comment.counts, select = c("comment", "apppct", "judpct", "affpct"))
df = df[df$affpct > 0,]   # filters out comments with no aff spans
df = melt(df)
# as histogram
ggplot(data=df,mapping=aes(value)) +
  geom_histogram(data = df[df$variable=="apppct",], color = line.color, aes(fill = variable), alpha = fill.alpha) +
  geom_histogram(data = df[df$variable=="judpct",], color = line.color, aes(fill = variable), alpha = fill.alpha) +
  geom_histogram(data = df[df$variable=="affpct",], color = line.color, aes(fill = variable), alpha = fill.alpha) +
  labs(title = "Polarity by comment") +
  scale_fill_discrete(name="Polarity",
                      breaks=c("apppct", "judpct", "affpct"),
                      labels=c("Appreciation", "Judgment", "Affect")) +
  theme(text = element_text(size=txtsize))
# as density plot
ggplot(data=df,mapping=aes(value, fill=variable))  +
  geom_density(alpha = fill.alpha) +
  labs(title = "Attitude label by comment, only comments with affect", x = "Percentage") +
  scale_fill_manual(name="Label",
                    values = palette,
                    breaks=c("apppct", "judpct", "affpct"),
                    labels=c("Appreciation", "Judgment", "Affect")) +
  theme(text = element_text(size=txtsize))

#### Graduation ####
# A smaller df with only comments that have graduation
graduation.comment.counts = comment.counts[comment.counts$gra > 0,]

## Graduation per Attitude
df = graduation.comment.counts$gra.att
# density
ggplot(mapping=aes(df)) + geom_density(fill = "purple", alpha = fill.alpha) +
  labs(title = "Graduation spans per Attitude span", x = "Graduation spans per Attitude span") +
  theme(text = element_text(size=txtsize))
# hist
ggplot(mapping=aes(df)) + geom_histogram(bins=20) +
  labs(title = "Graduation spans per Attitude span", x = "Graduation spans per Attitude span") +
  theme(text = element_text(size=txtsize))

## Same, but looking only where gra/att < 1
df = subset(graduation.comment.counts, gra.att < 1, select = c('comment', 'gra.att'))
# density
ggplot(mapping=aes(df$gra.att)) + geom_density(fill = "purple", alpha = fill.alpha) +
  labs(title = "Graduation spans per Attitude span", x = "Graduation spans per Attitude span") +
  theme(text = element_text(size=txtsize))
# hist
ggplot(mapping=aes(df$gra.att)) + geom_histogram() +
  labs(title = "Graduation spans per Attitude span", x = "Graduation spans per Attitude span") +
  theme(text = element_text(size=txtsize))

## Percent distribution of force and focus
# Shows that there's only a slightly higher tendency to use only focus than mix it evenly with Force, and most use Force exclusively
df = graduation.comment.counts[graduation.comment.counts$forcepct > 0 | graduation.comment.counts$focuspct > 0,]   # filters out comments with no Force/Focus
difference = df$forcepct - df$focuspct
# as density plot
ggplot(mapping=aes(difference)) + geom_density(fill = "purple", alpha = fill.alpha) +
  labs(title = "Preference for Force in Graduation, by comment", x = "Percent of Force spans - percent of Focus spans") +
  theme(text = element_text(size=txtsize))
# as histogram
ggplot(mapping=aes(difference)) + geom_histogram() +
  labs(title = "Tendency towards Force in Graduation, by comment", x = "Percent of Force spans - percent of Focus spans")

## Percent distribution of up and down
# Shows that there's only a slightly higher tendency to use only up than mix it evenly with down, and most use up exclusively
df = graduation.comment.counts[graduation.comment.counts$uppct > 0 | graduation.comment.counts$downpct > 0,]   # filters out comments with no Force/Focus
difference = df$uppct - df$downpct
ggplot(mapping=aes(difference)) + geom_density(fill = "purple", alpha = fill.alpha) +
  labs(title = "Tendency towards upwards Graduation, by comment", x = "Percent of upward Graduation - percent of downward Graduation") +
  theme(text = element_text(size=txtsize))

##### Stacked spans #####

## general use df
stackvis = subset(stacks, select=c(1, 7:12, 16:23))

### How often do things switch around?

## in Attitude (only Att comments)
df = subset(stackvis, attlab != 'None' & attpol !='None' & contained.attlab != 'None' & contained.attpol != 'None',
            select = c('comment', 'att.samelab', 'att.samepol'))
df = melt(df, id.vars='comment')
ggplot(data=df, aes(value, fill = variable)) + geom_bar(position = 'dodge')
# more common for att to change than stay the same, reverse for pol

## in Graduation (only Gra comments)
df = subset(stackvis, gralab != 'None' & grapol !='None' & contained.gralab != 'None' & contained.grapol != 'None',
            select = c('comment', 'gra.samelab', 'gra.samepol'))
df = melt(df, id.vars='comment')
ggplot(data=df, aes(value, fill = variable)) + geom_bar(position = 'dodge')
# this graph basically isn't that interesting

### Where does the switching happen?

## attlab (None indicates graduation in contained span)
df = subset(stackvis, attlab != 'None' & attlab != '*' & contained.attlab != '*', select = c('comment', 'attlab', 'contained.attlab'))
ggplot(data=df, aes(contained.attlab, fill = contained.attlab, color = contained.attlab)) + facet_wrap(~attlab) +
  geom_bar(position='dodge') + labs(title = 'Type of Attitude in stacked spans, by container')

## attlab with only att
df = subset(stackvis, contained.attlab != 'None' & attlab != '*' & contained.attlab != '*', select = c('comment', 'attlab', 'contained.attlab'))
ggplot(data=df, aes(contained.attlab, fill = contained.attlab, color = contained.attlab)) + facet_wrap(~attlab) +
  geom_bar(position='dodge') + labs(title = 'Type of Attitude in stacked spans, by container')

## attlab by type of gra (no att containing att)
df = subset(stackvis, attlab != 'None' & contained.attlab == 'None' & attlab != '*' & contained.attlab != '*', select = c('comment', 'attlab', 'contained.gralab'))
ggplot(data=df, aes(contained.gralab, fill = contained.gralab, color = contained.gralab)) + facet_wrap(~attlab) +
  geom_bar(position='dodge') + labs(title = 'Type of Attitude in stacked spans, by container')
# not sure how to interpret difference in App and Jud

#
##### Negation #####

### NEG keyword

## distribution of attlab in spans with negation
df = subset(appraisal.annotations, NEG, select = c('comment', 'attlab'))
ggplot(data=df, aes(attlab, fill = attlab)) + geom_bar(position='dodge')
# mostly Judgment. None = graduation

## distribution of attpol in spans with negation
df = subset(appraisal.annotations, NEG & attpol != '*', select = c('comment', 'attpol'))
ggplot(data=df, aes(attpol, fill = attpol)) + geom_bar(position='dodge') +
  labs(title='Attitude polarity in spans with negators')

## the next two are not interesting

## distribution of gralab in spans with negation
df = subset(appraisal.annotations, NEG & gralab != 'None', select = c('comment', 'gralab'))
ggplot(data=df, aes(gralab, fill = gralab)) + geom_bar(position='dodge')

## distribution of grapol in spans with negation
df = subset(appraisal.annotations, NEG & grapol != 'None', select = c('comment', 'grapol'))
ggplot(data=df, aes(grapol, fill = grapol)) + geom_bar(position='dodge')

### FOCUS and Attitude

## distribution of attpol + attlab in spans with FOCUS (smallest span selected if ambiguous)
df = subset(focusdf, gralab == 'None' & attlab != '*' & attpol != '*')
p1 = ggplot(data=df, aes(attpol, fill = attlab)) + geom_bar(position='stack') +
  labs(title = 'Attitude in spans with FOCUS') + scale_fill_brewer(palette='Spectral')

## compare with general data
df = subset(appraisal.annotations, attlab != 'None' & attlab != '*' & attpol != '*')
p2 = ggplot(data=df, aes(attpol, fill = attlab)) + geom_bar(position='stack') +
  labs(title = 'Attitude in the corpus as a whole') + scale_fill_brewer(palette='Spectral')

## show both
grid.arrange(p1, p2, nrow = 1)
# so in the FOCUS one, there's less 'pos', more 'neu', and less affect

#
##### Constructiveness and toxicity #####
## constructiveness
# distribution of constructiveness
ggplot(data=comment.counts, aes(is_constructive, fill=is_constructive)) + geom_bar()

# pct positive vs constructiveness
df = subset(comment.counts, att != 0, select = c('comment', 'is_constructive', 'posratio'))
ggplot(data=df, aes(posratio)) + geom_density(fill='purple') + facet_wrap(~is_constructive)
# constructive comments trend more positive, unconstructive more negative

# attitude label and constructiveness (ignoring affect)
df = subset(comment.counts, att != 0, select = c('comment', 'is_constructive', 'apppct', 'judpct'))
df = melt(df, id.vars=c('comment', 'is_constructive'))
ggplot(data=df, aes(value, fill=variable)) + geom_density(alpha=fill.alpha) + facet_wrap(~is_constructive)
# doesn't look that interesting, maybe more appreciation in constructive while unconstructive is more even

# affect and constructiveness (for comments with affect)
df = subset(comment.counts, affpct != 0, select = c('comment', 'is_constructive', 'affpct'))
ggplot(data=df, aes(affpct)) + geom_histogram(fill='purple') + facet_wrap(~is_constructive)
# clearly more have some amount of affect, though still very little
# there are 159 comments with affect, 125 of which are constructive (34 are unconstructive)

# gralab and constructiveness
df = subset(comment.counts, gra != 0, select = c('comment', 'is_constructive', 'forcepct'))
ggplot(data=df, aes(forcepct)) + geom_histogram(fill='purple') + facet_wrap(~is_constructive)
# more use of force relative to focus in constructive comments

# graduation and constructiveness
ggplot(data=comment.counts, aes(gra)) + geom_histogram(fill='purple') + facet_wrap(~is_constructive)
# more graduation in constructive comments
# 398 comments with Graduation, 289 of which are constructive (109 unconstructive)

## toxicity
# ultimately, the only interesting thing here is pct jud vs pct app
# overall distribution of toxicity
ggplot(data=contox.annotations, aes(toxicity_level, fill = toxicity_level)) + geom_bar()
# 1: 829
# 2: 172
# 3: 35
# 4: 7

# pct positive vs toxicity
df = subset(comment.counts, att != 0, select = c('comment', 'toxicity_level', 'posratio'))
ggplot(data=df, aes(posratio)) + geom_density(fill='purple') + facet_wrap(~toxicity_level)
# doesn't look very different

# attitude label and toxicity (ignoring affect)
df = subset(comment.counts, att != 0, select = c('comment', 'toxicity_level', 'apppct', 'judpct'))
df = melt(df, id.vars=c('comment', 'toxicity_level'))
ggplot(data=df, aes(value, fill=variable)) + geom_density(alpha=fill.alpha) + facet_wrap(~toxicity_level)
# especially at higher levls, much more judgment (though N is small)

# affect and toxicity (for comments with affect)
df = subset(comment.counts, affpct != 0, select = c('comment', 'toxicity_level', 'affpct'))
ggplot(data=df, aes(affpct)) + geom_density(fill='purple') + facet_wrap(~toxicity_level)
# doesn't seem to make a difference

# gralab and toxicity
df = subset(comment.counts, gra != 0, select = c('comment', 'toxicity_level', 'forcepct'))
ggplot(data=df, aes(forcepct)) + geom_density(fill='purple') + facet_wrap(~toxicity_level)
# about the same

# graduation and toxicity
ggplot(data=comment.counts, aes(gra)) + geom_density(fill='purple') + facet_wrap(~toxicity_level)
# looks the same

#
##### By article #####
# set color scale
scale = c('#a6cee3','#1f78b4','#b2df8a','#33a02c','#fb9a99','#e31a1c','#fdbf6f','#ff7f00','#cab2d6','#6a3d9a','#ffff99','#b15928','#000000')

## attlab
df = subset(article.counts, select = c('article', 'apppct', 'judpct', 'affpct'))
df = df[order(df$apppct),]
df$article = factor(df$article, levels = df$article)
df = melt(df, id.vars='article')
ggplot(data=df, aes(x=variable, y=value, fill = article)) +
  geom_bar(position='dodge', stat='identity') + scale_fill_manual(values = scale)

## attlab but only app and jud
df = subset(article.counts, select = c('article', 'app', 'jud'))
df$app.pct = df$app/(df$app+df$jud)
df = df[order(df$app.pct),]
df$article = factor(df$article, levels = df$article)
ggplot(data=df, aes(x=article, y=app.pct, fill = article)) +
  geom_bar(position='dodge', stat='identity') + scale_fill_manual(values = scale)

## attpol
df = subset(article.counts, select = c('article', 'pospct', 'negpct', 'neupct'))
df = df[order(df$negpct),]
df$article = factor(df$article, levels = df$article)
df = melt(df, id.vars='article')
ggplot(data=df, aes(x=variable, y=value, fill = article)) +
  geom_bar(position='dodge', stat='identity') + scale_fill_manual(values = scale)

## attpol but only pos and neg
df = subset(article.counts, select = c('article', 'pos', 'neg'))
df$pos.pct = df$pos/(df$pos+df$neg)
df = df[order(df$pos.pct),]
df$article = factor(df$article, levels = df$article)
ggplot(data=df, aes(x=article, y=pos.pct, fill = article)) +
  geom_bar(position='dodge', stat='identity') + scale_fill_manual(values = scale)

#
##### Correlations #####
# Correlation between tendency for negativity and tendency for appreciation
df = subset(comment.counts, select = c("comment", "pospct", "negpct", "judpct", "apppct"))
df$negtend = df$pospct - df$negpct
df$apptend = df$apppct - df$judpct
df <- subset(df, !is.na(negtend) & !is.na(apptend))
cor(df$negtend, df$apptend)

# Correlation between tendency for force and tendency for up
df = data.frame(force = graduation.comment.counts$forcepct - graduation.comment.counts$focuspct,
                up = graduation.comment.counts$uppct - graduation.comment.counts$downpct)
cor(df$force, df$up)

##### Exporting #####
export.folder = 'C:/Users/lcava/Documents/_My Actual Folders/Research/Discourse Processing/socc_comments/analysis/'
write.csv(comment.counts, paste(export.folder,'comment_counts.csv'))
write.csv(graduation.ambig, paste(export.folder, 'ambiguous_graduation.csv'))
write.csv(attcounts, paste(export.folder, 'attitude_counts.csv'))
write.csv(gracounts, paste(export.folder, 'graduation_counts.csv'))
write.csv(negcounts, paste(export.folder, 'negation_counts.csv'))
