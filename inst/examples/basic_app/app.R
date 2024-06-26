library(dplyr)
library(dbplyr)
library(DBI)
library(shiny)
devtools::load_all()

starwars2 <- starwars %>%
  mutate_if(~is.numeric(.) && all(Filter(Negate(is.na), .) %% 1 == 0), as.integer) %>%
  mutate_if(~is.character(.) && length(unique(.)) <= 25, as.factor) %>%
  mutate(is_droid = species == "Droid") %>%
  select(name, gender, height, mass, hair_color, eye_color, is_droid)

# create some labels to showcase column select input
attr(starwars2$name, "label")     <- "name of character"
attr(starwars2$gender, "label")   <- "gender of character"
attr(starwars2$height, "label")   <- "height of character in centimeters"
attr(starwars2$mass, "label")     <- "mass of character in kilograms"
attr(starwars2$is_droid, "label") <- "whether character is a droid"


starwars2_sql <- tbl_memdb(starwars2)

ui <- fluidPage(
  titlePanel("Filter Data Example"),
  fluidRow(
    column(8,
           dataTableOutput("data_summary"),
           verbatimTextOutput("data_filter_code")),
    column(4, shiny_data_filter_ui("data_filter"))))

server <- function(input, output, session) {
  filtered_data <- callModule(
    shiny_data_filter,
    "data_filter",
    data = starwars2_sql,
    choices = c("height", "mass", "is_droid", "name", "hair_color", "gender"),
    verbose = TRUE
  )

  output$data_filter_code <- renderPrint({
    cat(gsub("%>%", "%>% \n ",
             gsub("\\s{2,}", " ",
                  paste0(
                    capture.output(attr(filtered_data(), "code")),
                    collapse = " "))
    ))
  })

  output$data_summary <- renderDataTable({

    eval(parse(text= gsub("\\s{2,}", " ",
                               paste0(
                                 capture.output(attr(filtered_data(), "code")),
                                 collapse = " ")
    ))) %>%
      collect()
  },
  options = list(
    scrollX = TRUE,
    pageLength = 5
  ))
}

shinyApp(ui = ui, server = server)
