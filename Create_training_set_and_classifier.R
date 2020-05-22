##Script to read and classify grants and job offers

library(udpipe)
library(data.table)
library(dplyr)

job_curated<-readRDS(file="job_offer_curated.RDS")
head(job_curated)

#put "empty" summary on a other data.table

job_curated<-head(job_curated, 200)

job_empty_summary <-job_curated %>% filter(summary=="EMPTY")

job_to_examine <- job_curated %>% filter(!summary=="EMPTY")

job_of_interrest<-data.table()

for (i in 1:dim(job_to_examine)[1]) {
  print(job_to_examine[i,]$summary)
  keep <- "n"
  keep <- readline("keep offer ? (press y to keep, default is n)")
  if (keep=="n") {
    job_empty_summary<-rbind(job_empty_summary, job_to_examine[i,])
  }
  if (keep=="y"){
    job_of_interrest<-rbind(job_of_interrest, job_to_examine[i,])
  }
}


### Built the classifier
## From https://github.com/WinVector/PDSwR2/blob/master/IMDB/lime_imdb_example.R

library(text2vec)
library(wrapr)
create_pruned_vocabulary <- function(texts) {
  # create an iterator over the training set
  it_train <- itoken(texts,
                     preprocessor = tolower,
                     tokenizer = word_tokenizer,
                     ids = names(texts),
                     progressbar = FALSE)

  # tiny stop word list
  stop_words <- qc(the, a, an, this, that, those, i, you)
  vocab <- create_vocabulary(it_train, stopwords = stop_words)

  # prune the vocabulary
  # prune anything too common (appears in over half the documents)
  # prune anything too rare (appears in less than 0.1% of the documents)
  # limit to 10,000 words after that
  pruned_vocab <- prune_vocabulary(
    vocab,
    doc_proportion_max = 0.5,
    doc_proportion_min = 0.001,
    vocab_term_max = 10000
  )

  pruned_vocab
}


# take a corpus and a vocabulary
# and return a sparse matrix (of the kind xgboost will take)
# rows are documents, columns are vocab words
# this representation loses the order or the words in the documents
make_matrix <- function(texts, vocab) {
  iter <- itoken(texts,
                 preprocessor = tolower,
                 tokenizer = word_tokenizer,
                 ids = names(texts),
                 progressbar = FALSE)
  create_dtm(iter, vocab_vectorizer(vocab))
}

job_empty_summary$text<-paste(job_empty_summary$text_job, job_empty_summary$tickle_boxes)
job_of_interrest$text<-paste(job_of_interrest$text_job, job_of_interrest$tickle_boxes)
job_empty_summary$label<-0
job_of_interrest$label<-1



job<-rbind(job_empty_summary, job_of_interrest)


vocab<-create_pruned_vocabulary(job$text)

##dtm created as detailed in Practical data science with R p208

dtm<-make_matrix(job$text, vocab)

#code to save the dtm

#code to save the vocab

#code to save the object job






