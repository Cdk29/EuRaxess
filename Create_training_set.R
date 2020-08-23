


texts<-readRDS("job_labelised_final")

dim(texts)

texts$url<-NULL
texts$text_job<-NULL
texts$tickle_boxes<-NULL
texts$institute<-NULL
texts$summary<-NULL

dim(texts)


saveRDS(texts, "training_set.RDS")