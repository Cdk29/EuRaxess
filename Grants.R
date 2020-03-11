
#block-system-main a
#
scrape_urls_grant <- function(search_url) {
  #function to scrape all the urls of grant from the result table
  search_space <- read_html(search_url)
  Sys.sleep(3)
  urls<-search_space %>% html_nodes("a") %>% html_attr("href")
  idx<-grep("/jobs/funding/", urls)
  urls<-urls[idx]
  #two occurences per offer :
  urls<-unique(urls)
  return(urls)
}

# search_url<-"https://euraxess.ec.europa.eu/funding/search/"
# 
# scrape_urls_grant(search_url)


scrape_urls_grants_euraxess <- function(search_url, last_page) {
  #function recollect all the url of job offer
  #scrap all the url of one page; then pass to next page
  #on euraxxes, page 2 is page 1 in the url
  template_url<-paste0(search_url, "?page=")

  urls<-pblapply(paste0(template_url, 1:last_page), scrape_urls_grant)
  urls<-unlist(urls)
  #not forget the first page
  Sys.sleep(3)
  urls<-c(urls, scrape_urls_grant(search_url))
  urls<-paste0("https://euraxess.ec.europa.eu", urls)
  return(urls)
}


read_grant_offer <- function(url) {
  #job_offer <- read_html(url)
  job_offer <- tryCatch(read_html(url), error=function(e) NULL)
  if (is.null(job_offer)) {
    dt<-data.table(url, text_job="void", tickle_boxes="void",  institute="void")
    return(dt)
  }
  Sys.sleep(3)

  job_id<-"grant"

  #all general text, scrap too much things but it is the only one that generalize for each page
  #job_offer %>% html_nodes("#node-498418 p")  %>%  html_text()
  text_grant <- job_offer %>% html_nodes("p") %>%
    html_text() %>% paste( collapse = ' ')

  #all the tickle box of the job offer :
  tickle_boxes <- "Nothing."

  #location :
  #location <- job_offer %>% html_nodes(".field-country div") %>%  html_text()
  institute <- job_offer %>% html_nodes(".field-org-name div") %>%  html_text()

  #return a dataframe on each iteration of the apply, similar to page 278 of Text Mining in practice with R
  #rbindlist will be called after

  #part to create the dataframe
  dt<-data.table(url, text_grant, tickle_boxes, institute)
  return(dt)
}

url<-"https://euraxess.ec.europa.eu/jobs/funding/phd-mathematics-design-experiments-regression-models-correlated-observations"

read_grant_offer(url)


search_url<-"https://euraxess.ec.europa.eu/funding/search/"
urls<-scrape_urls_grants_euraxess(search_url, 1) 


grant_offers<-pblapply(urls, read_grant_offer)
grant_offers<-rbindlist(grant_offers, use.names = TRUE )

saveRDS(job_offer, file="grant_offers.RDS")






