if (!require(scales)) 
  install.packages('scales', repos = "http://cran.us.r-project.org")
library("scales")

## Read in distance measure file
dist <- read.delim (snakemake@input[["txt"]], header = T)
title <- snakemake@params[["sample_name"]]

## Select the longest isoforms
trx_len <- dist$utr5_size + dist$cds_size + dist$utr3_size
dist <- dist[order(dist$gene_name, trx_len),] # sort by gene name, then transcript length
dist <- dist[duplicated(dist$gene_name),] # select the longest isoform

## Rescale regions and determine scale
utr5.SF <- median(dist$utr5_size, na.rm = T)/median(dist$cds_size, na.rm = T)
utr3.SF <- median(dist$utr3_size, na.rm = T)/median(dist$cds_size, na.rm = T)

# Assign the regions to new dataframes
utr5.dist <- dist[dist$rel_location < 1, ]
utr3.dist <- dist[dist$rel_location >= 2, ]
cds.dist <- dist [dist$rel_location < 2 & dist$rel_location >= 1, ]

# Rescale 5'UTR and 3'UTR
utr5.dist$rel_location <- rescale(utr5.dist$rel_location, to = c(1-utr5.SF, 1), from = c(0,1))
utr3.dist$rel_location <- rescale(utr3.dist$rel_location, to = c(2, 2+utr3.SF), from = c(2,3))

# Combine the regions in a new dataframe and plot
all.regions <- c(utr5.dist$rel_location, cds.dist$rel_location, utr3.dist$rel_location)

## A smooth density plot
png(filename=snakemake@output[["png"]])
plot(density(all.regions), main=title, xaxt='n', xlab="")
abline (v = 1, lty  = 1, col = "red")
abline (v = 2, lty  = 1, col = "red")
axis(at=c(0.6,1.5,2.5), labels=c("5'UTR","CDS","3'UTR"), side=1)
dev.off()