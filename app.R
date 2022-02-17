library(tidyverse)
library(shiny)
library(wesanderson)
library(geojsonio)
library(rgdal)
library(rgeos)
#library(RColorBrewer)
library(rgdal)
library(shinyFiles)
library(shinythemes)
#library(shinyWidgets)#background color
library(rsconnect)#to host shiny app online
rsconnect::deployApp('C:/Users/eagle/Desktop/R/governmentSpending')


# Load TT Data ------------------------------------------------------------
#kids <- read.csv("C:/Users/eagle/Desktop/R/govspending/kids.csv")
kids <- readr::read_csv('https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2020/2020-09-15/kids.csv')

kids$variable <- as.factor(kids$variable)
levels(kids$variable)


# Load Map Data -----------------------------------------------------------
# Instructions from: https://www.r-graph-gallery.com/328-hexbin-map-of-the-usa.html
spdf <- geojson_read("us_states_hexgrid.geojson",  what = "sp")# Bit of reformating
spdf@data = spdf@data %>%
    mutate(google_name = gsub(" \\(United States\\)", "", google_name))

plot(spdf)

spdf@data = spdf@data %>% mutate(google_name = gsub(" \\(United States\\)", "", google_name))
spdf_fortified <- broom::tidy(spdf, region = "google_name")

#Determine centers for labels
centers <- cbind.data.frame(data.frame(gCentroid(spdf, byid=TRUE), id=spdf@data$iso3166_2))

#Join map data with kids data
test <- spdf_fortified %>%
    left_join(. , kids, by=c("id"="state")) 

levels(test$variable)

#pal <- wes_palette("GrandBudapest1", 21, type = "continuous")#color palette

#setNames(as.list(test$variable), test$variable)


# APP ---------------------------------------------------------------------


# Define UI for application that draws a histogram
ui <- fluidPage(
    
    theme = shinytheme("superhero"),
    
    # Application title
    titlePanel(div("US Government Spending on Kids", style = "color: white")),
    
    # Sidebar with a slider input for year
    sidebarLayout(
        sidebarPanel(
            sliderInput("yearSelect",
                        label = "Year:",
                        sep = "",
                        ticks = FALSE,
                        min = 1997,
                        max = 2016,
                        value = 1997),
            
            # selectInput("var", "Select Variable", choices = levels(test$variable))
            
            #TO Do" add the rest of the variables 
            selectInput(inputId = "var",
                        label = "Choose a variable:",
                        choices = c("PK-12 Education" = "PK12ed",
                                    "Higher Education" = "highered",
                                    "Education Subsidies" = "edsub",
                                    "Education Special Services" = "edserv",
                                    "Pell Grants" = "pell",
                                    "Head Start" = "HeadStartPriv",
                                    "Temporary Assistance for Needy Families (TANF)" = "TANFbasic",
                                    "Cash Assitantce/Social Services" = "othercashserv",
                                    "Supplemental Nutrition Assistance Program (SNAP)" = "SNAP",
                                    "Social Security" = "socsec",
                                    "Supplemental Security Income" = "fedSSI",
                                    "Earned Income Tax Credit (EITC)" = "fedEITC",
                                    "Child Tax Credit" = "CTC",
                                    "Additional Child Tax Credit" = "addCC",
                                    "State EITC" = "stateEITC",
                                    "Unemployment" = "unemp",
                                    "Worker's Compensation" = "wcomp",
                                    "Medicaid and CHIP" = "Medicaid_CHIP",
                                    "Public Health" = "pubhealth",
                                    "Other Health" = "other_health",
                                    "Household and Community Development" = "HCD",
                                    "Libraries" = "lib",
                                    "Parks and Recreation" = "parkrec"
                        ),
                        selected = 1),
            

            radioButtons("palette", "Color Palette",
                         c("GrandBudapest1"="gb1",
                           "GrandBudapest2"="gb2",
                           "Zissou" = "z",
                           "Royal1" = "r1",
                           "Royal2" = "r2"))
            
        ),#end of sidePanel
        
        
        #Show a plot of the generated distribution
        mainPanel(
            plotOutput("plot")
            
        )
    )
)

# Define server logic required to draw a histogram
server <- function(input, output) {
    
    
    filtered <- reactive({
        df <- test %>% 
            dplyr::filter(variable %in% input$var) %>%
            # dplyr::filter(variable == input$var) %>% 
            dplyr::filter(year == input$yearSelect) 
    })
    
    observe({
        if (input$palette == "gb1") {
            pal <- wes_palette("GrandBudapest1", 21, type = "continuous")
        } else if (input$palette == "gb2") {
            pal <- wes_palette("GrandBudapest2", 21, type = "continuous")
        } else if (input$palette == "r1") {
            pal <- wes_palette("Royal1", 21, type = "continuous")
        } else if (input$palette == "r2") {
            pal <- wes_palette("Royal2", 21, type = "continuous")
        } else {
            pal <- wes_palette("Zissou", 21, type = "continuous")
        }
    })

    
    #add filtering so var equals user selection
    output$plot <-renderPlot({
        data <- filtered()
        
        data %>%
            ggplot() +
            geom_polygon(aes(fill = inf_adj_perchild, x = long, y = lat, group = group), color = "#6b6b6b") +
            scale_fill_gradientn(colours = pal)+
            geom_text(data = centers, aes(x = x, y = y, label = id), size = 5, color = "white")+
            # annotate("text", x = -10, y = .5, label = input$yearSelect)+
            # geom_text(aes_string(x = 10, y = 25, label=unique("year")))+
            labs(
                fill = "Inflation (adjusted per child)"
            )+
            theme(plot.background = element_rect(fill="#95b0cc", color = NA),
                  panel.background = element_rect(fill="#95b0cc", color = NA),
                  legend.background = element_rect(fill="#95b0cc"),
                  legend.title = element_text(size = 16, margin = margin(r = .5, unit = "cm")),
                  legend.text = element_text(size = 14),
                  legend.key.size = unit(1, 'cm'),
                  panel.grid = element_blank(),
                  axis.title = element_blank(),
                  axis.text = element_blank(),
                  axis.ticks = element_blank(),
                  legend.position = "bottom"
            )},
        height = 700,width = 1150)
    
}


# Run the application 
shinyApp(ui = ui, server = server)
