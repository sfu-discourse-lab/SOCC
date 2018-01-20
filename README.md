# SOCC
SFU Opinion and Comments Corpus

The SFU Opinion and Comments Corpus (SOCC) is a corpus for the analysis of online news comments. Our corpus contains comments and the articles from which the comments originated. The articles are all opinion articles, not hard news articles. The corpus is larger than any other currently available comments corpora, and has been collected with attention to preserving reply structures and other metadata. In addition to the raw corpus, we also present annotations for four different phenomena: constructiveness, toxicity, negation and its scope, and appraisal. 

For more information about this work, please see our papers. 

- Kolhatkar. V. and M. Taboada (2017) [Using New York Times Picks to identify constructive comments](www.sfu.ca/~mtaboada/docs/publications/Kolhatkar_Taboada_EMNLP2017_WS.pdf). [Proceedings of the Workshop Natural Language Processing Meets Journalism](http://nlpj2017.fbk.eu/), Conference on Empirical Methods in Natural Language Processing. Copenhagen. September 2017.

- Kolhatkar, V. and M. Taboada (2017) [Constructiveness in news comments](www.sfu.ca/~mtaboada/docs/publications/Kolhatkar_Taboada_Abusive_Lg_WS_2017.pdf). [Proceedings of the 1st Abusive Language Online Workshop](https://sites.google.com/site/abusivelanguageworkshop2017/), 55th Annual Meeting of the Association for Computational Linguistics. Vancouver. August 2017, pp. 11-17.

The data is divided into two main parts: 
- Raw data
- Annotated data. Annotations:
  - Constructiveness
  - Toxicity
  - Appraisal
  - Negation



# Raw data 
The corpus contains 10,339 opinion articles (editorials, columns, and op-eds) together with their 663,173 comments from 304,099 comment threads, from the main Canadian daily in English, \textit{The Globe and Mail}, for a five-year period (from January 2012 to December 2016). We organize our corpus into three sub-corpora: the articles corpus, the comments corpus, and the comment-threads corpus, organized into three CSV files. 

<b>gnm_articles.csv</b><br>
This CSV contains information about The Globe and Mail articles in our dataset. 

<i>article_id</i><br>
A unique identifier for the article. We use this identifier in the comments CSV. You'll also see this identifier in the article url.  (E.g., 26691065)

<i>title</i><br>
The title or the headline of The Globe and Mail opinion article. (E.g., <em>Fifty years in Canada, and now I feel like a second-class citizen</em>)

<i>article_url</i><br>
The Globe and Mail url for the article. (E.g., http://www.theglobeandmail.com/opinion/fifty-years-in-canada-and-now-i-feel-like-a-second-class-citizen/article26691065/)

<i>author</i><br>
The author of the opinion article. 

<i>published_date</i><br>
The date when the article was published. (E.g., 2015-10-16 EDT)

<i>ncomments</i><br>
The number of comments in the comments corpus for this article. 

<i>ntop_level_comments</i><br>
The number of top-level comments in the comments corpus for this article. 

<i>article_text</i><br>
The article text. We have preserved the paragraph structure in the text with paragraph tags. 

<b>gnm_comments.csv</b><br>
This CSV contains article id and comment text and other metadata associated with each comment. 

<i>article_id</i><br>
A unique identifier for the article. We use this identifier in the comments CSV. You'll also see this identifier in the article url. (E.g., 26691065)

<i>comment_counter</i><br>
The comment counter that encodes two pieces of informaion: the source of the comment and the depth of the comment in the comment thread. 

<i>author</i><br>
The author of the comment. 

<i>post_time</i><br>
The posting time of the comment. The comments from source2 have post_time. 

<i>timestamp</i><br>	
The timestamp indicating the posting time of the comment. The comments from source1 have timestamp. 

<i>comment_text</i><br>
The comment text. The text is minimally preproessed. We have cleaned html tags and have done preliminary word segmentation to fix missing spaces after punctuation. 

<i>reactions</i><br>
The comments from source2 occassionaly have reactions. 

<i>replies</i><br>
A flag indicating whether the comment has replies or not. 

<i>TotalVotes</i><br>
The total votes (positive votes + negative votes)

<i>negVotes</i><br>
The negative votes received by the comment.

<i>posVotes</i><br>
The positive votes received by the comment. 

# Annotated data

## Constructiveness and toxicity

## Appraisal

The Appraisal annotations were performed using WebAnno. You can see [WebAnno server installation instructions](https://github.com/sfu-discourse-lab/WebAnno) on our GitHub page.
The guidelines directory contains a full description of the annotation guidelines. The annotations are made available as a project in .tsv files from WebAnno.

## Negation
The negation annotations were performed using WebAnno. You can see [WebAnno server installation instructions](https://github.com/sfu-discourse-lab/WebAnno) on our GitHub page.
The guidelines directory contains a full description of the annotation guidelines. The annotations are made available as a project in .tsv files from WebAnno.


