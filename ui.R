#
#   Author: Evan Elms
#   Date: 7/16/2019
#

library(shiny)
library(shinydashboard)

dashboardPage(skin="green",
              dashboardHeader(title="Project 3: Autmobile MPG Data Analysis",titleWidth=750),
              
              dashboardSidebar(sidebarMenu(
                menuItem("About", tabName = "about", icon = icon("archive")),
                menuItem("Data Exploration", tabName = "data", icon = icon("database")),
                menuItem("Modeling", tabName = "model", icon = icon("chart-line"))
              )),
              
              dashboardBody(
                tabItems(
                  tabItem(tabName = "about",
                          fluidRow(
                            withMathJax(),
                            column(12,
                                   tabsetPanel(
                                     tabPanel("About this app!",
                                              box(background="blue",width=12,
                                                  h4("This application is used to perform data analysis and statistical learning methods on the automobile MPG data set provided by UC Irvine Machine Learning <https://archive.ics.uci.edu/ml/datasets/Auto+MPG>. There are three sections to this application with each section having a series of tabs. 
                                                            ")
                                              ),
                                              box(background="blue",width=12,
                                                  h4("About section gives an overview of the dataset and column under the \"About Data\" and \"About Columns\" tabs."                                                              )
                                              ),
                                              box(background="blue",width=12,
                                                  h4("Data Exploration section allows for data analysis and summaries under the \"Data Summaries\" and \"Raw Data\" tabs. On the left hand side, the user can filter the type of data being displayed. In this section the user can also export any of the graphs or filtered data set. 
                                                            ")
                                              ),
                                              box(background="blue",width=12,
                                                  h4("Modeling section has \"Supervised Learning\" and \"Unsupervised Learning\" tabs that allow the user to explore different models for predicting the MPG of an autombile. The final tab \"Prediction\" allows the user to create a custom model for predicting MPG. 
                                                              ")
                                              )
                                     ),
                                     tabPanel("About the data",
                                              box(background="blue",width=12,
                                                  h4("The data set auto-mpg <https://archive.ics.uci.edu/ml/machine-learning-databases/auto-mpg/> is a collection of 398 car observations that measure various components that may or may not impact the fuel milage of the vehicle. The data set was first used in 1983 that focused on various cars built between 1970 and 1982. The response for this data set is miles per gallon (or how much fuel conspution a vehcile uses in city driving) with eight predicors. Among these predictors, three are discrete while the other five are continuous. In the link earlier, there is the original data set but there were 8 unknown values in the MPG column so for our application will be using the modified version that is maintained by Carnegie Mellon University. 
                                                          ")
                                              )
                                     ),
                                     tabPanel("About the columns",
                                              box(background="blue",width=12,
                                                  h4("Below is a description of each column in the data set:"),
                                                  h4("MPG - measurement of how many miles per gallon a vehicle can achieve"),
                                                  h4("CYLINDERS - number of cylinders the engine contains; a common example is a V8 which has 8 cylinders"),
                                                  h4("DISPLACEMENT - how much area the cylinders have to burn the gas in the engine block"),
                                                  h4("HORSEPOWER - numeric value on how much power is created by the vehicle"),
                                                  h4("WEIGHT - how heavy is the vehicle"),
                                                  h4("ACCELERATION - how quickly can the vehicle progress from a still position"),
                                                  h4("MODEL YEAR - year the vehicle was made"),
                                                  h4("ORIGIN - location where the car was engineered; 1 = American, 2 = German, 3 = Japanese"),
                                                  h4("CAR NAME - the model name and title of each vehicle")
                                              ),
                                              box(background="red",width=12,
                                                  h4("Note: For grouping methods we will split the car name field into make and model on the first space of each observation. Example: car make = \"Ford\" and car model = \"Mustang\""),
                                                  h4("CAR MAKE - brand name of the vehicle"),
                                                  h4("CARE MODEL - model of the vehicle")
                                              )
                                     )
                                   )
                            )
                          )
                  ),
                  
                  tabItem(tabName = "data",
                          fluidRow(
                            #Show a plot of the prior    
                            column(12,
                                   tabsetPanel(
                                     tabPanel("Analysis",
                                              column(3,
                                                     box(width=12,title="Understanding each predictor and it's relationship to MPG",
                                                         selectizeInput("columnDropDown", "Select a predictor:", selected = "cylinders", choices = c("cylinders","displacement","horsepower","weight","acceleration","model_year","car_make","origin")),
                                                         checkboxInput("boxPlotCheckBox", h4("Add boxplot effect")),
                                                         checkboxInput("zoomCheckBox", h4("Zoom into plot (does not include boxplot effect)")),
                                                         checkboxInput("columnCheckBox", uiOutput("colorCheckBox")),
                                                         conditionalPanel(
                                                           condition = "input.columnCheckBox == true",
                                                           selectizeInput("colorDropDown", "Select a second predictor:", selected = "displacement", choices = c("cylinders","displacement","horsepower","weight","acceleration","model_year","car_make","origin"))
                                                         ),
                                                         selectizeInput("pngPlotDropDown", "Select a plot to save:", selected = "ScatterPlot", choices = c("ScatterPlot","Zoom","Histogram")),
                                                         downloadButton("downloadPlot", "Download Plot")
                                                     )
                                              ),
                                              column(9,
                                                  plotOutput("predictorScatterPlot",
                                                             brush = brushOpts(
                                                               id = "predict_brush",
                                                               resetOnNew = TRUE
                                                             )
                                                  ),
                                                  conditionalPanel(
                                                    condition = "input.zoomCheckBox == true",
                                                    plotOutput("zoomScatterPlot")
                                                  ),
                                                  plotOutput("predictorHistogram")
                                              )
                                     ), #end tab panel
                                     tabPanel("View the data", 
                                              column(3,
                                                     selectizeInput("filterDropDown", "Select a predictor to filter on:", selected = "cylinders", choices = c("cylinders","displacement","horsepower","weight","acceleration","model_year","origin")),
                                                     sliderInput("filterRange", "Range:",
                                                                 min = 1, max = 1000,
                                                                 value = c(1,8)),
                                                     downloadButton("downloadData", "Download Data")
                                              ),
                                              column(9,
                                                     dataTableOutput("rawDataTable")
                                              )
                                     )
                                   ) #end tab set
                            ) #end column
                          ) #end fluidrow
                  ),
                  tabItem(tabName = "model",
                          fluidRow(
                            column(12,
                                   tabsetPanel(
                                     tabPanel("Generalized Linear Model",
                                              column(3,
                                                box(width=12,title="Create a generalized linear model of your choice",
                                                    selectizeInput("glmChooseDropDown", "Either build a model or input your own formula:", selected = "Choose one!", choices = c("Choose one!","Build model","Input formula")),
                                                    conditionalPanel(
                                                      condition = "input.glmChooseDropDown == \"Build model\"",
                                                      h3("You can build a model up to 4 predictors then press create!"),
                                                      selectizeInput("glm1DropDown", "Select predictor 1:", selected = "cylinders", choices = c("cylinders","displacement","horsepower","weight","acceleration","model_year","car_make","origin")),
                                                      selectizeInput("symb1DropDown", "Select symbol 1:", selected = " ", choices = c("","none","+",":","*")),
                                                      selectizeInput("glm2DropDown", "Select predictor 2:", selected = " ", choices = c("","none","cylinders","displacement","horsepower","weight","acceleration","model_year","car_make","origin")),
                                                      selectizeInput("symb2DropDown", "Select symbol 2:", selected = " ", choices = c("","none","+",":","*")),
                                                      selectizeInput("glm3DropDown", "Select predictor 3:", selected = " ", choices = c("","none","cylinders","displacement","horsepower","weight","acceleration","model_year","car_make","origin")),
                                                      selectizeInput("symb3DropDown", "Select symbol 3:", selected = " ", choices = c("","none","+",":","*")),
                                                      selectizeInput("glm4DropDown", "Select predictor 4:", selected = " ", choices = c("","none","cylinders","displacement","horsepower","weight","acceleration","model_year","car_make","origin")),
                                                      selectizeInput("familyDropDown", "Select a family:", selected = "gaussian", choices = c("binomial","gaussian","Gamma","inverse.gaussian","poisson","quasi","quasibinomial","quasipoisson")),
                                                      uiOutput("createdFormula"),
                                                      actionButton("createGlmButton", "Create model")
                                                    ),
                                                    conditionalPanel(
                                                      condition = "input.glmChooseDropDown == \"Input formula\"",
                                                      h3("You can compare upto 3 different generalized linear models (must include response)"),
                                                      textInput("formulaInput1","Formula 1:",value = "mpg ~ cylinders"),
                                                      selectizeInput("family1DropDown", "Select a family for formula 1:", selected = "gaussian", choices = c("binomial","gaussian","Gamma","inverse.gaussian","poisson","quasi","quasibinomial","quasipoisson")),
                                                      textInput("formulaInput2","Formula 2:", value = "mpg ~ weight"),
                                                      selectizeInput("family2DropDown", "Select a family for formula 2:", selected = "gaussian", choices = c("binomial","gaussian","Gamma","inverse.gaussian","poisson","quasi","quasibinomial","quasipoisson")),
                                                      textInput("formulaInput3","Formula 3:", value = ""),
                                                      selectizeInput("family3DropDown", "Select a family for formula 3:", selected = "none", choices = c("none","binomial","gaussian","Gamma","inverse.gaussian","poisson","quasi","quasibinomial","quasipoisson")),
                                                      actionButton("compareGlmsButton", "Compare models")
                                                    )
                                                )
                                              ),
                                              column(9,
                                                     conditionalPanel(
                                                       condition = "input.glmChooseDropDown == \"Build model\"",
                                                       textOutput("custModelSummaryText"),
                                                       htmlOutput("customModelSummary"),
                                                       plotOutput("customModelPlot"),
                                                       plotOutput("customLinearModelPlot")
                                                     ),
                                                     conditionalPanel(
                                                       condition = "input.glmChooseDropDown == \"Input formula\"",
                                                       textOutput("compareModelSummaryText"),
                                                       htmlOutput("compareModelSummary"),
                                                       plotOutput("compareModelPlot")
                                                     )
                                              )
                                     ),
                                     tabPanel("Tree Model",
                                              column(3,
                                                     box(width=12, title = "Create either a Regression Tree or Boosted Tree",
                                                         selectizeInput("treeChooseDropDown", "Select a tree method:", selected = "Choose one!", choices = c("Choose one!","Regression Tree","Boosted Tree")),
                                                         conditionalPanel(
                                                           condition = "input.treeChooseDropDown == \"Regression Tree\"",
                                                           h3("You can build a tree with up to 3 predictors then press create!"),
                                                           selectizeInput("tree1DropDown", "Select predictor 1:", selected = "cylinders", choices = c("cylinders","displacement","horsepower","weight","acceleration","model_year","car_make","origin")),
                                                           selectizeInput("tSymb1DropDown", "Select symbol 1:", selected = " ", choices = c("","none","+",":","*")),
                                                           selectizeInput("tree2DropDown", "Select predictor 2:", selected = " ", choices = c("","none","cylinders","displacement","horsepower","weight","acceleration","model_year","car_make","origin")),
                                                           selectizeInput("tSymb2DropDown", "Select symbol 2:", selected = " ", choices = c("","none","+",":","*")),
                                                           selectizeInput("tree3DropDown", "Select predictor 3:", selected = " ", choices = c("","none","cylinders","displacement","horsepower","weight","acceleration","model_year","car_make","origin")),
                                                           uiOutput("createdTreeFormula"),
                                                           h3("Complexity Parameter"),
                                                           textInput("cpFromInput","From:",value = "0"),
                                                           textInput("cpToInput","To:",value = "0.3"),
                                                           textInput("cpSeqInput","By sequence of:",value = "0.01"),
                                                           actionButton("createTreeButton", "Create tree")
                                                         ),
                                                         conditionalPanel(
                                                           condition = "input.treeChooseDropDown == \"Boosted Tree\"",
                                                           h4("You can view and change the complexity of the boosted tree with the attribues below"),
                                                           textInput("boostedFormulaInput","Formula:",value = "mpg ~ cylinders*displacement"),
                                                           h4("Interaction Depth"),
                                                           textInput("interactionFromInput","From:",value = "1"),
                                                           textInput("interactionToInput","To:",value = "10"),
                                                           sliderInput("nTreesRange", "Number of Trees:",
                                                                       min = 10, max = 100, value = c(30,50)),
                                                           textInput("minobsinnodeInput","Minobsinnode:",value = "20"),
                                                           h4("Shrinkage Rate"),
                                                           textInput("shrinkFromInput","From:",value = "0.01"),
                                                           textInput("shrinkToInput","To:",value = "0.1"),
                                                           textInput("shrinkSeqInput","By sequence of:",value = "0.5"),
                                                           actionButton("boostedTreeButton", "Create boosted tree")
                                                         )
                                                     )
                                              ),
                                              column(9,
                                                     conditionalPanel(
                                                       condition = "input.treeChooseDropDown == \"Regression Tree\"",
                                                       textOutput("custTreeModelText"),
                                                       plotOutput("regressionTreePlot")
                                                     ),
                                                     conditionalPanel(
                                                       condition = "input.treeChooseDropDown == \"Boosted Tree\"",
                                                       textOutput("boostedTreeModelText"),
                                                       plotOutput("boostedTreePlot")
                                                     )
                                              )
                                     ),
                                     tabPanel("Predictions",
                                              column(3,
                                                     box(width=12,title="Create a model of your choice and see how it performs at predictions!",
                                                         selectizeInput("predictChooseDropDown", "Either build a model or input your own formula:", selected = "Build model", choices = c("Build model","Input formula")),
                                                         conditionalPanel(
                                                           condition = "input.predictChooseDropDown == \"Build model\"",
                                                           h3("You can build a model up to 3 predictors"),
                                                           selectizeInput("predict1DropDown", "Select predictor 1:", selected = "cylinders", choices = c("cylinders","displacement","horsepower","weight","acceleration","model_year","car_make","origin")),
                                                           selectizeInput("preSymb1DropDown", "Select symbol 1:", selected = " ", choices = c("","none","+",":","*")),
                                                           selectizeInput("predict2DropDown", "Select predictor 2:", selected = " ", choices = c("","none","cylinders","displacement","horsepower","weight","acceleration","model_year","car_make","origin")),
                                                           selectizeInput("preSymb2DropDown", "Select symbol 2:", selected = " ", choices = c("","none","+",":","*")),
                                                           selectizeInput("predict3DropDown", "Select predictor 3:", selected = " ", choices = c("","none","cylinders","displacement","horsepower","weight","acceleration","model_year","car_make","origin"))
                                                         ),
                                                         conditionalPanel(
                                                           condition = "input.predictChooseDropDown == \"Input formula\"",
                                                           textInput("predictFormulaInput","Formula:",value = "mpg ~ cylinders*displacement")
                                                         ),
                                                         selectizeInput("familyPredictDropDown", "Select a family:", selected = "gaussian", choices = c("binomial","gaussian","Gamma","inverse.gaussian","poisson","quasi","quasibinomial","quasipoisson")),
                                                         textInput("testAmountInput","What percent of data do you want to use for testing:",value = "20"),
                                                         actionButton("createPredictButton", "Create a prediction")
                                                     )
                                              ),
                                              column(9,
                                                h3("output")
                                              )
                                              
                                     )
                                   )
                            )
                          )
                    
                  )
                )
              )
)
