#### select var 
# library(shinycssloaders) # needed to add a spinner to the plot
# library(varhandle) # contains check.numeric function


######## THIS HAS MODIFICATIONS FROM THE ORIGINAL DO NOT USE THIS FILE!!!! #######
# propagate from something that is actually working. 
# such as the upload_and_plot_layout project and app
# UI for color plots
selectLayoutColorUI <- function(id) {
  tagList(
    # [[1]] returns the drop-down menu
    selectInput(NS(id, "color_by"), 
                label = "Color plate plot by",  # as select input
                choices = NULL),
    
    # [[2]] returns the plot, WITHOUT brush well-selection
    plotOutput(NS(id, "plot"),  brush = "plot_brush")  %>% withSpinner(color="#525252"), 
        style = "overflow-x: scroll;overflow-y: scroll;height:580px",
    #tableOutput("selected_wells")
    verbatimTextOutput("selected_wells")
  )
}

# server for color plots
# relies on additional modules: updateSelectInput
# relied on additional functions: 
# make_platemap_plot
# find_vars

selectLayoutColorServer <- function(id, data, 
                                    hide_vars = c("row", "column", "well")) { # filter arg added here
  
  stopifnot(is.reactive(data))
  
  moduleServer(id, function(input, output, session) {
    observeEvent(data(), { # if ever the dataset is changed
      updateSelectInput(session, "color_by",
                        choices = find_vars(data(), hide_vars)) # update the choices
    })
    
    
    output$plot <- renderPlot({
      req(input$color_by)  # wait until input$color_by is created
      
      make_platemap_plot( data = data(),
                          fill_var = !!input$color_by,
                          plot_title = paste0("Plate layout: ", input$color_by))
    }, bg = "transparent")
    
    # output$selected_wells <- renderTable({
    #   brushedPoints(data, input$plot_brush)
    # })
    
    output$selected_wells <- renderText({
     input$plot_brush
    })
    
    reactive( make_platemap_plot( data = data(),
                                  fill_var = !!input$color_by,
                                  plot_title = paste0("Plate layout: ", input$color_by))
    )
    
  })
}

# function to find variables used in the platemap plot server
# helper function for the server
find_vars <- function(data, hide_vars) {
  data %>% 
    select(-all_of(hide_vars)) %>% # this could replace
    get_var_order(.)
}

get_var_order <-  function(layout) {
  layout %>%
    mutate_all(as.character) %>%
    pivot_longer(cols = everything(), names_to = "variable", values_to = "value") %>%
    group_by(variable) %>%
    summarise(count = n_distinct(value), .groups = 'drop') %>% # .groups is experimental, so keep an eye on this line as dplyr advances see: https://stackoverflow.com/questions/62140483/how-to-interpret-dplyr-message-summarise-regrouping-output-by-x-override
    arrange(count) %>% 
    pull(variable) %>%
    unique() %>%
    as.character()
}

# sort_layout_vars <- function( vars ) {
#   plate_vars <- c("condition", "well", "row", "column")
#   end_vars <- plate_vars[plate_vars %in% vars] # these should always be here, but just in case 
#   user_vars <- vars[!vars %in% end_vars ]
#   c(user_vars, end_vars)
# } 

# function to make the platemap plot
make_platemap_plot <- function( data,  plot_title, fill_var ) {
  
  fill_var <- enquo(fill_var)
  
  df <-  platetools::plate_map(data = data$well, well = data$well ) %>%
    mutate(well_f = well,
           well = as.character(well)) %>%
    select(-values) %>%
    left_join(data, by = "well") %>%
    mutate(well = well_f) %>%
    filter(!!fill_var != "Empty") %>%
    select(well, Column, Row, !!fill_var) %>%
    set_names(c("well", "Column", "Row", "var"))
  
  
  
  p <- df %>%
    ggplot( . , aes(x = Column, y = Row)) +
    geom_point(data = expand.grid(seq(1, 24), seq(1, 16)),
               aes_string(x = "Var1", y = "Var2"),
               color = "grey90", fill = "white", shape = 22, size = 5-2, alpha = 0.1) +
    coord_fixed(ratio = (24.5 / 24) / (16.5 / 16), xlim = c(0.5, 24.5)) +
    scale_y_reverse(breaks = seq(1, 16), labels = LETTERS[1:16]) +
    scale_x_continuous(position = "top", breaks = seq(1, 24)) +
    xlab("") +
    ylab("") +
    theme_dark() +
    theme(plot.background = element_rect(fill = "transparent", color = NA),
          
          legend.background = element_blank()) +
    
    geom_point(aes(fill = var), colour = "gray20", shape = 22, size = 5) +
    labs(title = plot_title, fill = fill_var) 
  
  if(all(check.numeric(df  %>% select(var) %>% as_vector()))){
    p <- p +
      scale_fill_viridis_c(begin = 0.8, end = 0) ### this is evaluating wrong---why?
    
  } else {
    
    p <- p +
      scale_fill_viridis_d(begin = 0.8, end = 0)  ### this is evaluating wrong---why?
  }
  
  p
  
}