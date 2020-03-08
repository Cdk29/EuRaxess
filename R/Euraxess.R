# library(rvest)
# library(stringr)
# library(udpipe)
# library(textrank)
# library(pbapply)
# library(data.table)

#' @title read_job_offer
#'
#' @description Read the job offer passed as url from euraxess and extract :
#' - the general text on it
#' - the content of the tickle box
#' - two parameter of location
#'
#' The text is extracted in a broad way using "#node-" + id of the job offer, it is the only way to generalize to
#' all the jobs offers.
#' @param url : Url of a job offer.
#'
#' @return datatable with the content of the job offer.
#' @export
#'
#' @examples
#' \dontrun{
#' url <- "https://euraxess.ec.europa.eu/jobs/498418"
#' df<-read_job_offer(url)
#' }
read_job_offer <- function(url) {
  #job_offer <- read_html(url)
  job_offer <- tryCatch(read_html(url), error=function(e) NULL)
  if (is.null(job_offer)) {
    dt<-data.table(url, text_job="void", tickle_boxes="void",  institute="void")
    return(dt)
  }
  Sys.sleep(3)
  #cut the Job ID from the url to got the text of the node
  url_cut<-strsplit(url, "/")
  url_cut<-unlist(url_cut)
  job_id<-url_cut[length(url_cut)]

  #all general text, scrap too much things but it is the only one that generalize for each page
  #job_offer %>% html_nodes("#node-498418 p")  %>%  html_text()
  text_job <- job_offer %>% html_nodes( paste0("#node-", job_id, " p")) %>%
    html_text() %>% paste( collapse = '')

  #all the tickle box of the job offer :
  tickle_boxes <- job_offer %>% html_nodes(".field-body ul") %>%  html_text() %>% paste(collapse = '')

  #location :
  #location <- job_offer %>% html_nodes(".field-country div") %>%  html_text()
  institute <- job_offer %>% html_nodes(".field-company-institute div") %>%  html_text()

  #return a dataframe on each iteration of the apply, similar to page 278 of Text Mining in practice with R
  #rbindlist will be called after

  #part to create the dataframe
  dt<-data.table(url, text_job, tickle_boxes, institute)
  return(dt)
}

#following url is all the job for :
#First Stage Researcher (R1) (7069)
#Sort by post date. Deadline for application is filled sometimes randomly by people (like some other fields actually)
#Sorting in order to stop when the offers are too old

#' @title scrape_urls_page
#'
#' @description Function to scrape all the urls of job from result page. Allow to used some filter from euraxess,
#' like "early stage researcher". Used in scrape_urls_euraxess.
#' @param search_url :  Url of one results page of a search for job offer. Can be the first or page 17. Passed as
#' input by scrape scrape_urls_euraxess.
#'
#' @return
#' @export
#'
#' @examples
#' \dontrun{
#' search_url <- "https://euraxess.ec.europa.eu/jobs/search/field_research_profile/first-stage-researcher-r1-446?sort=created&order=desc"
#' urls <- scrape_urls_pages(search_url)
#' }
scrape_urls_page <- function(search_url) {
  #function to scrape all the urls of job from result page
  search_space <- read_html(search_url)
  Sys.sleep(3)
  #hrs4r is not nothing we want to keep
  urls<-search_space %>% html_nodes("a") %>% html_attr("href")
  idx<-grep("/jobs/\\d", urls)
  urls<-urls[idx]
  #two occurences per offer :
  urls<-unique(urls)
  return(urls)
}


#' @title scrape_urls_euraxess
#'
#' @description Function recollect all the url of job offers from euraxes to run read_job_offer.
#'
#' @param search_url : url of the first page of results of a job offers search.
#' @param last_page : last page of the search to be scrapped using this function. 3 mean that the first page of resuls
#' will be scrapped, then the three others.
#'
#' @return
#' @export
#'
#' @examples
#' \dontrun{
#' scrape_urls_euraxess(search_url, 3)
#' urls<-scrape_urls_euraxess(search_url, 3)
#' job_offer<-pblapply(urls, read_job_offer)
#' }
#'
scrape_urls_euraxess <- function(search_url, last_page) {
  #function recollect all the url of job offer
  #scrap all the url of one page; then pass to next page
  #on euraxxes, page 2 is page 1 in the url
  template_url<-paste0(search_url, "&page=")

  urls<-pblapply(paste0(template_url, 1:last_page), scrape_urls_page)
  urls<-unlist(urls)
  #not forget the first page
  Sys.sleep(3)
  urls<-c(urls, scrape_urls_page(search_url))
  urls<-paste0("https://euraxess.ec.europa.eu", urls)
  return(urls)
}



#' @title  resume_job_offer
#'
#' @description Summarized a job offer using textrank. During the execution of the function, the terminology is
#' reduced to the keywords passed as input to get a summary containing only sentence with keywords of interrest.
#'
#' @param df : df of job offer scrapped by read_offer_offer.
#' @param tagger : a udpipe model for english annotation.
#' @param key_words : key words to create the summary with pagerank
#'
#' @return a summary of the job offer that can be empty of no sentence contain the keywords.
#' @export
#'
#' @examples
#' \dontrun{
#' key_words<-c("systematic", "review", "text", "mining", "text")
#' tagger <- udpipe_load_model("english-gum-ud-2.4-190531.udpipe")
#' resume_job_offer(df, tagger, key_words)
#'
#'
#' }
#'
#'
resume_job_offer <- function(df, tagger, key_words) {
  #shorten the job offer for latter manual review
  #since key words are not calculated on the fly, we do not need to do the full annotation or parsing,
  #just the sentences :
  joboffer <- udpipe_annotate(tagger, paste(df$text_job, df$tickle_boxes))
  joboffer <- as.data.frame(joboffer)
  keyw <- textrank_keywords(joboffer$lemma,
                            relevant = joboffer$upos %in% c("NOUN", "ADJ"))

  joboffer$textrank_id <- unique_identifier(joboffer, c("sentence_id"))
  sentences <- unique(joboffer[, c("textrank_id", "sentence")])

  #here the changes regarding the tutorial of text rank
  terminology <- subset(joboffer, upos %in% c("NOUN", "ADJ"))
  terminology <- terminology[, c("textrank_id", "lemma")]
  terminology <- terminology[terminology$lemma %in% key_words,]
  if (dim(terminology)[1]==0) {
    s<-"EMPTY"
    return(s)
  }
  tr <- textrank_sentences(data = sentences, terminology = terminology)
  s <- summary(tr, n = 3, keep.sentence.order = TRUE)
  s <- paste(s, collapse = " ")
  return(s)
}

# resume_job_offer(df, tagger, key_words)


# urls<-scrape_urls_euraxess(search_url, 3)

# job_offer<-pblapply(urls, read_job_offer)
# job_offer<-rbindlist(job_offer, use.names = TRUE)

# saveRDS(job_offer, file="job_offer.RDS")

#' @title summarise_all_job_offers
#'
#' @description Run resume_job_offer on all the job_offers and return a data.table with the summary
#'
#' @param job_offer : data.table of job offer.
#' @param tagger : an updpipe model for the annotation
#' @param key_words : key words on which construct the summary
#'
#' @return
#' @export
#'
#' @examples
#' \dontrun{
#' key_words<-c("systematic", "review", "text", "mining", "text")
#' tagger <- udpipe_load_model("english-gum-ud-2.4-190531.udpipe")
#' urls<-scrape_urls_euraxess(search_url, 3)
#' job_offer<-pblapply(urls, read_job_offer)
#' job_offer<-rbindlist(job_offer, use.names = TRUE)
#' saveRDS(job_offer, file="job_offer.RDS")
#' job_offer<-summarise_all_job_offers(job_offer, tagger, key_words)
#' saveRDS(job_offer, file="job_offer_curated.RDS")
#' }
summarise_all_job_offers <- function(job_offer, tagger, key_words) {
  pb = txtProgressBar(min = 1, max = dim(job_offer)[1], initial = 1)
  job_offer$summary<-"void"
  for (i in 1:dim(job_offer)[1]) {
    setTxtProgressBar(pb,i)
    summary<-resume_job_offer(job_offer[i,], tagger, key_words)
    job_offer[i,]$summary<-summary
  }
  return(job_offer)
}
