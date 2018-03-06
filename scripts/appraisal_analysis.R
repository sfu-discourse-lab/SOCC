# code is still in development

#### Getting the annotation dataframe ####
# Read file
# library(readr)
# annotations <- read_csv("~/_folders I made myself/Research/Discourse Processing/socc_comments/corrected_combined_appraisal_comments.csv")

# remove the extra column
annotations <- annotations[,2:11]

# Check for any blank annotations
mismatches = subset(annotations,
                    annotations$attlab == "*" | annotations$attpol == "*" | annotations$gralab == "*" | annotations$grapol == "*")

#### Getting basic counts ####
# So that we can count them later, get subsets of "annotations" by label
# Attitude labels
approws = annotations[annotations$attlab=="Appreciation",]
judrows = annotations[annotations$attlab=="Judgment",]
affrows = annotations[annotations$attlab=="Affect",]
# Attitude polarities
posrows = annotations[annotations$attpol=="pos",]
negrows = annotations[annotations$attpol=="neg",]
neurows = annotations[annotations$attpol=="neu",]
# Graduation labels
forcerows = annotations[annotations$gralab=="Force",]
focusrows = annotations[annotations$gralab=="Focus",]
# Graduation polarities
upgradrows = annotations[annotations$grapol=="up",]$grapol
downgradrows = annotations[annotations$grapol=="down",]

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

#### Finding stacked spans and graduation ####

# find stacked spans
stacks = annotations[0,]
look = 10     # how far ahead to look
punctuation = c(".", ",", "!", "?")
for(i in 1:length(annotations$span))
{
  for(n in 1:look)
  {
    if (match(i+n, 1:length(annotations$span), nomatch=FALSE))
    {
      if(annotations$charstart[i+n] <= annotations$charend[i]  # if the charstart for the 'next' is less than charstart for this one
         & annotations$comment[i+n] == annotations$comment[i]  # and the two are in the same comment
         & !(annotations$span[i] %in% punctuation)              # and this span is not just punctuation
         & !(annotations$span[i+n] %in% punctuation))           # and neither is the 'next' one
      {
        stacks = rbind(annotations[i,], stacks)  # then add this row to stacks
        stacks = rbind(annotations[i+n,], stacks) # and the 'next' one
      }
    }
  }
}
stacks = unique(stacks)
stacks = stacks[order(stacks[,1], stacks[,4]),]

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
graduation = graduation[order(graduation[,1], graduation[,4]),]
graduation.oldnames = graduation # this df's rownames will be indices for the annotations df
rownames(graduation) = 1:length(graduation$span)

# add column for scope of graduation
look = 10
# find all rows with graduation (should be the same as focusrows + forcerows)
candidates = graduation[graduation$grapol != "None" | graduation$gralab != "None",]
# make a key so we know the original index of each row
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
