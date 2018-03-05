# code is still in development

# Read file
# annotations <- read_csv("~/_folders I made myself/Research/Discourse Processing/socc_comments/combined_appraisal_comments.csv")

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