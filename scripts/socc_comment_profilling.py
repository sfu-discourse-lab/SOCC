import pandas as pd
import ast
import datetime
import numpy as np

"""
Note: This script file is specific designed for SOCC_DATA/raw/gnm_comment_threads.csv,
which can be find in "https://github.com/sfu-discourse-lab/SOCC"
"""

def posted_comments(df):
	""" count the posted comments of each user
	Args:
		df: pandas dataframe (for gnm_comment_threads.csv only)

	Returns:
		a dataframe with two columns ['comment_author', 'count']
	"""
	return df[['comment_author','comment_id']].drop_duplicates().\
	groupby(['comment_author']).agg(['count'])

def thread_participated(df):
	""" count the number of threads that each user participated in
	Args:
		df: pandas dataframe (for gnm_comment_threads.csv only)
	
	Return:
		a dataframe with two columns ['comment_author', 'count_thread_participated']
	"""
	df['articleID_threadID'] = pd.Series(df.comment_counter.\
		apply(lambda x: "_".join(x.split('_')[1:3])))
	return df[['comment_author', 'articleID_threadID']].\
	drop_duplicates().groupby(['comment_author']).count()

def threads_initiated(df):
	""" count the number of threads that each user initiated
	Args:
		df: pandas dataframe (for gnm_comment_threads.csv only)
	
	Return:
		a dataframe with two columns ['comment_author', 'count_thread_initiated']
	"""
	df['is_initiated_threads'] = df['comment_counter'].apply(lambda x:len(x.split('_'))==3)
	return df[['comment_author', 'is_initiated_threads']].groupby(['comment_author']).sum()

def pos_votes_count(df):
	""" count the number of positive votes that each user gained
	Args:
		df: pandas dataframe (for gnm_comment_threads.csv only)
	
	Return:
		a dataframe with two columns ['comment_author', 'pos_votes_count']
	"""
	return df[['comment_author', 'posVotes']].groupby('comment_author').sum()

def neg_votes_count(df):
	""" count the number of positive votes that each user gained
	Args:
		df: pandas dataframe (for gnm_comment_threads.csv only)
	
	Return:
		a dataframe with two columns ['comment_author', 'neg_votes_count']
	"""
	return df[['comment_author', 'negVotes']].groupby('comment_author').sum()

def _find_all_reactions_types(df):
	""" This is the helper function
	from all the reactions, find all kind of reactions types
	
	Args:
		df_reactions: reaction_list column in 
						pandas dataframe (for gnm_comment_threads.csv only)
	
	Return:
		a dataframe with two columns ['comment_author', 'reaction_types_count']
	"""
	reaction_is_null = df.reactions.isnull()
	reactions = []
	for i in range(len(df.reactions)):
		if not reaction_is_null[i] and len(df.reactions[i]) > 2:
			reaction_list = ast.literal_eval(df.reactions[i])['reaction_list']
			for rlist in reaction_list:
				reactions.append(rlist['reaction'])	
	return list(set(reactions))


def _find_all_reactions_count(reaction_list):
	""" This is the helper function
	for each reaction list, find the reaction count
	
	Args:
		df: pandas dataframe (for gnm_comment_threads.csv only)
	
	Return:
		a dataframe with two columns ['comment_author', 'reaction_types_count']
	"""
	reactions_count = {}
	for rlist in reaction_list:
		if rlist['reaction'] in reactions_count:
			reactions_count[rlist['reaction']] += 1
		else:
			reactions_count[rlist['reaction']] = 1
	return reactions_count

def reactions_count(df):
	""" count the reactions that each user gained among the reaction lists
	
	Args:
		df: pandas dataframe (for gnm_comment_threads.csv only)
	
	Return:
		a dataframe with two columns ['comment_author', 'reaction_types_count']
	"""
	result = pd.DataFrame(df.comment_author.drop_duplicates().reset_index(drop=True))
	reaction_types = _find_all_reactions_types(df)
	#print(reaction_types)
	for i in reaction_types:
		df[i] = 0
	df['reaction_counts'] = 0
	reaction_is_null = df.reactions.isnull()
	for i in range(len(df.reactions)):
		if not reaction_is_null[i] and df.reactions[i] != '{}':
			reactions = ast.literal_eval(df.iloc[i]['reactions'])
			df.loc[i, 'reaction_counts'] = int(reactions['reaction_counts'][-1].split()[-1])
			reaction_list = _find_all_reactions_count(reactions['reaction_list'])
			for k in reaction_list.keys():
				#print(k) TEST PURPOSE
				df.loc[i, k] = int(reaction_list[k])

	for t in reaction_types:
		raction_type_sum = df[['comment_author', t]].groupby('comment_author').sum()
		result = result.join(raction_type_sum, on = 'comment_author')
	raction_count_sum = df[['comment_author', 'reaction_counts']].groupby('comment_author').sum()
	result = result.join(raction_count_sum, on = 'comment_author')
	return result

def yearly_count(df):
	""" for each user, count the number of posted comment every year
	
	Args:
		df: pandas dataframe (for gnm_comment_threads.csv only)
	
	Return:
		a dataframe with few columns ['comment_author', 
		'comments_posted_in_years', 'yearly_frequency']
	"""
	timestamp_df = df[['comment_author','timestamp']].dropna()
	timestamp_df['year'] = timestamp_df['timestamp'].dropna().\
	apply(lambda x: datetime.datetime.fromtimestamp(int(x)/1000).year)
	#timestamp_df['thread_year'] = timestamp_df['threadTimestamp'].dropna().apply(lambda x: datetime.datetime.fromtimestamp(int(x)/1000).year)
	counts = timestamp_df[['comment_author', 'year']].dropna()\
	.groupby(['comment_author', 'year']).size()
	counts = pd.DataFrame(counts, columns = ['count'])
	yearly_counts = pd.pivot_table(counts, values='count', \
		index=['comment_author'], columns=['year'], aggfunc=np.sum)
	yearly_counts.columns = ['comments_posted_in_' + str(n) for n in yearly_counts.columns]
	yearly_counts['yearly_frequency'] = yearly_counts.sum(axis=1)/len(yearly_counts.columns)
	return yearly_counts

def main(path):
    """
    Main function.

    Args:
        path: (str): write your description
    """
	df = pd.read_csv('Data/raw/gnm_comment_threads.csv').drop_duplicates()
	result = pd.DataFrame(df.comment_author.drop_duplicates().reset_index(drop=True))
	result = result.join(posted_comments(df), on = 'comment_author')
	result = result.join(thread_participated(df), on = 'comment_author')
	result = result.join(threads_initiated(df), on = 'comment_author')
	result = result.join(pos_votes_count(df), on = 'comment_author')
	result = result.join(neg_votes_count(df), on = 'comment_author')
	result = result.join(reactions_count(df).set_index('comment_author'), on = 'comment_author')
	result = result.join(yearly_count(df), on = 'comment_author')
	result.columns = ['comment_author','posted_comments_count', \
	'participated_threads_count', 'initiated_thread_count', \
	'posVotes_num', 'negVotes_num'] + list(result.columns[6:])
	result.to_csv('commenter_profiles.csv', index=False)


if __name__ == "__main__":
	import argparse
	parser = argparse.ArgumentParser(description='count the comment profilling')
	parser.add_argument('gnm_comment_threads_file_path', type=str,
                    help='the path to ICE folder')
	args = parser.parse_args()
	main(args.gnm_comment_threads_file_path)
	


