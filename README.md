#  EuRaxess

This package regroup R functions to scrappe job offer from Euraxess. Job offers on Euraxess can be poorly filled (lot of post-doc offer for early stage stage researcher, not meaningfull title, etc), and jobs are the interface of biology/medicine and computer science cannot be search directly. Such jobs at the interface can be hidden inside differents ITN. For such reason and because there is a lot of offers on this website (at least 400 pages will be scrapped on the first iteration), a best approach is to use text mining to ease the work.

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

#Key words to create a summary of each job offer. 
#If none of them if found in the offer the summary will be empty (speed up the search).

key_words<-c("systematic", "review", "text", "mining", "text")

#Load the udpipe model :

tagger <- udpipe_load_model("english-gum-ud-2.4-190531.udpipe")

# Scrappe the 400 first pages of result for "Early stage researcher

search_url <- "https://euraxess.ec.europa.eu/jobs/search/field_research_profile/first-stage-researcher-r1-446?sort=created&order=desc"

urls<-scrape_urls_euraxess(search_url, 400) 

#read the job offers :

job_offer<-pblapply(urls, read_job_offer)
job_offer<-rbindlist(job_offer, use.names = TRUE )

saveRDS(job_offer, file="job_offer.RDS")
#synthetise the jobs offers :
job_offer<-summarise_all_job_offers(job_offer, tagger, key_words)

saveRDS(job_offer, file="job_offer_curated.RDS")

```
