# SOCC
SFU Opinion and Comments Corpus

The SFU Opinion and Comments Corpus (SOCC) is a corpus for the analysis of online news comments. Our corpus contains comments and the articles from which the comments originated. The articles are all opinion articles, not hard news articles. The corpus is larger than any other currently available comments corpora, and has been collected with attention to preserving reply structures and other metadata. In addition to the raw corpus, we also present annotations for four different phenomena: constructiveness, toxicity, negation and its scope, and appraisal. 

For more information about this work, please see our papers. 

- Kolhatkar. V. and M. Taboada (2017) [Using New York Times Picks to identify constructive comments](https://aclanthology.info/pdf/W/W17/W17-4218.pdf). [Proceedings of the Workshop Natural Language Processing Meets Journalism](http://nlpj2017.fbk.eu/), Conference on Empirical Methods in Natural Language Processing. Copenhagen. September 2017.

- Kolhatkar, V. and M. Taboada (2017) [Constructiveness in news comments](http://aclweb.org/anthology/W17-3002). [Proceedings of the 1st Abusive Language Online Workshop](https://sites.google.com/site/abusivelanguageworkshop2017/), 55th Annual Meeting of the Association for Computational Linguistics. Vancouver. August 2017, pp. 11-17.

# Download link and data

[Download SFU Opinion and Comments Corpus](https://researchdata.sfu.ca/islandora/object/islandora%3A9109)

The data is divided into two main parts, with the annotated portion being, in turn, divided into three portions: 
- [Raw data](#raw)
  - The articles corpus (gnm_articles.csv)
  - The comments corpus (gnm_comments.csv)
  - The comment-threads corpus (gnm_comment_threads.csv)
- [Annotated data](#annotated)
  - [SFU constructiveness and toxicity corpus](#constructiveness)
  - [SFU negation corpus](#negation)
  - [SFU Appraisal corpus](#appraisal)


# <a name="raw"></a>Raw data 
The corpus contains 10,339 opinion articles (editorials, columns, and op-eds) together with their 663,173 comments from 304,099 comment threads, from the main Canadian daily in English, <em>The Globe and Mail</em>, for a five-year period (from January 2012 to December 2016). We organize our corpus into three sub-corpora: the articles corpus, the comments corpus, and the comment-threads corpus, organized into three CSV files: gnm_articles.csv, gnm_comments.csv, and gnm_comment_threads.csv. 

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

<b>timestamp</b><br>	
The timestamp indicating the posting time of the comment. The comments from source1 have timestamp. 

<b>post_time</b><br>
The posting time of the comment. The comments from source2 have post_time. 

<b>comment_text</b><br>
The comment text. The text is minimally preproessed. We have cleaned the HTML tags and have done preliminary word segmentation to fix missing spaces after punctuation. 

<b>TotalVotes</b><br>
The total votes (positive votes + negative votes)

<b>posVotes</b><br>
The positive votes received by the comment. 

<b>negVotes</b><br>
The negative votes received by the comment.

<b>vote</b><br>
Not sure. A Field from the scraped comments JSON. 

<b>reactions</b><br>
A list of reactions of other commenters on this comment. The comments from source2 occassionaly have reactions. 
Here is an example:

{u'reaction_list': [{u'reaction_user': u'areukiddingme', u'reaction': u'disagree', u'reaction_time': u'Dec 13, 2016'}, {u'reaction_user': u'Mark Shore', u'reaction': u'like', u'reaction_time': u'Dec 13, 2016'}], u'reaction_counts': [u'All 2']}


<b>replies</b><br>
A flag indicating whether the comment has replies or not. 

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

# <a name="annotated"></a>Annotated data

## <a name="constructiveness"></a>SFU constructiveness and toxicity corpus

We annotated a subset of SOCC for constructiveness and toxicity. The annotated corpus is organized as a CSV and contains 1,043 annotated comments in responses to 10 different articles covering a variety of subjects: technology, immigration, terrorism, politics, budget, social issues, religion, property, and refugees. For half of the articles, we included only top-level comments. For the other half, we included both top-level comments and responses. We used CrowdFlower (https://www.crowdflower.com/) as our crowdsourcing annotation platform and annotated the comments for constructiveness. We asked the annotators to first read the articles, and then to tell us whether the displayed comment was constructive or not. 

For toxicity, we asked annotators a multiple-choice question, *How toxic is the comment?* Four answers were possible:

  - Very toxic
  - Toxic
  - Mildly toxic
  - Not toxic

More information on the annotation, and the instructions to annotators, is available in the CrowdFlower_instructions file. 

## SFU_constructiveness_toxicity_corpus.csv
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

## <a name="negation"></a>SFU negation corpus
The negation annotations were performed using WebAnno. You can see [WebAnno server installation instructions](https://github.com/sfu-discourse-lab/WebAnno) on our GitHub page.

The guidelines directory contains a full description of the annotation guidelines. The annotations are made available as a project in .tsv files from WebAnno.

The WebAnno directory is structured in folders. There are five subfolders: annotation, annotation_ser, curation, curation_ser, and source. The folders annotation_ser and curation_ser contain documents in a format that WebAnno uses to import annotations and are difficult to read otherwise. The annotation folder includes the original annotations, while the curation folder contains the final annoatations. These two folders have subfolders themselves, one for each comment that was annotated. Each subfolder is named with a comment ID (the same as in the raw corpus), and inside is a .tsv file with the annotations, named after the user who created those annotations. The annotations can be viewed from these .tsv files using a document viewer.

Each .tsv file begins with a comment line describing the format of the file (e.g. #FORMAT=WebAnno TSV 3.1) followed by one line for each column of data indicating which annotation layer is described by that column. Then, for each sentence in the annotated comment there is a line in the .tsv file with the whole sentence (e.g. #Text=This story gives broader context to the earlier reports of the abuse of band finances by the native leadership.). Each line after that one describes one word in the comment. The first column indicates which sentence the word is in followed by a dash, after which is the index of the word in the sentence (e.g. 1-1 for the first word in the first sentence). The second column indicates the position of the first and last character of the word in the comment (e.g. 0-4 for a four-letter word at the beginning of the comment). The third column gives the text of the word (e.g. This). The remaining columns indicate annotated labels.

In the Negation project, there is only one layer with four possible annotations: NEG, SCOPE, FOCUS, and XSCOPE. These labels appear in the fourth column of the .tsv file. If a span includes multiple words, it will be marked with an index; for example, a span of four words marked with the same SCOPE span might have SCOPE\[1] in column 4 for each word, while a single word annotated with NEG would have NEG in column 4 for that word. In comments with no negation annotations, there is no fourth column.

These projects can also be imported back into WebAnno, a process which we detail in the WebAnno instructions (see link above).

## <a name="appraisal"></a>SFU Appraisal corpus

The Appraisal annotations were performed using WebAnno. The structure of the corpus is identical to that of the negation corpus, though the .tsv files are slightly different. Guidelines for Appraisal annotation are available in the guidelines directory.

The .tsv files for Appraisal have the category of Appraisal (i.e. Appreciation, Judgment, Affect) in the fourth column, its polarity (i.e. pos, neg, neu) in the fifth, the category of Graduation (i.e. Force, Focus) in the sixth, and the polarity of Graduation (e.g. up, down) in the seventh. For comments without Appraisal, there will only be three columns (the fourth and beyond will not appear). For comments without Graduation, there will be no sixth or seventh column. There are no comments with Graduation that lack Appraisal.

Spans that include multiple words are indexed in the same way that those in Negation are. For example, a multi-word span of Appreciation might have the annotation Appreciation\[1] in the fourth column for each word it covers, while a single-word span of Appreciation would simply have Appreciation in the fourth column in that word's row.
