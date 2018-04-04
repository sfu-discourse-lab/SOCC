# code is still in development

library(readr)
library(tokenizers)
library(ggplot2)
library(reshape2)
library(viridis)

###### Getting the annotation dataframes ######
# Read file
appraisal.annotations <- read_csv("~/_My Actual Folders/Research/Discourse Processing/socc_comments/corrected_combined_appraisal_comments.csv")
negation.annotations <- read_csv("~/_My Actual Folders/Research/Discourse Processing/socc_comments/combined_negation_comments.csv")

# remove the extra column
appraisal.annotations <- appraisal.annotations[,2:length(appraisal.annotations)]
negation.annotations <- negation.annotations[,2:length(negation.annotations)]

# Check for any blank appraisal.annotations
mismatches = subset(appraisal.annotations,
                    appraisal.annotations$attlab == "*" | appraisal.annotations$attpol == "*" | appraisal.annotations$gralab == "*" | appraisal.annotations$grapol == "*")

###### Getting basic counts ######
# So that we can count them later, get subsets of "appraisal.annotations" by label
# Attitude labels
approws = appraisal.annotations[appraisal.annotations$attlab=="Appreciation",]
judrows = appraisal.annotations[appraisal.annotations$attlab=="Judgment",]
affrows = appraisal.annotations[appraisal.annotations$attlab=="Affect",]
# Attitude polarities
posrows = appraisal.annotations[appraisal.annotations$attpol=="pos",]
negrows = appraisal.annotations[appraisal.annotations$attpol=="neg",]
neurows = appraisal.annotations[appraisal.annotations$attpol=="neu",]
# Graduation labels
forcerows = appraisal.annotations[appraisal.annotations$gralab=="Force",]
focusrows = appraisal.annotations[appraisal.annotations$gralab=="Focus",]
# Graduation polarities
upgradrows = appraisal.annotations[appraisal.annotations$grapol=="up",]
downgradrows = appraisal.annotations[appraisal.annotations$grapol=="down",]

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
attcounts = data.frame(row.names = c("neg", "pos", "neu"))
gracounts = data.frame(row.names = c("up", "down"))

# put in counts for Attitude
attcounts$appreciation = c(
  length(approws[approws$attpol=="neg",]$attlab),  # count of negative appreciation
  length(approws[approws$attpol=="pos",]$attlab),  # count of positive appreciation
  length(approws[approws$attpol=="neu",]$attlab)   # count of neutral appreciation
)

attcounts$judgment = c(
  length(judrows[judrows$attpol=="neg",]$attlab),
  length(judrows[judrows$attpol=="pos",]$attlab),
  length(judrows[judrows$attpol=="neu",]$attlab)
)

attcounts$affect = c(
  length(affrows[affrows$attpol=="neg",]$attlab),
  length(affrows[affrows$attpol=="pos",]$attlab),
  length(affrows[affrows$attpol=="neu",]$attlab)
)

# put in counts for Graduation
gracounts$force = c(
  length(forcerows[forcerows$grapol=="up",]$gralab),
  length(forcerows[forcerows$grapol=="down",]$gralab)
)

gracounts$focus = c(
  length(focusrows[focusrows$grapol=="up",]$gralab),
  length(focusrows[focusrows$grapol=="down",]$gralab)
)

###### Finding stacked spans and graduation ######

# find stacked spans
stacks = appraisal.annotations[0,]
look = 10     # how far ahead to look
punctuation = c(".", ",", "!", "?")
for(i in 1:length(appraisal.annotations$span))
{
  for(n in 1:look)
  {
    if (match(i+n, 1:length(appraisal.annotations$span), nomatch=FALSE))
    {
      if(appraisal.annotations$charstart[i+n] <= appraisal.annotations$charend[i]  # if the charstart for the 'next' is less than charstart for this one
         & appraisal.annotations$comment[i+n] == appraisal.annotations$comment[i]  # and the two are in the same comment
         & !(appraisal.annotations$span[i] %in% punctuation)             # and this span is not just punctuation
         & !(appraisal.annotations$span[i+n] %in% punctuation))          # and neither is the 'next' one
      {
        stacks = rbind(appraisal.annotations[i,], stacks)  # then add this row to stacks
        stacks = rbind(appraisal.annotations[i+n,], stacks) # and the 'next' one
      }
    }
  }
}
stacks = unique(stacks)
stacks = stacks[order(stacks$comment, stacks$charstart),]

# get a data.frame of all spans with graduation and the attitude spans that contain them
graduation = stacks[0,]
look = 10     # how far ahead to look
for(i in 1:length(stacks$span))
{
  for(n in 1:look)
  {
    # look ahead, if we see a grad annotation for this comment and an attitude one for an overlapping future one then we can include them
    if (match(i+n, 1:length(stacks$span), nomatch=FALSE))
    {
      if(stacks$charstart[i+n] <= stacks$charend[i]  # if the charstart for the 'next' is less than charend for this one
         & stacks$comment[i+n] == stacks$comment[i]  # and the two are in the same comment
         & (stacks$gralab[i] != "None" | stacks$grapol[i] != "None")  # and there's a graduation annotation in this row
         & (stacks$attlab[i+n] != "None" | stacks$attpol[i+n] != "None") # and an attitude annotation in the 'next' one
         )
      {
        graduation = rbind(stacks[i,], graduation)  # then add this row to the df (graduation annotation)
        graduation = rbind(stacks[i+n,], graduation) # and the 'next' one (attitude annotation)
      }
    }
    # look behind for the same thing
    if (match(i-n, 1:length(stacks$span), nomatch=FALSE))
    {
      if(stacks$charstart[i] <= stacks$charend[i-n]  # if the charstart for this one is greater than charend for the 'previous' one
         & stacks$comment[i-n] == stacks$comment[i]  # and the two are in the same comment
         & (stacks$gralab[i] != "None" | stacks$grapol[i] != "None")  # and there's a graduation annotation in this row
         & (stacks$attlab[i-n] != "None" | stacks$attpol[i-n] != "None") # and an attitude annotation in the 'previous' one
      )
      {
        graduation = rbind(stacks[i,], graduation)  # then add this row to the df (graduation annotation)
        graduation = rbind(stacks[i-n,], graduation) # and the 'previous' one (attitude annotation)
      }
    }
  }
}

graduation = unique(graduation)
graduation = graduation[order(graduation$comment, graduation$charstart),]
graduation.oldnames = graduation # this df's rownames will be indices for the appraisal.annotations df
rownames(graduation) = 1:length(graduation$span)

# add column for scope of graduation
look = 10
# find all rows with graduation (should be the same as focusrows + forcerows)
candidates = graduation[graduation$grapol != "None" | graduation$gralab != "None",]
# make a key so we know the original index of each row
index.key = c()
for (i in 1:length(candidates$span))
{
  index.key[i] = strtoi(rownames(candidates[i,]))
}
# e.g. index.key[1] returns "15," meaning 15 is the original index of candidates[1,]
graduation$scope_of = 0
for(i in 1:length(candidates$span))
{
  graduation$scope_of[index.key[i]] = 0
  for(n in 1:look)
  {
    if(match(index.key[i]+n, 1:length(graduation$span), nomatch=FALSE))
    {
      if(graduation$charstart[index.key[i]+n] <= graduation$charend[index.key[i]] 
        & graduation$comment[index.key[i]+n] == graduation$comment[index.key[i]]) # same thing as before checking for overlap
      {
        graduation$scope_of[index.key[i]+n] = index.key[i]
      }
    }
    if(match(index.key[i]-n, 1:length(graduation$span), nomatch=FALSE))
    {
      if (graduation$charstart[index.key[i]] <= graduation$charend[index.key[i]-n] # but looking backwards too
          & graduation$comment[index.key[i]-n] == graduation$comment[index.key[i]])
      {
        graduation$scope_of[index.key[i]-n] = index.key[i]
      }
    }
  }
}

graduation$belongs_to = 0
for(i in 1:length(candidates$span))
{
  graduation$belongs_to[index.key[i]] = 0
  for(n in 1:look)
  {
    if(match(index.key[i]-n, 1:length(graduation$span), nomatch=FALSE))
    {
      if (graduation$charstart[index.key[i]] <= graduation$charend[index.key[i]-n] # looking backwards only
          & graduation$comment[index.key[i]-n] == graduation$comment[index.key[i]])
      {
        graduation$belongs_to[index.key[i]] = index.key[i]-n
      }
    }
  }
}

# find graduation spans with ambiguous scopes
graduation.ambig = graduation[0,]
look = 5
for(i in 1:length(graduation$span))
{
  for(n in 1:look)
  {
    if (match(i+n, 1:length(graduation$span), nomatch=FALSE))
    {
      if(graduation$scope_of[i] != 0 # look for matching scopes, signaling ambiguity
         & graduation$scope_of[i] == graduation$scope_of[i+n])
      {
        # add this row to graduation.ambig
        graduation.ambig = rbind(graduation[i,], graduation.ambig)
        # and the next one
        graduation.ambig = rbind(graduation[i+n,], graduation.ambig)
        # and the one of which this is the scope
        graduation.ambig = rbind(graduation[graduation$scope_of[i],], graduation.ambig)
      }
    }
  }
}

graduation.ambig = unique(graduation.ambig)
# order the rows properly
neworder = c()
for (i in 1:length(rownames(graduation.ambig))) neworder[i] = strtoi(rownames(graduation.ambig)[i])
graduation.ambig = graduation.ambig[order(neworder),]

# this doesn't include cases where there's multiple graduation in one attitude, e.g. graduation[53:57,]

###### Getting counts by comment ######

# make a dataframe with one column, each of which is a unique comment id
comment.counts = data.frame(unique(appraisal.annotations$comment))
colnames(comment.counts) = 'comment'

#### using the comment IDs, fill in comment length and count
### start by making empty columns
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

### then fill them in
## starting with basic counts
for (i in 1:length(comment.counts$comment)){
  # subset the dataframe
  df = appraisal.annotations[appraisal.annotations$comment == comment.counts$comment[i],]
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
}

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

###### Adding in negation ######
# check that all comment names match
appraisal.comments = unique(appraisal.annotations$comment)
negation.comments = unique(negation.annotations$comment)
comment.matching = data.frame(comment = c(appraisal.comments, negation.comments),
                              appraisal = NA,
                              negation = NA)
comment.matching$appraisal = comment.matching$comment %in% appraisal.comments
comment.matching$negation = comment.matching$comment %in% negation.comments
comment.matching$both = comment.matching$appraisal && comment.matching$negation

mask.app = appraisal.comments %in% negation.comments
mask.neg = negation.comments %in% appraisal.comments
# comments in both appraisal and negation
# appraisal.comments[mask.app]
# comments in only appraisal
# appraisal.comments[!mask.app]
# comments in only negation
# negation.comments[!mask.neg]

###### Visualization #####
# often need to reshape the comment counts so that they work with ggplot; melt() does this
# see http://seananderson.ca/2013/10/19/reshape/ for more info on that
## aesthetic variable setting:
fill.alpha = .5
line.color = "black" # used for histograms
##### By comment #####
#### General plots per word ####
df = subset(comment.counts, select = c("comment"))
df$attrate = comment.counts$att/comment.counts$wordlength
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
  labs(title = "Polarity by comment", x = "Percentage") +
  scale_fill_discrete(name="Polarity",
                      breaks=c("pospct", "negpct", "neupct"),
                      labels=c("Positive", "Negative", "Neutral"))
# as density plot
ggplot(data=df,mapping=aes(value, fill = variable)) +
  geom_density(alpha = fill.alpha, bw =.025) +
  labs(title = "Polarity by comment", x = "Percentage") +
  scale_fill_discrete(name="Polarity",
                      breaks=c("pospct", "negpct", "neupct"),
                      labels=c("Positive", "Negative", "Neutral"))

## Same plot, but looking only at comments with neu
df = subset(comment.counts, select = c("comment", "pospct", "negpct", "neupct"))
df = df[df$neupct > 0,]   # filters out comments with no neu spans
df = melt(df)
# as histogram
ggplot(data=df,mapping=aes(value)) +
  geom_histogram(data = df[df$variable=="pospct",], color = line.color, aes(fill = variable), alpha = fill.alpha) +
  geom_histogram(data = df[df$variable=="negpct",], color = line.color, aes(fill = variable), alpha = fill.alpha) +
  geom_histogram(data = df[df$variable=="neupct",], color = line.color, aes(fill = variable), alpha = fill.alpha) +
  labs(title = "Polarity by comment", x = "Percentage") +
  scale_fill_discrete(name = "Polarity",
                      breaks=c("pospct", "negpct", "neupct"),
                      labels=c("Positive", "Negative", "Neutral"))
# as density plot
ggplot(data=df,mapping=aes(value, fill = variable)) +
  geom_density(alpha = fill.alpha) +
  labs(title = "Polarity by comment", x = "Percentage") +
  scale_fill_discrete(name="Polarity",
                      breaks=c("pospct", "negpct", "neupct"),
                      labels=c("Positive", "Negative", "Neutral"))

## Ignoring neutral spans, positive pct - negative pct
# attempts to further answer whether comments favor one polarity of span
df = subset(comment.counts, select = c("comment", "pos", "neg"))
df = df[df$pos > 0 | df$neg > 0,]   # filters out comments with no pos or neg spans
df$posratio = (df$pos/(df$pos + df$neg) - df$neg/(df$pos + df$neg))
ggplot(mapping=aes(df$posratio)) + geom_density(fill = "purple", alpha = fill.alpha) +
  labs(title = "Positivity of comment attitudes", x="percent of positive spans minus percent of negative spans")

## Percentages of attitude label
# this gives an idea of how prevalent the different labels are
df = subset(comment.counts, select = c("comment", "apppct", "judpct", "affpct"))
df = df[df$apppct > 0 | df$judpct > 0,]   # filters out comments with no app or jud spans
df = melt(df)
# as density plot
ggplot(data=df,mapping=aes(value, fill=variable)) + geom_density(alpha = fill.alpha)
# as histogram
ggplot(data=df,mapping=aes(value)) +
  geom_histogram(data = df[df$variable=="apppct",], color = line.color, aes(fill = variable), alpha = fill.alpha) +
  geom_histogram(data = df[df$variable=="judpct",], color = line.color, aes(fill = variable), alpha = fill.alpha) +
  geom_histogram(data = df[df$variable=="affpct",], color = line.color, aes(fill = variable), alpha = fill.alpha) +
  labs(title = "Polarity by comment") +
  scale_fill_discrete(name="Polarity",
                      breaks=c("apppct", "judpct", "affpct"),
                      labels=c("Appreciation", "Judgment", "Affect"))

## Same thing but without affect:
# lets us see that judgment and appreciation have similar distributions
df = subset(comment.counts, select = c("comment", "apppct", "judpct"))
df = df[df$apppct > 0 | df$judpct > 0,]   # filters out comments with no app or jud spans
df = melt(df)
# as histogram
ggplot(data=df,mapping=aes(value)) +
  geom_histogram(data = df[df$variable=="apppct",], color = line.color, aes(fill = variable), alpha = fill.alpha) +
  geom_histogram(data = df[df$variable=="judpct",], color = line.color, aes(fill = variable), alpha = fill.alpha) +
  labs(title = "Type of Attitude by comment") +
  scale_fill_discrete(name="Attitude type",
                      breaks=c("apppct", "judpct", "affpct"),
                      labels=c("Appreciation", "Judgment", "Affect"))
# as density plot
ggplot(data=df,mapping=aes(value, fill=variable)) + geom_density(alpha = fill.alpha)

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
                      labels=c("Appreciation", "Judgment", "Affect"))
# as density plot
ggplot(data=df,mapping=aes(value, fill=variable)) + geom_density(alpha = fill.alpha)

#### Graduation ####
# A smaller df with only comments that have graduation
graduation.comment.counts = comment.counts[comment.counts$gra > 0,]

## Percent distribution of force and focus
# Shows that there's only a slightly higher tendency to use only focus than mix it evenly with Force, and most use Force exclusively
df = graduation.comment.counts[graduation.comment.counts$forcepct > 0 | graduation.comment.counts$focuspct > 0,]   # filters out comments with no Force/Focus
difference = df$forcepct - df$focuspct
# as density plot
ggplot(mapping=aes(difference)) + geom_density(fill = "purple", alpha = fill.alpha) +
  labs(title = "Tendency towards Force in Graduation, by comment", x = "Percent of Force spans - percent of Focus spans")
# as histogram
ggplot(mapping=aes(difference)) + geom_histogram() +
  labs(title = "Tendency towards Force in Graduation, by comment", x = "Percent of Force spans - percent of Focus spans")

## Percent distribution of up and down
# Shows that there's only a slightly higher tendency to use only up than mix it evenly with down, and most use up exclusively
df = graduation.comment.counts[graduation.comment.counts$uppct > 0 | graduation.comment.counts$downpct > 0,]   # filters out comments with no Force/Focus
difference = df$uppct - df$downpct
ggplot(mapping=aes(difference)) + geom_density(fill = "purple", alpha = fill.alpha) +
  labs(title = "Tendency towards upwards Graduation, by comment", x = "Percent of upward Graduation - percent of downward Graduation")

##### Correlations #####
# Correlation between tendency for negativity and tendency for appreciation
df = subset(comment.counts, select = c("comment", "pospct", "negpct", "judpct", "apppct"))
df$negtend = df$pospct - df$negpct
df$apptend = df$apppct - df$judpct
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