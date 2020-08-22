Create training set
================

How to use
----------

This rmarkdown document is meant to keep track of the creation of the train and test set to create a classifier to recollect interresting job offers from Euraxess automatically. Most of the code came from Create\_training\_set\_and\_classifier.R.

**This document must be run using rmarkdown::render("Create\_training\_set.Rmd", params = "ask", output\_format="github\_document") in a R session.**

``` r
library(udpipe)
library(data.table)
```

    ## data.table 1.12.8 using 1 threads (see ?getDTthreads).  Latest news: r-datatable.com

``` r
library(dplyr)
```

    ## 
    ## Attaching package: 'dplyr'

    ## The following objects are masked from 'package:data.table':
    ## 
    ##     between, first, last

    ## The following objects are masked from 'package:stats':
    ## 
    ##     filter, lag

    ## The following objects are masked from 'package:base':
    ## 
    ##     intersect, setdiff, setequal, union

Read the offers :

``` r
job_curated<-readRDS(file="job_offer_curated.RDS")
#head(job_curated)
dim(job_curated)
```

    ## [1] 2009    5

Head for the demo and testing :

``` r
job_curated<-head(job_curated, 20)
```

Create data structures to keep the jobs :

``` r
job_empty_summary <-job_curated %>% filter(summary=="EMPTY")

job_to_examine <- job_curated %>% filter(!summary=="EMPTY")

job_of_interrest <- copy(job_curated[c(FALSE),])
head(job_of_interrest)
```

    ## Empty data.table (0 rows and 5 cols): url,text_job,tickle_boxes,institute,summary

Loop to select the job offers :

``` r
for (i in 1:dim(job_to_examine)[1]) {
  #print(job_to_examine[i,]$summary)
  message("\n\n\n\n\n\n\n\n\n\n")
  message(job_to_examine[i,]$summary)
  message("\n\n\n\n\n")
  keep <- "n"
  keep <- readline("keep offer ? (press y to keep, default is n)")
  if (keep=="n") {
    job_empty_summary<-rbind(job_empty_summary, job_to_examine[i,])
  }
  if (keep=="y"){
    job_of_interrest<-rbind(job_of_interrest, job_to_examine[i,])
  }
}
```

``` r
job_empty_summary$text<-paste(job_empty_summary$text_job, job_empty_summary$tickle_boxes)
job_of_interrest$text<-paste(job_of_interrest$text_job, job_of_interrest$tickle_boxes)
job_empty_summary$label<-0
job_of_interrest$label<-1

job<-rbind(job_empty_summary, job_of_interrest)
```

Saving the jobs offers :

``` r
saveRDS(job, "job_labelised")
```
