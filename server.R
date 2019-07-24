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
shinyServer(function(input, output, session) {
    
    carData <- read_fwf(file="auto-mpg.data",col_positions = fwf_empty("auto-mpg.data"))
    carData <- carData %>% mutate(X9=as.numeric(substr(carData$X8,1,1)))
    carData$X8 <- sapply(strsplit(sapply(strsplit(carData$X8, "\""), "[", 2), " "), "[", 1)
    colnames(carData) <- c("mpg","cylinders","displacement","horsepower","weight","acceleration","model_year","car_make","origin")
    
    ranges <- reactiveValues(x = NULL, y = NULL)
    
    output$colorCheckBox <- renderUI({
        paste0("Color code an additional predictor layer on top of ", toupper(input$columnDropDown))
    })

    output$predictorScatterPlot <- renderPlot({
        switch(input$columnDropDown,
               "cylinders" = g <- ggplot(carData, aes(x = cylinders, y = mpg)),
               "displacement" = g <- ggplot(carData, aes(x = displacement, y = mpg)),
               "horsepower" = g <- ggplot(carData, aes(x = horsepower, y = mpg)),
               "weight" = g <- ggplot(carData, aes(x = weight, y = mpg)),
               "acceleration" = g <- ggplot(carData, aes(x = acceleration, y = mpg)),
               "model_year" = g <- ggplot(carData, aes(x = model_year, y = mpg)),
               "car_make" = g <- ggplot(carData, aes(x = car_make, y = mpg)),
               "origin" = g <- ggplot(carData, aes(x = origin, y = mpg))
        )
        if(input$columnCheckBox){
            switch(input$colorDropDown,
                   "cylinders" = g <- g + geom_point(aes(col = cylinders)),
                   "displacement" = g <- g + geom_point(aes(col = displacement)),
                   "horsepower" = g <- g + geom_point(aes(col = horsepower)),
                   "weight" = g <- g + geom_point(aes(col = weight)),
                   "acceleration" = g <- g + geom_point(aes(col = acceleration)),
                   "model_year" = g <- g + geom_point(aes(col = model_year)),
                   "car_make" = g <- g + geom_point(aes(col = car_make)),
                   "origin" = g <- g + geom_point(aes(col = origin))
            )
        } else {
            g <- g + geom_point()
        }
        
        if(input$boxPlotCheckBox){
            switch(input$columnDropDown,
                   "cylinders" = g + geom_boxplot(aes(group = cut_width(cylinders, 1))) + geom_jitter(),
                   "displacement" = g + geom_boxplot(aes(group = cut_width(displacement, 50))) + geom_jitter(),
                   "weight" = g + geom_boxplot(aes(group = cut_width(weight, 500))) + geom_jitter(),
                   "acceleration" = g + geom_boxplot(aes(group = cut_width(acceleration, 2.5))) + geom_jitter(),
                   "model_year" = g + geom_boxplot(aes(group = cut_width(model_year, 1))) + geom_jitter(),
                   "origin" = g + geom_boxplot(aes(group = cut_width(origin, 1))) + geom_jitter(),
                   g + geom_boxplot() + geom_jitter()
            )
        } else {
            g + geom_jitter()
        }
        
    })
    
    output$predictorHistogram <- renderPlot({
        switch(input$columnDropDown,
               "cylinders" = g2 <- ggplot(carData, aes(x = cylinders)),
               "displacement" = g2 <- ggplot(carData, aes(x = displacement)),
               "horsepower" = g2 <- ggplot(carData, aes(x = horsepower)),
               "weight" = g2 <- ggplot(carData, aes(x = weight)),
               "acceleration" = g2 <- ggplot(carData, aes(x = acceleration)),
               "model_year" = g2 <- ggplot(carData, aes(x = model_year)),
               "car_make" = g2 <- ggplot(carData, aes(x = car_make)),
               "origin" = g2 <- ggplot(carData, aes(x = origin))
        )
        g2 + geom_bar()
    })
    
    
    output$zoomScatterPlot <- renderPlot({
        switch(input$columnDropDown,
               "cylinders" = g <- ggplot(carData, aes(x = cylinders, y = mpg)),
               "displacement" = g <- ggplot(carData, aes(x = displacement, y = mpg)),
               "horsepower" = g <- ggplot(carData, aes(x = horsepower, y = mpg)),
               "weight" = g <- ggplot(carData, aes(x = weight, y = mpg)),
               "acceleration" = g <- ggplot(carData, aes(x = acceleration, y = mpg)),
               "model_year" = g <- ggplot(carData, aes(x = model_year, y = mpg)),
               "car_make" = g <- ggplot(carData, aes(x = car_make, y = mpg)),
               "origin" = g <- ggplot(carData, aes(x = origin, y = mpg))
        )
        if(input$columnCheckBox){
            switch(input$colorDropDown,
                   "cylinders" = g <- g + geom_point(aes(col = cylinders)),
                   "displacement" = g <- g + geom_point(aes(col = displacement)),
                   "horsepower" = g <- g + geom_point(aes(col = horsepower)),
                   "weight" = g <- g + geom_point(aes(col = weight)),
                   "acceleration" = g <- g + geom_point(aes(col = acceleration)),
                   "model_year" = g <- g + geom_point(aes(col = model_year)),
                   "car_make" = g <- g + geom_point(aes(col = car_make)),
                   "origin" = g <- g + geom_point(aes(col = origin))
            )
        } else {
            g <- g + geom_point()
        }
        
        g + geom_jitter() + coord_cartesian(xlim = ranges$x, ylim = ranges$y, expand = FALSE)
        
    })
    
    observe({
        brush <- input$predict_brush
        if (!is.null(brush)) {
            ranges$x <- c(brush$xmin, brush$xmax)
            ranges$y <- c(brush$ymin, brush$ymax)
            
        } else {
            ranges$x <- NULL
            ranges$y <- NULL
        }
    })

})
