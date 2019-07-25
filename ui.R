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
                menuItem("Data Exploration", tabName = "data", icon = icon("database"))
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
                                                         )
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
                                              h1("data table")
                                     )
                                   ) #end tab set
                            ) #end column
                          ) #end fluidrow
                  )
                )
              )
)
