# code is still in development

# Read file
# library(readr)
# annotations <- read_csv("~/_folders I made myself/Research/Discourse Processing/socc_comments/corrected_combined_appraisal_comments.csv")

# remove the extra column
annotations <- annotations[,2:11]

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

# Get simple counts
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

# Check for any blank annotations
mismatches = subset(annotations,
                    annotations$attlab == "*" | annotations$attpol == "*" | annotations$gralab == "*" | annotations$grapol == "*")

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
graduation.all = stacks[0,]
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
         & !(stacks$span[i] %in% punctuation)        # and this span is not just punctuation
         & !(stacks$span[i+n] %in% punctuation)      # and neither is the 'next' one
         & (stacks$gralab[i] != "None" | stacks$grapol[i] != "None")  # and there's a graduation annotation in this row
         & (stacks$attlab[i+n] != "None" | stacks$attpol[i+n] != "None") # and an attitude annotation in the 'next' one
         )
      {
        graduation.all = rbind(stacks[i,], graduation.all)  # then add this row to the df (graduation annotation)
        graduation.all = rbind(stacks[i+n,], graduation.all) # and the 'next' one (attitude annotation)
      }
    }
    # look behind for the same thing
    if (match(i-n, 1:length(stacks$span), nomatch=FALSE))
    {
      if(stacks$charstart[i] <= stacks$charend[i-n]  # if the charstart for this one is greater than charend for the 'previous' one
         & stacks$comment[i-n] == stacks$comment[i]  # and the two are in the same comment
         & !(stacks$span[i] %in% punctuation)        # and this span is not just punctuation
         & !(stacks$span[i-n] %in% punctuation)      # and neither is the 'next' one
         & (stacks$gralab[i] != "None" | stacks$grapol[i] != "None")  # and there's a graduation annotation in this row
         & (stacks$attlab[i-n] != "None" | stacks$attpol[i-n] != "None") # and an attitude annotation in the 'previous' one
      )
      {
        graduation.all = rbind(stacks[i,], graduation.all)  # then add this row to the df (graduation annotation)
        graduation.all = rbind(stacks[i-n,], graduation.all) # and the 'previous' one (attitude annotation)
      }
    }
  }
}

graduation.all = unique(graduation.all)
graduation.all = graduation.all[order(graduation.all[,1], graduation.all[,4]),]
