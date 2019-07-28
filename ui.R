#
#   Author: Evan Elms
#   Date: 7/16/2019
#   Description: Application used to analyze car data and determine which predictors work best in calculating the
#     the miles per galon of a car. There are 3 tabs to this application
#         1. Intro - discussing the app and data
#         2. data analysis - tools that allow the user to explore the data through graphs and the raw data itself
#         3. Modeling - allows the user to fit GLMs and 2 tree models to the data through their own formulas
#

library(shiny)
library(shinydashboard)

#main dashboard
dashboardPage(skin="green",
              dashboardHeader(title="Project 3: Automobile MPG Data Analysis",titleWidth=750),
              
              #side bar items found the left hand side that can be hidden by user's request
              dashboardSidebar(sidebarMenu(
                menuItem("About", tabName = "about", icon = icon("archive")),
                menuItem("Data Exploration", tabName = "data", icon = icon("database")),
                menuItem("Modeling", tabName = "model", icon = icon("chart-line"))
              )),
              
              #main body where the user will interact with the tools and data
              dashboardBody(
                #a list of all the tab items found the side bar
                tabItems(
                  #first tab item is describing the application and data
                  tabItem(tabName = "about",
                          fluidRow(
                            withMathJax(),
                            column(12,
                                   tabsetPanel(
                                     tabPanel("About this app!",
                                              #divided the description into 4 boxes so the text didn't look endless
                                              box(background="green",width=12,
                                                  h4("This application is used to perform data analysis and statistical learning methods on the automobile MPG data set provided by ",a("UC Irvine Machine Learning", href="https://archive.ics.uci.edu/ml/datasets/Auto+MPG"), ". There are three sections to this application with each section having a series of tabs. 
                                                            ")
                                              ),
                                              box(background="green",width=12,
                                                  h4("About section gives an overview of the dataset and columns under the \"About the data\" and \"About the columns\" tabs."                                                              )
                                              ),
                                              box(background="green",width=12,
                                                  h4("Data Exploration section allows for data analysis and summaries under the \"Data Summaries\", \"Raw Data\", \"Dendogram\" tabs. On the left hand side, the user can filter the type of data being displayed. In this section the user can also export any of the graphs or filtered data set. 
                                                            ")
                                              ),
                                              box(background="green",width=12,
                                                  h4("Modeling section has \"Generalized Linear Models\" and \"Tree Model\" tabs that allow the user to explore different models for predicting the MPG of an autombile. The final tab \"Prediction\" allows the user to create a custom model for predicting MPG. 
                                                              ")
                                              )
                                     ),
                                     #description about where the data was located and the history of it
                                     tabPanel("About the data",
                                              box(background="green",width=12,
                                                  h4("The data set auto-mpg, found ", a("here", href="https://archive.ics.uci.edu/ml/machine-learning-databases/auto-mpg/"), ", is a collection of 398 car observations that measure various components that may or may not impact the fuel milage of the vehicle. The data set was first used in 1983 and focused on various cars built between 1970 and 1982. The response for this data set is miles per gallon (or how much fuel conspution a vehcile uses in city driving) with eight predictors. Among these predictors, three are discrete while the other five are continuous. In the link earlier, there is the original data set but there were eight unknown values in the MPG column so for our application will be using the modified version that is maintained by Carnegie Mellon University.")
                                              )
                                     ),
                                     #column descriptions and tranformation
                                     tabPanel("About the columns",
                                              box(background="green",width=12,
                                                  h4("Below is a description of each column in the data set:"),
                                                  h4("MPG - measurement of how many miles per gallon a vehicle can achieve"),
                                                  h4("CYLINDERS - number of cylinders the engine contains; a common example is a V8 which has 8 cylinders"),
                                                  h4("DISPLACEMENT - how much area the cylinders have to burn the gas in the engine block"),
                                                  h4("HORSEPOWER - numeric value on how much power is created by the vehicle"),
                                                  h4("WEIGHT - how heavy is the vehicle"),
                                                  h4("ACCELERATION - how quickly can the vehicle progress from a still position"),
                                                  h4("MODEL YEAR - year the vehicle was made"),
                                                  h4("ORIGIN - location where the car was engineered; 1 = America, 2 = Germany, 3 = Japan"),
                                                  h4("CAR NAME - the model name and title of each vehicle")
                                              ),
                                              box(background="red",width=12,
                                                  h4("Note: For grouping methods we will split the car name field into make and remove model on the first space of each observation. Example: car make = \"Ford\" and car model = \"Mustang\""),
                                                  h4("CAR MAKE - brand name of the vehicle")
                                              )#end of box
                                     ), #end of tab panel
                                     #section discusses the different symbol options found in the model section
                                     tabPanel("About the symbols",
                                              box(background="green",width=12,
                                                  h4("In this application you can choose from a series of symbols that will format the equation of the predictors in the formula of each model in the model section. Below is a summary of what each symbol means:"),
                                                  h4("+ - an additional interaction of a predictor with the resposne. Example: cylinder + displacement would create a formula of ", withMathJax(helpText('$$mpg \\sim cylinder + displacement$$'))),
                                                  h4(": - an interaction between two predictors with the response. Example: cylinders:displacement would create a formula of ", withMathJax(helpText('$$mpg \\sim cylinders*displacement$$'))),
                                                  h4("* - is all combinations between two predictors, essentially combining : and +. Example: cylinders*cylinders would create a formula of ", withMathJax(helpText('$$mpg \\sim cylinders + cylinders^2$$')))
                                              ),
                                              box(background="red",width=12,
                                                  h4("Note: MathJax was used to create the squared symbol above!"))
                                      )
                                   )#end of tabset panel
                            )#end of column
                          )#end of fluid row
                  ), #end of tab item
                  
                  #data tab focuses all on data analysis, giving the user to see the relationships between the response and predictor
                  #while also having the ability to view the raw data
                  tabItem(tabName = "data",
                          fluidRow(
                            column(12,
                                   tabsetPanel(
                                     #first tab panel is focused on showing the user each predictor through a series of graphs
                                     #user can choose from a set of options to modify the graphs, includes a conditional panel
                                     #based on the user's input to add more depth by providing a 2 predictor
                                     tabPanel("Analysis",
                                              column(3,
                                                     box(width=12,title="Understanding each predictor and its relationship to MPG",
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
                                              #output of the graphs from the server side that are dynamic as the user changes the predictor
                                              #also have a conditional statement for the zoom feature in case the user does not always want to view it
                                              column(9,
                                                     h3("Scatter plot of the selected predictor:"),
                                                  plotOutput("predictorScatterPlot",
                                                             brush = brushOpts(
                                                               id = "predict_brush",
                                                               resetOnNew = TRUE
                                                             )
                                                  ),
                                                  conditionalPanel(
                                                    condition = "input.zoomCheckBox == true",
                                                    h3("Select a section on the graph above to zoom a specific area!"),
                                                    plotOutput("zoomScatterPlot")
                                                  ),
                                                  h3("Numeric histogram to summarize the counts in the selected predictor:"),
                                                  plotOutput("predictorHistogram")
                                              )
                                     ), #end tab panel
                                     #tab is focused on allowing the user to see the raw data and filter it based on a predictor
                                     #the slider is dynamically changing based on the range of the selected predictor
                                     tabPanel("View the data", 
                                              column(3,
                                                     selectizeInput("filterDropDown", "Select a predictor to filter on:", selected = "cylinders", choices = c("cylinders","displacement","horsepower","weight","acceleration","model_year","origin")),
                                                     sliderInput("filterRange", "Range:",
                                                                 min = 1, max = 1000,
                                                                 value = c(1,8)),
                                                     downloadButton("downloadData", "Download Data")
                                              ),
                                              #data table generated on the server side
                                              column(9,
                                                     dataTableOutput("rawDataTable")
                                              )
                                     ),
                                     #tabPanel allows user to create a hierarchical dendogram customaizable to thier deisng
                                     tabPanel("Dendogram",
                                              column(3,
                                                h3("You can create a customizable hierarchical dendogram by changing the order below!"),
                                                h3("You can change up to 6 predictors in the dendogram:"),
                                                selectizeInput("dendo1DropDown", "Select hierarchical predictor 1:", selected = "cylinders", choices = c("cylinders","displacement","horsepower","weight","acceleration","model_year","car_make","origin")),
                                                selectizeInput("dendo2DropDown", "Select hierarchical predictor 2:", selected = "displacement", choices = c("cylinders","displacement","horsepower","weight","acceleration","model_year","car_make","origin")),
                                                selectizeInput("dendo3DropDown", "Select hierarchical predictor 3:", selected = "horsepower", choices = c("cylinders","displacement","horsepower","weight","acceleration","model_year","car_make","origin")),
                                                selectizeInput("dendo4DropDown", "Select hierarchical predictor 4:", selected = "none", choices = c("none","cylinders","displacement","horsepower","weight","acceleration","model_year","car_make","origin")),
                                                selectizeInput("dendo5DropDown", "Select hierarchical predictor 5:", selected = "none", choices = c("none","cylinders","displacement","horsepower","weight","acceleration","model_year","car_make","origin")),
                                                selectizeInput("dendo6DropDown", "Select hierarchical predictor 6:", selected = "none", choices = c("none","cylinders","displacement","horsepower","weight","acceleration","model_year","car_make","origin"))
                                              ),
                                              column(9,
                                                h3("Interactive Dendogram:"),
                                                collapsibleTreeOutput("interactiveDendogram")
                                              )
                                     )
                                   ) #end tab set
                            ) #end column
                          ) #end fluidrow
                  ),
                  #model tab provides the user the tools to fit different GLM and tree models to the data base on their analysis in the above tab
                  tabItem(tabName = "model",
                          fluidRow(
                            column(12,
                                   tabsetPanel(
                                     #Tab allows the user to customize a formula and fit it to any GLM allowed in the glm function
                                     #There is a try catch on the server side in case the user inputs an invalid formula, in which they will be notified
                                     #There are 2 conditional panesl based on if the user want's to build the formula or input it
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
                                              #output of the glm will vary based on if the user is building the formula or inputting it
                                              column(9,
                                                     conditionalPanel(
                                                       condition = "input.glmChooseDropDown == \"Build model\"",
                                                       textOutput("custModelSummaryText"),
                                                       h3("Model summary:"),
                                                       htmlOutput("customModelSummary"),
                                                       h3("Model plots:"),
                                                       plotOutput("customModelPlot"),
                                                       plotOutput("customLinearModelPlot")
                                                     ),
                                                     conditionalPanel(
                                                       condition = "input.glmChooseDropDown == \"Input formula\"",
                                                       textOutput("compareModelSummaryText"),
                                                       h3("Model summary:"),
                                                       htmlOutput("compareModelSummary"),
                                                       h3("Model plot:"),
                                                       plotOutput("compareModelPlot")
                                                     )
                                              )
                                     ),
                                     #tree panel allows the user to either fit a regression tree or boosted tree
                                     #Attempted to fit other trees but had challenges when creating plots to show the user 
                                     #how their changes affected the tree and it's prediction pattern
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
                                                           textInput("cpSetInput","Set final cp to:",value = "0.2"),
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
                                                     )#end of box
                                              ), #end of column
                                              #output plots of the user's formulas and selected tree
                                              #conditional statements linked to if the user wants a regression or boosted tree
                                              column(9,
                                                     conditionalPanel(
                                                       condition = "input.treeChooseDropDown == \"Regression Tree\"",
                                                       textOutput("custTreeModelText"),
                                                       h3("Regression tree design and branches:"),
                                                       plotOutput("regressionFullTreePlot"),
                                                       h3("CP complexity plot:"),
                                                       plotOutput("regressionTreePlot")
                                                     ),
                                                     conditionalPanel(
                                                       condition = "input.treeChooseDropDown == \"Boosted Tree\"",
                                                       textOutput("boostedTreeModelText"),
                                                       h3("Boosted tree parameters:"),
                                                       plotOutput("boostedTreePlot")
                                                     )
                                              ) #end of column
                                     ),
                                     #final tab allows the user to input a GLM formula and see how it plots agains a test set
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
                                                         textInput("testAmountInput","What percent of data do you want to use for testing:",value = "20")
                                                     )
                                              ),
                                              #output plot of the prediction tests
                                              column(9,
                                                textOutput("predictionModelText"),
                                                h3("Predictive vs Actual points:"),
                                                plotOutput("predictionPlot")
                                              )#end of column
                                              
                                     )#end of tab panel
                                   )#end of tabset panel
                            )#end of column
                          )#end of fluid row
                    
                  )#end of tab item
                )#end of tabitems
              )#end of dashboard body
)#end of dashboard
