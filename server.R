library(shiny)
library(lubridate)
library(parallel)
library(ggplot2)

# Define server logic required to draw a histogram
shinyServer(function(input, output) {
  
  # Expression that generates a histogram. The expression is
  # wrapped in a call to renderPlot to indicate that:
  #
  #  1) It is "reactive" and therefore should re-execute automatically
  #     when inputs change
  #  2) Its output type is a plot
  output$ui_bitrate <- renderUI({
  switch(input$bitrate_choice,
         "crf" = {sliderInput("bitrate_control", label = NULL, value = 30, min = 1, max = 51)},
         "abr" = numericInput("bitrate_control", label = NULL, min = 100, value = 500))
  })
  output$ffmpeg_loc <- renderText(Sys.which('ffmpeg'))
  
  # Get locations
  executables <- Sys.which(c('ffprobe', 'ffmpeg'))
  
  # Duration Function
  get_duration <- function(file){
    ffprobe_duration <- paste(executables['ffprobe'],
                             " -v quiet -print_format compact=print_section=0:nokey=1:escape=csv -show_entries format=duration ",
                             '"', file, '"', sep = "")
    file_duration <- as.numeric(system(command = ffprobe_duration, intern = TRUE))
    return(file_duration)
  }
  get_resolution <- function(file){
    ffprobe_res <- paste(executables['ffprobe'],
                             " -v quiet -print_format compact=print_section=0:nokey=1:escape=csv -select_streams v:0 -show_entries stream=height,width ",
                             '"', file, '"', sep = "")
    file_resolution <- system(command = ffprobe_res, intern = TRUE)
    return(file_resolution)
  }
  
  build_movies_db <- function(base_dir){
    movies <- data.frame(Path=list.files(path = base_dir,
                                         pattern = "*.avi$|*.mkv$|*.mp4$|*.webm$",
                                         recursive = TRUE,
                                         ignore.case = TRUE,
                                         full.names = TRUE),
                         stringsAsFactors = FALSE,
                         row.names = NULL)
    movies$Movie <- list.files(path = base_dir, 
                               pattern = "*.avi$|*.mkv$|*.mp4$|*.webm$", 
                               full.names = FALSE,
                               recursive = TRUE,
                               ignore.case = TRUE,
                               include.dirs=FALSE)
    movies <- movies[!grepl(pattern = "sample.",x = movies$Movie),]
    movies$Seconds <- mclapply(X = movies$Path, FUN = get_duration, mc.cores = detectCores())
    movies$Duration <- round(seconds_to_period(movies$Seconds))
    save(movies, file = "movies.Rdata")
  }
  
  # Create Movies Database
  if(file.exists("movies.Rdata")){
    load(file = "movies.Rdata")
  } else {
    build_movies_db(base_dir = input$base_dir)
  }
  
  output$movies_list <- renderDataTable(subset(movies, select = c('Movie', 'Duration')),
                                        list(orderClasses = TRUE))
  output$stats_plot <- renderPlot(
    switch(input$stats_plot,
           "duration"={
             ggplot(data = movies, aes(x = as.numeric(Seconds)/60)) +
               geom_histogram(aes(fill = ..count..)) + 
               xlab('Runtime') +
               ylab('# of Movies') +
               ggtitle("Distribution of Runtimes") + 
               scale_fill_continuous("# of Movies")
           }))
})
