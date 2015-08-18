library(shiny)
library(plyr)

# Extract data scientist job info from files created from the CareerJet api.

library(jsonlite) # To read in json files
library(quantmod) # For currency conversion

# Initialize locations
locations <- c('africa', 'asia', 'australia', 'europe', 'north america')

# Create blank output data frame twice as long the number of jobs returned from the API 
by_region_df <- data.frame(matrix(NA, nrow=40))

# Create empty hits vector for the number of jobs in each region
hits <- integer()

# Create empty salaries list
salaries <- list()

# Loop over locations and extract jobs info and summarize into output data frame
for (loc in locations){
    
    # Read in the json
    con_in <- file(paste0(loc, '.json'), open='r')
    json_in <- stream_in(con_in)
    
    # Get the number of jobs in this region
    hits <- c(hits, as.numeric(json_in$hits))
    
    # Get the job details for this region into a data frame
    jobs_df <- as.data.frame(json_in$jobs[[1]])
    
    # Convert the salary data to annual and USD and add as new columns to the jobs_df.
    # Must remove jobs with NA's in the salary fields before calculating mins and maxes
    jobs_df <- jobs_df[!is.na(jobs_df$salary_min),]
    jobs_df <- jobs_df[!is.na(jobs_df$salary_max),]
    
    # Annualize all salaries.
    jobs_df$salary_min[jobs_df$salary_type=='M'] <- as.integer(jobs_df$salary_min[jobs_df$salary_type=='M']) * 12
    jobs_df$salary_max[jobs_df$salary_type=='M'] <- as.integer(jobs_df$salary_max[jobs_df$salary_type=='M']) * 12
    
    # Call to get conversion rate is getQuote(paste0(from, to, "=X"))
    # Returns a data frame. The "Last" column is the one of interest.
    # To avoid overusing the Yahoo FX API I must to build a local set of just conversions I need.
    # Get all the currency codes in the jobs_df into "from" vector
    from <- unique(jobs_df$salary_currency_code)
    
    # Create "to" vector of same length as "from" with all "USD" entries
    to <- rep('USD', length(from))
    
    # Get the conversion factors to convert to USD
    # Usage is like this:
    # library(quantmod)
    # from <- c("CAD", "JPY", "USD")
    # to <- c("USD", "USD", "EUR")
    # getQuote(paste0(from, to, "=X"))
    conv_rates <- getQuote(paste0(from, to, '=X'))
    rates <- conv_rates$Last
    # Add names to the rates so it can be used as a dictionary
    names(rates) <- from
    
    # Do conversion and add new columns to the jobs_df
    jobs_df$annual_usd_min <- round(as.integer(jobs_df$salary_min) * unname(rates[jobs_df$salary_currency_code]), 0)
    jobs_df$annual_usd_max <- round(as.integer(jobs_df$salary_max) * unname(rates[jobs_df$salary_currency_code]), 0)
    
    # A to the salaries list the combined min and max salaries for this region.
    salaries[[loc]] <- c(jobs_df$annual_usd_min, jobs_df$annual_usd_max)
    # Don't forget this is just the 20 (or fewer if data are missing) top paying jobs in the region.
    
    close(con_in)
}

# At this point we have the following:
# character vector called locations that contains the name of each region
# integer vector called hits that is the number of jobs in each region
# list called salaries that has the min and max salaries of the approx top 20 paying jobs in each region
# The server can now create plots as required for the ui.

# For capitalizing first letters of multiple word vectors
simpleCap <- function(x) {
    s <- strsplit(x, " ")[[1]]
    paste(toupper(substring(s, 1,1)), substring(s, 2),
          sep="", collapse=" ")
}

# Barplot of jobs by regions
#barplot(hits, main='Jobs by Region', names.arg=locations, xlab='Region', ylab='Number of jobs', col='darkgreen')

# For the boxplots do this:
# options(scipen=7) # Suppress scientific notation for less than 7 order of magnitude
# boxplot(salaries[[loc]], ylab='USD per year', main=paste('Data Scientist Salaries in', sapply(loc, simpleCap)))

shinyServer(
    function(input, output) {
        output$barPlot <- renderPlot({
            barplot(hits, main='Data Scientist Jobs by Region', names.arg=sapply(locations, simpleCap), ylab='Number of Jobs', col='darkgreen')
        })
        output$boxPlot <- renderPlot({
            options(scipen=7)
            boxplot(salaries[[input$regionChoice]], ylab='USD per year', main=paste('Data Scientist Salaries in', sapply(input$regionChoice, simpleCap)))
        })
        output$locations <- renderText({locations})
        output$text1 <- renderText({input$text1})
        output$text2 <- renderText({input$text2})
        output$text3 <- renderText({
            if (input$goButton==0) { "Press Go"}
            else {
                input$goButton
                isolate(paste(input$text1, input$text2))
            }
        })
    }
)