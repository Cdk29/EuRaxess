library(udpipe)
library(rvest)
library(textrank)
library(EuRaxess)
library(rvest)
library(pbapply)
library(stringr)
library(data.table)


# Scrappe the 400 first pages of result for "Early stage researcher

search_url <- "https://euraxess.ec.europa.eu/jobs/search/field_research_profile/first-stage-researcher-r1-446?sort=created&order=desc"

urls<-scrape_urls_euraxess(search_url, 400)


job_offer<-pblapply(urls, read_job_offer)
job_offer<-rbindlist(job_offer, use.names = TRUE )

job_offer %>% dim()
job_offer %>% unique() %>% dim()
job_offer <- job_offer %>% unique()

saveRDS(job_offer, file="job_offer_x_november.RDS")

