# sudo Rscript install.R
depp <- c("BioCircos","cluster","devtools","ggplot2","enrichR","htmlwidgets",
          "rio","shiny","shinycssloaders","stringr","viridis","colormap",
          "DT","coloc","curl","dplyr","grDevices","jsonlite","plotly",
          "shinyjs","reshape2","shinythemes","stats","purrr","readr",
          "UpSetR","textshape","showtext","parallelMap","Seurat","grImport","dtw")

BioDepp <- c("IRanges","BiocGenerics","clusterProfiler","GenomicRanges",
            "cBioPortalData","AnVIL","iClusterPlus","MOFA2","MOFAdata",
             "tidyverse","BloodCancerMultiOmics2017","curatedTCGAData",
            "GenomicDataCommons","SingleR","TCGAbiolinks","maftools",
            "RTCGAToolbox","splatter","ggtree")

devtoolsDepp <- c("xlucpu/MOVICS","dynverse/dyngen","dynverse/scvelo",
                  "dynverse/dyno","rcannood/GENIE3bis","shenorrLab/cellAlign")
devtoolsDepp.pkgName <- c("MOVICS","dyngen","scvelo","dyno","GENIE3bis","cellAlign")


# Check and install missing R packages
depp.new<-depp[!(depp%in%installed.packages())]
if (length(depp.new)) {
  install.packages(depp.new, repos='http://cran.us.r-project.org', Ncpus = 4)
}

packageurl <- "https://cran.r-project.org/src/contrib/Archive/heatmap.plus/heatmap.plus_1.3.tar.gz"
install.packages(packageurl, repos=NULL, type="source", Ncpus = 4)

# Check and install missing Bioconductor packages
BioDepp.new<-BioDepp[!(BioDepp%in%installed.packages())]
if (length(BioDepp.new)) {
  if (!requireNamespace("BiocManager", quietly = TRUE))
    install.packages("BiocManager", repos='http://cran.us.r-project.org', Ncpus = 4)
  BiocManager::install(BioDepp, type="source", Ncpus = 4)
}

# Check and install missing devtools packages
devtoolsDepp.new<-devtoolsDepp[!(devtoolsDepp.pkgName%in%installed.packages())]
if (length(devtoolsDepp.new)) {
    devtools::install_github(devtoolsDepp.new)
}
