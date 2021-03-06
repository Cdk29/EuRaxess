#  EuRaxess

This package regroup R functions to scrappe jobs/grants offers and summarize them from the website Euraxess. Job offers on Euraxess can be attractive but are often poorly filled (lot of post-doc offers categorized as early stage stage researcher, not meaningfull titles, etc), and jobs at the interface of biology/medicine and computer science are mixed into bigger project, like inside ITNs.

# Data 

- job_offer_20_septembre.RDS : scrapping of job offer from the 20 september.

# Approach

Currently the goal of the package is just to scrappe job offers. Previous approach based on Machine Learning to automatically select interresting job offers are actually an over kill, and would operate on a quite imbalanced dataset. A grep approach is more time saving.

## Dependencies 
- rvest
- stringr
- udpipe
- textrank 
- pbapply
- data.table 

## Example 

```R
library(devtools)
install_github("Cdk29/EuRaxess")

```


```R

library(udpipe) 
library(rvest)
library(textrank)
library(EuRaxess)
library(rvest)
library(pbapply)
library(stringr)
library(data.table)

#Key words to create a summary of each job offer. library(data.table)#If none of them if found in the offer the summary will be empty (speed up the search).

key_words<-c("systematic", "review", "text", "mining", "bioinformatics", "bioinformatician", "data", "machine",
             "learning", "biology", "medecine", "bioinformatician", "medical", "medicine", "nlp", "keras", "natural", 
             "processing")

#Load the udpipe model :

tagger <- udpipe_load_model("english-gum-ud-2.4-190531.udpipe")

# Scrappe the 400 first pages of result for "Early stage researcher

search_url <- "https://euraxess.ec.europa.eu/jobs/search/field_research_profile/first-stage-researcher-r1-446?sort=created&order=desc"

urls<-scrape_urls_euraxess(search_url, 400) 

#to save and reload them :
#cat(urls,file="urls.txt",sep="\n")
#urls<-readLines("urls.txt")

#read the job offers :


job_offer<-pblapply(urls, read_job_offer)
job_offer<-rbindlist(job_offer, use.names = TRUE )

saveRDS(job_offer, file="job_offer.RDS")

#problem of duplicates

job_offer %>% dim()
job_offer %>% unique() %>% dim()
job_offer <- job_offer %>% unique()

#synthetise the jobs offers :
job_offer<-summarise_all_job_offers(job_offer, tagger, key_words)

saveRDS(job_offer, file="job_offer_curated.RDS")

```
## To look quickly for some offers with keywords :

```R
job_offer <- job_offer %>% unique() 

grep("NLP", job_offer$text_job)
grep("NLP", job_offer$tickle_boxes)

job_offer[grep("NLP", job_offer$text_job),]$url
job_offer[grep("NLP", job_offer$tickle_boxes),]$url

URL<-job_offer[grep("NLP", job_offer$text_job),]$url
URL<-c(URL, job_offer[grep("NLP", job_offer$tickle_boxes),]$url)

for (i in 1:length(URL)){
  browseURL(as.character(URL[i]))  
}
```


## Example with the grants 

```R
#udpipe::udpipe_download_model("english-gum")
#definition of the functions inside Grant.R

search_url<-"https://euraxess.ec.europa.eu/funding/search/"
urls<-scrape_urls_grants_euraxess(search_url, 48)


grant_offers<-pblapply(urls, read_grant_offer)
grant_offers<-rbindlist(grant_offers, use.names = TRUE )

saveRDS(grant_offers, file="grant_offers.RDS")


tagger <- udpipe_load_model("english-gum-ud-2.4-190531.udpipe")
key_words<-c("systematic", "review", "text", "mining", "machine", "learning", "biology", "medecine", "medical", "natural", "processing", "language")


grant_offers_summarized<-summarise_all_grants_offers(grant_offers, tagger, key_words)





```

