library(shiny)

# Define UI for application that draws a histogram
shinyUI(fluidPage(
  navbarPage("streamR",
             tabPanel("Home", icon = icon("home")),
             tabPanel("Stream", icon = icon("play"))

  ),
  
  # Sidebar with a slider input for the number of bins
  sidebarLayout(
    sidebarPanel(
      tabsetPanel(
        tabPanel(title = "Video", icon = icon("video-camera"),
                 selectInput("bitrate_choice", label = "Choose Bitrate Control", 
                             choices = c("Constant Rate Factor" = "crf", "Average Bitrate" = "abr"), selected = "crf",
                             multiple = FALSE),
                 uiOutput("ui_bitrate"),
                 sliderInput("framerate", label = "Desired Framerate", value = 15, min = 5, max = 30),
                 numericInput("width", label = "Scale Width", value = 640),
                 submitButton(text = "Apply Changes", icon = icon("floppy-o"))),
        tabPanel(title = "Server", icon = icon("hdd-o"),
                 textInput("rtmp_server", label = "RTMP Host", value = "rtmp://"),
                 passwordInput("rtmp_password", label = "RTMP Server Password"),
                 textInput("base_dir", label = "Base Directory for Movies", value = "/Volumes/"),
                 div(style="display:inline-block",submitButton(text = "Start", icon = icon("play"))),
                 div(style="display:inline-block",submitButton(text = "Restart", icon = icon("refresh")))))
    ),
    
    # Show a plot of the generated distribution
    mainPanel(
      tabsetPanel(
        tabPanel(title = "Movies", icon = icon("film"),
                 dataTableOutput("movies_list")),
        tabPanel(title = "Log", icon = icon("list"),
                 textOutput("ffmpeg_loc")),
        tabPanel(title = "Stats", icon = icon("bar-chart"),
                 selectInput("stats_plot",label = "Choose the graph:",choices = c("Movie Duration Histogram"="duration")),
                 plotOutput("stats_plot"))
      )
    )
  )
))
