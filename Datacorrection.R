
#PROBLEM : for the job offer sorted manually, were not kept as negative when pressing just enter :
#the"n" by default was not working

j<-readRDS("job_labelised")

dim(j)

table(j$label)

job_curated<-readRDS("job_offer_curated.RDS")

job_to_examine <- job_curated %>% filter(!summary=="EMPTY")

idx<-which(job_to_examine$url %in% j$url)

dim(job_to_examine[-idx,])
#551   5
job_to_examine<-job_to_examine[-idx,]

#already examined jobs :
job_to_examine<-head(job_to_examine, 300)
dim(job_to_examine)

job_to_examine$text<-paste(job_to_examine$text_job, job_to_examine$tickle_boxes)
job_to_examine$label<-0

dim(job_to_examine)
dim(j)

#> dim(job_to_examine)
#[1] 300   7
#> dim(j)
#[1] 1458    7

job<-rbind(j, job_to_examine)



saveRDS(job, "job_labelised_final")