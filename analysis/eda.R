setwd("/Users/ianwhitestone/Documents/git/khp-analytics/analysis/")

library(ggplot2)
source("helper.R")
library(data.table)
library(dtplyr)
library(dplyr)
library(scales)
library(zoo)
library(RColorBrewer)
library(plyr)
library(RPostgreSQL)
library(lubridate)


number_ticks = function(n) {function(limits) pretty(limits, n)}
palette = brewer.pal("YlGnBu", n=9)


# loads the PostgreSQL driver
drv = dbDriver("PostgreSQL")
# creates a connection to the postgres database
# note that "con" will be used later in each connection to the database
conn = dbConnect(drv, dbname = "",
                 host = "", port = 5432,
                 user = "")


query = "
    SELECT a.*, b.score, c.queue_id, c.start_time, c.end_time
    FROM enhanced_transcripts as a
    JOIN distress_scores as b
    ON a.contact_id=b.contact_id
    JOIN contacts as c
    ON a.contact_id=c.contact_id
    "
df = dbGetQuery(conn, query) %>% setDT

# Explore DF
head(df, n=5)
dim(df)
str(df)

ggplot(df, aes(x=score)) +
  geom_bar() + theme_dlin() +
  scale_x_continuous(breaks=number_ticks(8))


ggplot(df, aes(x=factor(score), y=handle_time)) +
  geom_boxplot() + theme_dlin() +
  labs(x='score', y='handle time (min)')
  # scale_x_continuous(breaks=number_ticks(8))

