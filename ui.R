library(shiny)
shinyUI(pageWithSidebar(
    
    headerPanel(h2(style="text-align:center", 'Where the Jobs Are'), windowTitle='Where The Jobs Are'),
    sidebarPanel(
        plotOutput('boxPlot'),
        radioButtons(inputId='regionChoice', label='Select a Region', 
                     c('Africa'='africa', 'Asia'='asia', 'Australia'='australia',
                       'Europe'='europe', 'North America'='north america'), inline=TRUE)
    ),
    mainPanel(
        p('(Please wait a moment for charts to appear)'),
        plotOutput('barPlot'),
        p('Results based on jobs data from CareerJet API retrieved 14 August 2015')
    )
))