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
library(ggiraphExtra)
library(sjPlot)
library(sjmisc)
library(sjlabelled)
library(caret)
library(Metrics)

# Define server logic required to draw a histogram
shinyServer(function(input, output, session) {
    
    carData <- read_fwf(file="auto-mpg.data",col_positions = fwf_empty("auto-mpg.data"))
    carData <- carData %>% mutate(X9=as.numeric(substr(carData$X8,1,1)))
    carData$X8 <- sapply(strsplit(sapply(strsplit(carData$X8, "\""), "[", 2), " "), "[", 1)
    colnames(carData) <- c("mpg","cylinders","displacement","horsepower","weight","acceleration","model_year","car_make","origin")
    carData <- filter(carData,horsepower != "?")
    carData$horsepower <- as.double(carData$horsepower)
    
    ranges <- reactiveValues(x = NULL, y = NULL)
    
    getData <- reactive({
        newData <- switch(input$filterDropDown,
                          "cylinders" = filter(carData, cylinders >= input$filterRange[1] & cylinders <= input$filterRange[2]),
                          "displacement" = filter(carData, displacement >= input$filterRange[1] & displacement <= input$filterRange[2]),
                          "horsepower" = filter(carData, horsepower >= input$filterRange[1] & horsepower <= input$filterRange[2]),
                          "weight" = filter(carData, weight >= input$filterRange[1] & weight <= input$filterRange[2]),
                          "acceleration" = filter(carData, acceleration >= input$filterRange[1] & acceleration <= input$filterRange[2]),
                          "model_year" = filter(carData, model_year >= input$filterRange[1] & model_year <= input$filterRange[2]),
                          "origin" = filter(carData, origin >= input$filterRange[1] & origin <= input$filterRange[2])
        )
    })
    
    output$colorCheckBox <- renderUI({
        paste0("Color code an additional predictor layer on top of ", toupper(input$columnDropDown))
    })
    
    predScatterPlot <- function(){
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
    }
    
    predHistogram <- function(){
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
    }
    
    predZoomScatterPlot <- function(){
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
    }

    output$predictorScatterPlot <- renderPlot({
        predScatterPlot()
    })
    
    output$predictorHistogram <- renderPlot({
        predHistogram()
    })
    
    
    output$zoomScatterPlot <- renderPlot({
        predZoomScatterPlot()
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
    
    output$downloadPlot <- downloadHandler(
        filename = function(){
            paste0(input$pngPlotDropDown,str_replace_all(Sys.time(),":","_"),".png")
            },
        content = function(file) {
            ggsave(file, switch(input$pngPlotDropDown,
                                "ScatterPlot" = predScatterPlot(),
                                "Zoom" = predZoomScatterPlot(),
                                "Histogram" = predHistogram()),
                   width = 16, height = 12)
        }
        )
    
    #server function generates a table based on the filtered values    
    output$rawDataTable <- renderDataTable({
        #grab the filtered data set
        getData()
    })
    
    observe({updateSliderInput(session, "filterRange", min = min(carData %>% select(input$filterDropDown)), max = max(carData %>% select(input$filterDropDown)), value = c(min(carData %>% select(input$filterDropDown)),max(carData %>% select(input$filterDropDown))))})
    
    output$downloadData <- downloadHandler(
        filename = function() {
            paste0("CarMPG_FileretedOn_",input$filterDropDown,".csv")
        },
        content = function(file) {
            write.csv(getData(), file, row.names = FALSE)
        }
    )
    
    getCreatedFormula <- function(){
        str_remove_all(paste0("mpg ~ ",input$glm1DropDown,input$symb1DropDown,input$glm2DropDown,input$symb2DropDown,input$glm3DropDown,input$symb3DropDown,input$glm4DropDown),"none")
    }
    
    output$createdFormula <- renderUI({
        h4(paste0("Formula: ",getCreatedFormula()))
    })
    
    custModelError = ""
    
    createCustomModel <- eventReactive(input$createGlmButton, {
        custModelError = ""
        glm(formula = getCreatedFormula(), data = carData, family = input$familyDropDown)
    })
    
    output$customModelSummary <- renderUI({
        tryCatch({
            custModel <- tab_model(createCustomModel(), CSS = list(
                css.depvarhead = 'color: red;',
                css.centeralign = 'text-align: left;', 
                css.firsttablecol = 'font-weight: bold;', 
                css.summary = 'color: blue;'
            ))
            HTML(custModel$page.complete)
        }, error=function(e) {
            custModelError = "Please input a valide formula"
        }
        )
    })
    
    observe({updateTextInput(session, "custModelSummaryText", value = custModelError)})
    
    output$customModelPlot <- renderPlot({
        try(
            plot_model(createCustomModel())
        )
    })
    
    output$customLinearModelPlot <- renderPlot({
        try(
            ggPredict(createCustomModel())
        )
    })
    
    compareModelError = ""
    
    createCompareModels <- eventReactive(input$compareGlmsButton, {
        compareModelError = ""
        model1 <- glm(formula = input$formulaInput1, data = carData, family = input$family1DropDown)
        model2 <- glm(formula = input$formulaInput2, data = carData, family = input$family2DropDown)
        if(input$family3DropDown == "none") {
            list(model1, model2)
        } else {
            model3 <- glm(formula = input$formulaInput3, data = carData, family = input$family3DropDown)
            list(model1, model2, model3)
        }
    })
    
    output$compareModelSummary <- renderUI({
        tryCatch({
            compareModels <- tab_model(createCompareModels(),   CSS = list(
                css.depvarhead = 'color: red;',
                css.centeralign = 'text-align: left;', 
                css.firsttablecol = 'font-weight: bold;', 
                css.summary = 'color: blue;'
            ))
            HTML(compareModels$page.complete)
        }, error=function(e) {
            compareModelError = "Please input a valide formula"
        }
        )
    })
    
    observe({updateTextInput(session, "compareModelSummaryText", value = compareModelError)})
    
    output$compareModelPlot <- renderPlot({
        try(
            plot_models(createCompareModels())
        )
    })
    
    getCreatedTreeFormula <- function(){
        str_remove_all(paste0("mpg ~ ",input$tree1DropDown,input$tSymb1DropDown,input$tree2DropDown,input$tSymb2DropDown,input$tree3DropDown),"none")
    }
    
    output$createdTreeFormula <- renderUI({
        h4(paste0("Formula: ",getCreatedTreeFormula()))
    })
    
    custTreeModelError = ""
    
    createCustomTreeModel <- eventReactive(input$createTreeButton, {
        custTreeModelError = ""
        rpartGrid = expand.grid(.cp = seq(as.double(input$cpFromInput),as.double(input$cpToInput),as.double(input$cpSeqInput)))
        regTreeFit <- fitTree(getCreatedTreeFormula(),"rpart",rpartGrid)
    })
    
    fitTree <- function(formulaInput,treeMethod,grid) {
        controlTraining <- trainControl(method = "repeatedcv", number = 10)
        TreeFit <- train(form = formula(formulaInput), data = carData, method = treeMethod, trControl=controlTraining , preProcess = c("center", "scale"), tuneGrid = grid)
        return (TreeFit)
    }
    
    observe({updateTextInput(session, "custTreeModelText", value = custTreeModelError)})
    
    output$regressionTreePlot <- renderPlot({
        tryCatch({
            plot(createCustomTreeModel())
        }, error=function(e) {
            custTreeModelError = "Please input a valide tree formula"
        }
        )
    })
    
    boostedTreeModelError = ""
    
    createBoostedTreeModel <- eventReactive(input$boostedTreeButton, {
        boostedTreeModelError = ""
        gbmGrid <- expand.grid(interaction.depth = as.double(input$interactionFromInput):as.double(input$interactionToInput),
                               n.trees = seq(as.double(input$nTreesRange[1]), as.double(input$nTreesRange[2]), 10),
                               n.minobsinnode = as.double(input$minobsinnodeInput),
                               shrinkage = c(as.double(input$shrinkFromInput),as.double(input$shrinkToInput),as.double(input$shrinkToInput)))
        boostedTreeFit <- fitTree(input$boostedFormulaInput,"gbm",gbmGrid)
    })
    
    observe({updateTextInput(session, "boostedTreeModelText", value = boostedTreeModelError)})
    
    output$boostedTreePlot <- renderPlot({
        tryCatch({
            plot(createBoostedTreeModel())
        }, error=function(e) {
            boostedTreeModelError = "Please input a valide tree formula"
        }
        )
    })
    
    getPredictionFormula <- function(){
        if(input$predictChooseDropDown == "Build model"){
            predictFormula = paste0("mpg ~ ",input$predict1DropDown,input$preSymb1DropDown,input$predict2DropDown,input$preSymb2DropDown,input$predict3DropDown)
        } else {
            predictFormula = input$predictFormulaInput
        }
        return(predictFormula)
    }
    
    performPrediction <- function(){
        train <- sample(1:nrow(carData), size = nrow(carData)*(1-(as.double(input$testAmountInput)/100)))
        test <- dplyr::setdiff(1:nrow(carData), train)
        carDataTrain <- carData[train, ]
        carDataTest <- carData[test, ]
        predictFormula <- getPredictionFormula()
        currentModel <- glm(formula = predictFormula, data = carDataTrain, family = input$familyPredictDropDown)
        currentPrediction <- predict(currentModel, newdata = dplyr::select(carDataTest, -mpg))
        print(AIC(currentModel))
        print(BIC(currentModel))
        plot(currentPrediction)
        points(carDataTrain$mpg, bg='blue', pch=21)
        points(currentPrediction, bg='red', pch=21)
        legend("topright", legend=c("Predicted Points", "Test Points"),
               col=c("red", "blue"), pch=21, cex=1)
    }
    
    output$predictionPlot <- renderPlot({
        performPrediction()
    })

})
