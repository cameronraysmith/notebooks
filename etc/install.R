# sudo Rscript install.R
depp <- c("BioCircos","cluster","devtools","ggplot2","enrichR","htmlwidgets",
          "rio","shiny","shinycssloaders","stringr","viridis",
          "DT","coloc","curl","dplyr","grDevices","jsonlite","plotly",
          "shinyjs","reshape2","shinythemes","stats","purrr","readr","UpSetR")

BioDepp <- c("IRanges","BiocGenerics","clusterProfiler","GenomicRanges",
            "cBioPortalData", "AnVIL", "iClusterPlus", "MOFA2", "MOFAdata",
             "tidyverse", "BloodCancerMultiOmics2017", "curatedTCGAData",
             "GenomicDataCommons")

# Check and install missing R packages
depp.new<-depp[!(depp%in%installed.packages())]
if (length(depp.new)) {
  install.packages(depp.new, repos='http://cran.us.r-project.org', Ncpus = 4)
}
# # Check and install missing Bioconductor packages
BioDepp.new<-BioDepp[!(BioDepp%in%installed.packages())]
if (length(BioDepp.new)) {
  if (!requireNamespace("BiocManager", quietly = TRUE))
    install.packages("BiocManager", repos='http://cran.us.r-project.org', Ncpus = 4)
  BiocManager::install(BioDepp, type="source", Ncpus = 4)
}
