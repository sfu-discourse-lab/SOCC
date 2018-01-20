# SOCC
SFU Opinion and Comments Corpus

The SFU Opinion and Comments Corpus (SOCC) is a corpus for the analysis of online news comments. Our corpus contains comments and the articles from which the comments originated. The articles are all opinion articles, not hard news articles. The corpus is larger than any other currently available comments corpora, and has been collected with attention to preserving reply structures and other metadata. In addition to the raw corpus, we also present annotations for four different phenomena: constructiveness, toxicity, negation and its scope, and appraisal. 

For more information about this work, please see our papers. 

- Kolhatkar. V. and M. Taboada (2017) [Using New York Times Picks to identify constructive comments](www.sfu.ca/~mtaboada/docs/publications/Kolhatkar_Taboada_EMNLP2017_WS.pdf). [Proceedings of the Workshop Natural Language Processing Meets Journalism](http://nlpj2017.fbk.eu/), Conference on Empirical Methods in Natural Language Processing. Copenhagen. September 2017.

- Kolhatkar, V. and M. Taboada (2017) [Constructiveness in news comments](www.sfu.ca/~mtaboada/docs/publications/Kolhatkar_Taboada_Abusive_Lg_WS_2017.pdf). [Proceedings of the 1st Abusive Language Online Workshop](https://sites.google.com/site/abusivelanguageworkshop2017/), 55th Annual Meeting of the Association for Computational Linguistics. Vancouver. August 2017, pp. 11-17.

The data is divided into two main parts: 
- Raw data 
- Annotated data
  - SFU constructiveness and toxicity corpus
  - SFU Appraisal corpus
  - SFU negation corpus



# Raw data 
The corpus contains 10,339 opinion articles (editorials, columns, and op-eds) together with their 663,173 comments from 304,099 comment threads, from the main Canadian daily in English, \textit{The Globe and Mail}, for a five-year period (from January 2012 to December 2016). We organize our corpus into three sub-corpora: the articles corpus, the comments corpus, and the comment-threads corpus, organized into three CSV files: gnm_articles.csv, gnm_comments.csv, and gnm_comment_threads.csv. 

## gnm_articles.csv

<br>
This CSV contains information about The Globe and Mail articles in our dataset. Below we describe fields in this CSV.

<b>article_id</b><br>
A unique identifier for the article. We use this identifier in the comments CSV. You'll also see this identifier in the article url.  (E.g., 26691065)

<b>title</b><br>
The title or the headline of The Globe and Mail opinion article. (E.g., <em>Fifty years in Canada, and now I feel like a second-class citizen</em>)

<b>article_url</b><br>
The Globe and Mail url for the article. (E.g., http://www.theglobeandmail.com/opinion/fifty-years-in-canada-and-now-i-feel-like-a-second-class-citizen/article26691065/)

<b>author</b><br>
The author of the opinion article. 

<b>published_date</b><br>
The date when the article was published. (E.g., 2015-10-16 EDT)

<b>ncomments</b><br>
The number of comments in the comments corpus for this article. 

<b>ntop_level_comments</b><br>
The number of top-level comments in the comments corpus for this article. 

<b>article_text</b><br>
The article text. We have preserved the paragraph structure in the text with paragraph tags. 

## gnm_comments.csv <br>
The CSV contains all unique comments (663,173 comments) in response to the articles in articles.csv after removing duplicates and comments with large overlap. The corpus is useful to study individual comments, i.e., without considering their location in the comment thread structure. Below we describe fields in this CSV.

<b>article_id</b><br>
A unique identifier for the article. We use this identifier in the comments CSV. You'll also see this identifier in the article url. (E.g., 26691065)

<b>comment_counter</b><br>
The comment counter which encodes the position and depth of a comment in a comment thread. Below are some examples. 
- First top-level comment: source1_article-id_0
- First child of the top-level comment: source1_article-id_0_0
- Second child of the top-level comment: source1_article-id_0_1
- Grandchildren. source1_article-id_0_0_0, source1_article-id_0_0_1

<b>comment_author</b><br>
The username of the author of the comment. 

<b>post_time</b><br>
The posting time of the comment. The comments from source2 have post_time. 

<b>timestamp</b><br>	
The timestamp indicating the posting time of the comment. The comments from source1 have timestamp. 

<b>comment_text</b><br>
The comment text. The text is minimally preproessed. We have cleaned the HTML tags and have done preliminary word segmentation to fix missing spaces after punctuation. 

<b>reactions</b><br>
The comments from source2 occassionaly have reactions. 

<b>replies</b><br>
A flag indicating whether the comment has replies or not. 

<b>TotalVotes</b><br>
The total votes (positive votes + negative votes)

<b>negVotes</b><br>
The negative votes received by the comment.

<b>posVotes</b><br>
The positive votes received by the comment. 

<b>vote</b><br>
Not sure. A Field from the scraped comments JSON. 

<b>comment_id</b><br>
The comment identifier from the scraped comments JSON

<b>parentID</b><br>
The parent's identifier from the scraped comments JSON

<b>threadID</b><br>
The thread identifier from the scraped comments JSON

<b>streamId</b><br>
The stream identifier from the scraped comments JSON

<b>edited</b><br>
A Field from the scraped comments JSON. Guess: Whether the comment is edited or not. 

<b>isModerator</b><br>
A Field from the scraped comments JSON. Guess: Whether the commenter is a moderator. The value is usually False. 

<b>highlightGroups</b><br>
Not sure. A Field from the scraped comments JSON. 

<b>moderatorEdit</b><br>
Not sure. A Field from the scraped comments JSON. Guess: Whether the comment is edited by the moderator or not.

<b>descendantsCount</b><br>
Not sure. A Field from the scraped comments JSON. Guess: The number of descendents in the thread structure. 

<b>threadTimestamp</b><br>
The thread time stamp from the scraped JSON.

<b>flagCount</b><br>
Not sure. A Field from the scraped comments JSON. 

<b>sender_isSelf</b><br>
Not sure. A Field from the scraped comments JSON. 

<b>sender_loginProvider</b><br>
The login provider (e.g., Facebook, GooglePlus, LinkedIn, Twitter, Google)

<b>data_type</b><br>
A Field from the scraped comments JSON, usually marked as 'comment'. 

<b>is_empty</b><br>
Not sure. A Field from the scraped comments JSON. Guess: Whether the comment is empty or not. 

<b>status</b><br>
The status of the comment (e.g., published, rejected, deleted)

## gnm_comment_threads.csv <br>
This CSV contains all unique comment threads -- a total of 304,099 unique comment threads in response to the articles in the gnm_articles.csv. This CSV can be used to study online conversations.

The fields in this CSV are same as that of gnm_comments.csv.

# Annotated data

## SFU constructiveness and toxicity corpus


<b>article_id</b><br>
A unique identifier for the article. This identifier can be used to link the comment to the appropriate article from gnm_articles.csv in the raw corpus.

<b>comment_counter</b><br>
The comment counter which encodes the position and depth of a comment in a comment thread. The comment counter can be used to link the comment to the raw corpus. 

<b>title</b><br>
The title of The Globe and Mail opinion article. 

<b>globe_url</b><br>
The URL of the article on The Globe and Mail. 

<b>comment_text</b><br>
The comment text. 

<b>is_constructive</b><br>
Crowd's annotation on constructiveness (yes, no, not sure)

<b>is_constructive:confidence</b><br>
Crowd's confidence (between 0 to 1.0) about the answer. In CrowdFlower terminology, each annotator has a trust level based on how they perform on the gold examples, and each answer has a confidence, which is a normalized score of the summation of the trusts associated with annotators.

<b>toxic_level</b><br>
Crowd's annotation on the toxicity level of the comment

<b>toxic_level:confidence</b><br>
Crowd's confidence (between 0 to 1.0) about the answer.

<b>did_you_read_the_article</b><br>
Whether the annotator has read the article or not. 

<b>did_you_read_the_article:confidence</b><br>
Crowd's confidence (between 0 to 1.0) about the answer.

<b>annotator_comments</b><br>
Free text comments from the annotators. 

<b>expert_is_constructive</b><br>
Expert's judgement on constructiveness of the comment. 

<b>expert_toxicity_level</b><br>
Expert's judgement on the toxicity level of the comment. 

<b>expert_comments</b><br>
Expert's free text comments on crowd's annotations. 

## SFU Appraisal corpus

The Appraisal annotations were performed using WebAnno. You can see [WebAnno server installation instructions](https://github.com/sfu-discourse-lab/WebAnno) on our GitHub page.
The guidelines directory contains a full description of the annotation guidelines. The annotations are made available as a project in .tsv files from WebAnno.

## SFU negation corpus
The negation annotations were performed using WebAnno. You can see [WebAnno server installation instructions](https://github.com/sfu-discourse-lab/WebAnno) on our GitHub page.
The guidelines directory contains a full description of the annotation guidelines. The annotations are made available as a project in .tsv files from WebAnno.


