#
#   Author: Evan Elms
#   Date: 7/16/2019
#   Description: server side of application used to analyze car data and find which predictors best match with MPG
#       The server side performs all the calculations and transformations provided by the user and renders 
#       all plots and text for the following tabs:
#         1. Intro - none transformations on this tab
#         2. data analysis - graphs used to compare each predictor to the MPG along with viewing the raw data
#         3. Modeling - creates and calculates all models in the tab
#

library(shiny)
library(shinydashboard)
library(tidyverse)
library(ggiraphExtra)
library(sjPlot)
library(sjmisc)
library(sjlabelled)
library(caret)
library(rpart)
library(rpart.plot)
library(collapsibleTree)

# Define server logic required to perform data anlaysis and charts/plots for the ui
shinyServer(function(input, output, session) {
    
    #car data is read into R and transformed according to pre-defined conditions
    carData <- read_fwf(file="auto-mpg.data",col_positions = fwf_empty("auto-mpg.data"))
    carData <- carData %>% mutate(X9=as.numeric(substr(carData$X8,1,1)))
    carData$X8 <- sapply(strsplit(sapply(strsplit(carData$X8, "\""), "[", 2), " "), "[", 1)
    colnames(carData) <- c("mpg","cylinders","displacement","horsepower","weight","acceleration","model_year","car_make","origin")
    carData <- filter(carData,horsepower != "?")
    carData$horsepower <- as.double(carData$horsepower)
    
    #range used for the zoom function, is set to null as not being used yet but must be instantiated
    ranges <- reactiveValues(x = NULL, y = NULL)
    
    #get data returns filtered data used in the view data tab
    #used a switch statement as the filter was not happy with the input$filter values
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
    
    #dynamic UI piece used to inform the user what color layer they will be adding to the existing predictor
    output$colorCheckBox <- renderUI({
        paste0("Color code an additional predictor layer on top of ", toupper(input$columnDropDown))
    })
    
    #scatter plot function used to build the scatter plot based on the user's inputs
    #again had to use a series of switch cases as ggplot did not like the input methods
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
        #if the user wants to add a color layer for an additional predictor, the if statement will handle it
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
        #if the user wants a box plot on top of the existing plot
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
    
    #numeric count histogram used to show the user the categories in each predictor
    #and how many are in each category, also used a switch statement again 
    #due to challenges with input commands
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
    
    #zoom scatter plat created when the user highlights a certain area in the main graph
    #managed by a series of switch cases and if statements to handle the multiple user inputs
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

    #render function used to send the plot back to the UI
    output$predictorScatterPlot <- renderPlot({
        predScatterPlot()
    })
    
    #render function used to send the plot back to the UI
    output$predictorHistogram <- renderPlot({
        predHistogram()
    })
    
    #render function used to send the plot back to the UI
    output$zoomScatterPlot <- renderPlot({
        predZoomScatterPlot()
    })
    
    #observe function used to adjust the x and y coordinates as the user changes the zoom
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
    
    #download plot function allows the user to select which plot they want to save 
    #and then save the final piece to their local machine
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
    
    #observe function is used update the slider on the filter page based
    #on which predictor the user is filtering on
    observe({updateSliderInput(session, "filterRange", min = min(carData %>% select(input$filterDropDown)), max = max(carData %>% select(input$filterDropDown)), value = c(min(carData %>% select(input$filterDropDown)),max(carData %>% select(input$filterDropDown))))})
    
    #download data function allows the user to save the filtered data
    output$downloadData <- downloadHandler(
        filename = function() {
            paste0("CarMPG_FileretedOn_",input$filterDropDown,".csv")
        },
        content = function(file) {
            write.csv(getData(), file, row.names = FALSE)
        }
    )

    #function obtains the order for the interactive dendogram
    getHierarchy <- function(){
        hierarchyList <- c(input$dendo1DropDown,input$dendo2DropDown,input$dendo3DropDown,input$dendo4DropDown,input$dendo5DropDown,input$dendo6DropDown)
        finalHierarchy <- hierarchyList[!hierarchyList == "none"]
        return(finalHierarchy)
    }
    
    #output of the interactive dendogram
    output$interactiveDendogram <- renderCollapsibleTree({
        collapsibleTree(carData, getHierarchy())
    })
    
    #functinon used to create the formula the user builds for the GLM models
    getCreatedFormula <- function(){
        str_remove_all(paste0("mpg ~ ",input$glm1DropDown,input$symb1DropDown,input$glm2DropDown,input$symb2DropDown,input$glm3DropDown,input$symb3DropDown,input$glm4DropDown),"none")
    }
    
    #UI text used to show the user their current full formula
    output$createdFormula <- renderUI({
        h4(paste0("Formula: ",getCreatedFormula()))
    })
    
    #error string used to inform the user if their formula is not correct
    custModelError = ""
    
    #event button based on when the user clicks the create glm
    #used to create the glm model
    createCustomModel <- eventReactive(input$createGlmButton, {
        custModelError = ""
        glm(formula = getCreatedFormula(), data = carData, family = input$familyDropDown)
    })
    
    #output on how well the custom model performed in explaining the variance in MPG
    #if the user inputs a bad formula, then the trycatch will inform them
    output$customModelSummary <- renderUI({
        tryCatch({
            custModel <- tab_model(createCustomModel(), CSS = list(
                css.depvarhead = 'color: red;',
                css.centeralign = 'text-align: left;', 
                css.firsttablecol = 'font-weight: bold;', 
                css.summary = 'color: blue;'
            ))
            HTML(custModel$page.complete)
        }, warning = function(w) {
            custModelError = "Please input a valide formula"
        }, error=function(e) {
            custModelError = "Please input a valide formula"
        }
        )
    })
    
    #observe function used to update the user if their formula is bad
    observe({updateTextInput(session, "custModelSummaryText", value = custModelError)})
    
    #plot function used to return the final plot created by the user to the UI
    output$customModelPlot <- renderPlot({
        try(
            plot_model(createCustomModel())
        )
    })
    
    #a linear plot that is sometimes displayed to the user if their model if linear
    output$customLinearModelPlot <- renderPlot({
        try(
            ggPredict(createCustomModel())
        )
    })
    
    #error sting used to inform the user if their formula is bad
    compareModelError = ""
    
    #event button that generates a model when the user clicks create
    #can build up to 3 models and uses an if else statement depending on the user
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
    
    #UI piece displays how the models did in comparison to each other
    #if any of the formulas are bad then the user is informed in the trycatch
    output$compareModelSummary <- renderUI({
        tryCatch({
            compareModels <- tab_model(createCompareModels(),   CSS = list(
                css.depvarhead = 'color: red;',
                css.centeralign = 'text-align: left;', 
                css.firsttablecol = 'font-weight: bold;', 
                css.summary = 'color: blue;'
            ))
            HTML(compareModels$page.complete)
        }, warning = function(w) {
            compareModelError = "Please input a valide formula"
        }, error=function(e) {
            compareModelError = "Please input a valide formula"
        }
        )
    })
    
    #observe function used to update the user if their formula was bad
    observe({updateTextInput(session, "compareModelSummaryText", value = compareModelError)})
    
    #plot all the models in their estimates to compare and show the user their differences
    output$compareModelPlot <- renderPlot({
        try(
            plot_models(createCompareModels())
        )
    })
    
    #function obtains the formula for the tree models that the user built
    getCreatedTreeFormula <- function(){
        str_remove_all(paste0("mpg ~ ",input$tree1DropDown,input$tSymb1DropDown,input$tree2DropDown,input$tSymb2DropDown,input$tree3DropDown),"none")
    }
    
    #UI output text shows the user what their overall formula appears like
    output$createdTreeFormula <- renderUI({
        h4(paste0("Formula: ",getCreatedTreeFormula()))
    })
    
    #string used to inform the user if their formula is bad
    custTreeModelError = ""
    
    #event button that beings creating a tree model based on the users inputs
    createCustomTreeModel <- eventReactive(input$createTreeButton, {
        custTreeModelError = ""
        rpartGrid = expand.grid(.cp = seq(as.double(input$cpFromInput),as.double(input$cpToInput),as.double(input$cpSeqInput)))
        regTreeFit <- fitTree(getCreatedTreeFormula(),"rpart",rpartGrid)
    })
    
    #fit tree function used to build the trees and return the finally created tree
    fitTree <- function(formulaInput,treeMethod,grid) {
        controlTraining <- trainControl(method = "repeatedcv", number = 10)
        TreeFit <- train(form = formula(formulaInput), data = carData, method = treeMethod, trControl=controlTraining , preProcess = c("center", "scale"), tuneGrid = grid)
        return (TreeFit)
    }
    
    #observe function updates the error string to inform the user if their formula is bad
    observe({updateTextInput(session, "custTreeModelText", value = custTreeModelError)})
    
    #return the plot of the tree to the UI to be diplayed to the user
    output$regressionFullTreePlot <- renderPlot({
        tryCatch({
            tree <- rpart(formula(getCreatedTreeFormula()), data=carData, cp=as.double(input$cpSetInput))
            rpart.plot(tree, box.palette="RdBu", shadow.col="gray", nn=TRUE)
        }, warning = function(w) {
            custTreeModelError = "Please input a valide tree formula"
        }, error=function(e) {
            custTreeModelError = "Please input a valide tree formula"
        })
    })
    
    #plot displays the complexity of CP in the regression tree
    output$regressionTreePlot <- renderPlot({
        tryCatch({
            plot(createCustomTreeModel())
        }, warning = function(w) {
            custTreeModelError = "Please input a valide tree formula"
        }, error=function(e) {
            custTreeModelError = "Please input a valide tree formula"
        }
        )
    })
    
    #boosted error string used to inform the user if their formula is bad
    boostedTreeModelError = ""
    
    #event button used to created the boosted tree based on the user's inputs and tuning parameters
    createBoostedTreeModel <- eventReactive(input$boostedTreeButton, {
        boostedTreeModelError = ""
        gbmGrid <- expand.grid(interaction.depth = as.double(input$interactionFromInput):as.double(input$interactionToInput),
                               n.trees = seq(as.double(input$nTreesRange[1]), as.double(input$nTreesRange[2]), 10),
                               n.minobsinnode = as.double(input$minobsinnodeInput),
                               shrinkage = c(as.double(input$shrinkFromInput),as.double(input$shrinkToInput),as.double(input$shrinkToInput)))
        boostedTreeFit <- fitTree(input$boostedFormulaInput,"gbm",gbmGrid)
    })
    
    #observe function updates the UI to inform the user if their formula is bad
    observe({updateTextInput(session, "boostedTreeModelText", value = boostedTreeModelError)})
    
    #plot is created of the tuning parameters used in the boosting tree method
    output$boostedTreePlot <- renderPlot({
        tryCatch({
            plot(createBoostedTreeModel())
        }, warning = function(w) {
            boostedTreeModelError = "Please input a valide tree formula"
        }, error=function(e) {
            boostedTreeModelError = "Please input a valide tree formula"
        }
        )
    })
    
    #string used to inform the user if their prediction formula is bad
    predictionModelError = ""
    
    #based on the user's input, the prediction formula is grabbed from either the tab windows
    getPredictionFormula <- function(){
        if(input$predictChooseDropDown == "Build model"){
            predictFormula = paste0("mpg ~ ",input$predict1DropDown,input$preSymb1DropDown,input$predict2DropDown,input$preSymb2DropDown,input$predict3DropDown)
        } else {
            predictFormula = input$predictFormulaInput
        }
        return(predictFormula)
    }
    
    #main prediction function that splits the data into training and test
    #performs a prediction on the model generated by the user
    #and plots the comparison between the predicted and actual
    performPrediction <- function(){
        predictionModelError = ""
        train <- sample(1:nrow(carData), size = nrow(carData)*(1-(as.double(input$testAmountInput)/100)))
        test <- dplyr::setdiff(1:nrow(carData), train)
        carDataTrain <- carData[train, ]
        carDataTest <- carData[test, ]
        predictFormula <- getPredictionFormula()
        currentModel <- glm(formula = predictFormula, data = carDataTrain, family = input$familyPredictDropDown)
        currentPrediction <- predict(currentModel, newdata = dplyr::select(carDataTest, -mpg))
        plot(currentPrediction)
        points(carDataTrain$mpg, bg='blue', pch=21)
        points(currentPrediction, bg='red', pch=21)
        legend("topright", legend=c("Predicted Points", "Test Points"),
               col=c("red", "blue"), pch=21, cex=1)
    }
    
    #final plot function used to display in the UI the predicted values in reference to the actual
    output$predictionPlot <- renderPlot({
        tryCatch({
            performPrediction()
        }, warning = function(w) {
            predictionModelError = "Please input a valide formula"
        }, error = function(e) {
            predictionModelError = "Please input a valide formula"
        })
    })
    
    #observe function used to inform the user if their formula is bad
    observe({updateTextInput(session, "predictionModelText", value = predictionModelError)})

})
