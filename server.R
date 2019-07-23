#
# This is the server logic of a Shiny web application. You can run the
# application by clicking 'Run App' above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(tidyverse)

# Define server logic required to draw a histogram
shinyServer(function(input, output) {
    
    carData <- read_fwf(file="auto-mpg.data",col_positions = fwf_empty("auto-mpg.data"))
    carData <- carData %>% mutate(X9=as.numeric(substr(carData$X8,1,1)))
    carData$X8 <- sapply(strsplit(sapply(strsplit(carData$X8, "\""), "[", 2), " "), "[", 1)
    colnames(carData) <- c("mpg","cylinders","displacement","horsepower","weight","acceleration","model year","car make","origin")

    output$distPlot <- renderPlot({

        # generate bins based on input$bins from ui.R
        x    <- faithful[, 2]
        bins <- seq(min(x), max(x), length.out = input$bins + 1)

        # draw the histogram with the specified number of bins
        hist(x, breaks = bins, col = 'darkgray', border = 'white')

    })

})
