#!/usr/bin/env Rscript
# Copyright 2014 Jason A. French

# Check dependencies
if (suppressMessages(!require(lubridate))) {
  install.packages("lubridate", repos = "http://cran.rstudio.com/")
  library(lubridate)
}
if (suppressMessages(!require(optparse))) {
  install.packages("optparse", repos = "http://cran.rstudio.com/")
  library(optparse)
}

# Parse option list
option_list <- list(make_option(c("-t", "--time"),
                                help = "Start time in 24-hour notation (15:00)"), 
                    make_option(c("--server", "-s"),
                                help = "RTMP server address"),
                    make_option(c("-f", "--framerate"), default = 15,
                                help = "Desired output framerate"),
                    make_option(c("--crf"), default = 30, 
                                help = "Desired Constant Rate Factor [default %default]"), 
                    make_option(c("--update"), default = FALSE,
                                help = "Update stream.R to /usr/local/bin/"))
opt <- parse_args(OptionParser(usage = "%prog [options] movie.avi", option_list = option_list), 
                  positional_arguments = TRUE)

update.streamR <- function(x) {
  # Check sudo
  if (Sys.getenv("USER") != "root") {
    stop("Please run the install function as root.")
  }
  system(command = "curl -O https://raw.githubusercontent.com/frenchja/streamR/master/stream.R /usr/local/bin/stream.R")
  system(command = "chmod +x /usr/local/bin/stream.R")
}

if ("update" %in% names(opt$options) == TRUE) {
  update.stream()
}

if ("framerate" %in% names(opt$options) == TRUE) {
  framerate <- paste("-r", opt$options$framerate)
}

# Print usage if no movie given
if (length(opt$args) == 0 || "args" %in% names(opt) == FALSE) {
  cat("Usage:  stream.R --server rtmp://yourserver.com movie.avi")
}

# Check that movies exist
lapply(opt$args, FUN = function(x) {
  if (file.access(x) == -1) {
    stop(sprintf("Specified file %s does not exist", x))
  }
})


# Extract film duration ffmpeg.duration <- paste('ffmpeg -i',
# opt$args[1], '2>&1 | grep Duration | sed 's/Duration: \(.*\),
# start/\1/g'') duration <- system(command = ffmpeg.duration, intern =
# TRUE)

log <- function(file){
  ffprobe.command <- paste("ffprobe -v quiet -print_format compact=print_section=0:nokey=1:escape=csv -show_entries format=duration",
                            file)
  film.duration <- as.numeric(system(command = ffprobe.command, intern = TRUE))
  film.duration.print <- round(seconds_to_period(film.duration), 0)
  cat("Movie: ", file, "\n",
      "Start Time: ", now(),
      "Duration: ", film.duration.print, "\n",
      "End Time: ", now() + film.duration,
      file = paste(as.Date(now()), ".log", sep = ""),
      append = TRUE)
}


# Check ffmpeg
ffmpeg.loc <- Sys.which("ffmpeg")
if (ffmpeg.loc == "") {
  stop("Please install ffmpeg with support for RTMP and fdk-aac.")
}

if ("args" %in% names(opt) == TRUE && length(opt$args) > 0) {
  file <- normalizePath(path = opt$args[1])
  # ffmpeg command
  ffmpeg <- paste(ffmpeg.loc, "-re -i", file, "-c:v libx264", "-vf scale=640:-1", 
                  "-preset fast", "-tune zerolatency", "-crf", opt$options$crf, framerate, 
                  "-c:a libfdk_aac", "-profile:a aac_he", "-b:a 64k", "-f flv", opt$options$server)
  log(file)
  if ("time" %in% names(opt$options) == TRUE) {
    # Get delay in seconds for sleep
    delay <- difftime(time1 = as.POSIXct(as.character(opt$options$time), 
                                         format = "%H:%M"), time2 = now(), units = "secs")
    command <- paste("screen", Sys.which("sleep"), as.integer(delay), 
                     "&&", ffmpeg)
  } else {
    command <- paste("screen", ffmpeg)
  }
  system(command, intern = FALSE, ignore.stdout = TRUE, ignore.stderr = TRUE)
}