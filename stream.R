#!/usr/bin/env Rscript
# Copyright 2014 Jason A. French

# Check dependencies
if(suppressMessages(!require(lubridate))){
  install.packages('lubridate', repos="http://cran.rstudio.com/")
  library(lubridate)
}
if(suppressMessages(!require(optparse))){
  install.packages('optparse', repos="http://cran.rstudio.com/")
  library(optparse)
}

# Parse option list
option_list <- list(
  make_option(c("-t", "--time"), 
              help = "Time as '15:00'"),
  make_option(c("--server", "-s"), 
              help = "RTMP server address"),
  make_option(c("-f", "--framerate"),
              help = "Desired output framerate"))
opt <- parse_args(OptionParser(option_list = option_list), positional_arguments = TRUE)

if('framerate' %in% names(opt$options) == TRUE){
  framerate <- paste('-r', opt$options$framerate)
} else {
  # Otherwise use native framerate
  framerate <- ""
}

# Print usage if no movie given
if(length(opt$args) == 0 || 'args' %in% names(opt) == FALSE){
  cat(paste("Usage:  stream.R --time 15:00 movie.avi"))
}

# Check that movies exist
lapply(opt$args,FUN = function(x){
  if(file.access(x) == -1){
    stop(sprintf("Specified file %s does not exist", x))
  }
})

# Check ffmpeg
ffmpeg.loc <- Sys.which('ffmpeg')
if(ffmpeg.loc == ""){
  stop('Please install ffmpeg with support for RTMP and fdk-aac.')
}


file <- normalizePath(path = opt$args[1])

# ffmpeg command
ffmpeg <- paste(ffmpeg.loc, "-re -i", file, "-c:v libx264",
                "-vf scale=640:-1", "-preset fast", "-tune zerolatency",
                "-crf 30", framerate, "-c:a libfdk_aac", "-profile:a aac_he",
                "-b:a 64k", "-f flv", opt$options$server)

if('time' %in% names(opt$options) == TRUE){
  # Get delay in seconds for sleep
  delay <- difftime(time1 = as.POSIXct(as.character(opt$options$time), format="%H:%M"), 
                    time2 = now(),
                    units = 'secs')
  command <- paste("screen", Sys.which('sleep'), as.integer(delay), "&&", ffmpeg)
} else {
  command <- paste("screen", ffmpeg)
}

system(command,intern = FALSE, minimized = TRUE, invisible = TRUE)