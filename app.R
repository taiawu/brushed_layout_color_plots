# this app is a minimal example of uploading a layout file using the layout uploads module
library(tidyverse)
library(shiny)
library(shinyalert) # needed to upload layout files
library(shinycssloaders) # needed for the spinner on the layout plots
library(varhandle)  # needed for the layout plots
# source("upload_layout_module.R")
source("layout_color_plot_module.R")

source("layout_color_plot_module.R")

ui <- fluidPage(
    ### hadley's example, unchanged
    plotOutput("plot", brush = "plot_brush"),
    tableOutput("data"),
    ### ^ hadley's example, unchanged
    
    ### adapted from the color plot layout module
    p("color plotting module"),
    selectLayoutColorUI("color_var")[[1]], # select a color_by variable
   # plotOutput("external_plot",  brush = "plot_brush_wells")  %>% withSpinner(color="#525252"),
   plotOutput("plot_from_raw",  brush = "plot_brush_wells")  %>% withSpinner(color="#525252"),
 #  tableOutput("selected"),
   verbatimTextOutput("selected_text"),
    selectLayoutColorUI("color_var")[[3]], # select a color_by variable
    selectLayoutColorUI("color_var")[[4]] # select a color_by variable
    # selectLayoutColorUI("color_var")[[4]] # plate plot
    ### ^ adapted from the color plot layout module
   
)

server <- function(input, output, session) {
    ### hadley's example, unchanged
    output$plot <- renderPlot({
        ggplot(mtcars, aes(wt, mpg)) + geom_point()
    }, res = 96)
    
    output$data <- renderTable({
        brushedPoints(mtcars, input$plot_brush)
    })
    ### ^ hadley's example, unchanged
    
    ### adapted from the color plot layout module
    # layout_raw <- uploadLayoutServer("data") # upload the data
    # layout <- reactive(layout_raw()) # access the layout outside of the module
    layout <- reactive(readRDS("demo_layout.rds"))
    output$table_external <- renderTable(head(layout()))


    ### color layout plot module ###
    layout_plot <- selectLayoutColorServer("color_var",
                                           data = layout # reactive, but called without the ()
                                           )
  
    output$external_plot <- renderPlot({
        layout_plot()
    }, bg = "transparent")
    
    output$plot_from_raw <- renderPlot({
      #  req(input$color_by)  # wait until input$color_by is created
        
        make_platemap_plot( data = layout(),
                            fill_var = ligand,
                            plot_title = paste0("Plate layout: "))
    }, bg = "transparent")
    
    
    # output$data <- renderTable({
    #     brushedPoints(layout(), input$plot_brush_wells)
    # })
    # 
    output$selected <- renderTable({
        #input$plot_brush_wells
     brushedPoints(layout(), input$plot_brush_wells)
    })
    
    output$selected_text <- renderText({
        input$plot_brush_wells
       # brushedPoints(layout(), input$plot_brush_wells)
    })
    
    # output$selected <- renderText({
    #     #input$plot_brush_wells
    #  brushedPoints(layout(), input$plot_brush_wells)
    # })
    ### ^ adapted from the color plot layout module
}
# Run the application 
shinyApp(ui = ui, server = server)
