#
# This is a Shiny web application. You can run the application by clicking
# the 'Run App' button above.
#
# Find out more about building applications with Shiny here:
#
#    http://shiny.rstudio.com/
#

library(shiny)
library(magrittr)

# Define UI for application that draws a histogram
ui <- fluidPage(

    # Application title
    titlePanel("Edit replications"),

    # Sidebar with a slider input for number of bins 
    sidebarLayout(
        sidebarPanel(
            selectInput("file",
                        "File to edit",
                        choices = setdiff(list.files("./data/", "*.md"), "README.md")),
            "Changes are auto-saved when you select a different file"
        ),

        # Show a plot of the generated distribution
        mainPanel(
          textInput("title", "Effect name (brief)"),
          textInput("effect_names", "Effect (with alternative names, if any)"),
          textInput("effect_description", "Effect description & evidence summary"),
          textInput("status", "Status"),
          textInput("original_paper", "Original Paper")
        )
    )
)

# Define server logic required to draw a histogram
server <- function(input, output, session) {
  
  observe({
    file <- input$file
    
    if (exists("previous_file") && file != previous_file && stringr::str_length(previous_file) > 1) {
      message("Saving changes for ", previous_file)
      effect_prev <- effect
      effect$title <- input$title
      effect$effect_names <- input$effect_names
      effect$effect_description <- input$effect_description
      effect$Status <- input$status
      effect$`Original effect size` <- input$original_paper
      if(!identical(effect, effect_prev)) write_md_file(effect, previous_file)
    }
    
    
    if (!is.null(file)) {
      message("Reading ", file)
      effect <- read_md_file(file)
      effect <<- effect
      message("Read ", effect$title)
      updateTextInput(session, "title", value = effect$title)
      updateTextInput(session, "effect_names", value = effect$effect_names)
      updateTextInput(session, "effect_description", value = effect$effect_description)
      updateTextInput(session, "status", value = effect$Status)
      updateTextInput(session, "original_paper", value = effect$`Original paper`)
    }
    
    if (exists("previous_file") && file != previous_file && stringr::str_length(previous_file) > 1) {
    commit_and_push(previous_file)
    }
    previous_file <<- file
    
})
  
}

read_md_file <- function(file_name) {

  withCallingHandlers({
    text <- readLines(file.path("data", file_name))
  }, warning=function(w) {
    if (stringr::str_detect(conditionMessage(w), "incomplete final line"))
      invokeRestart("muffleWarning")
  })
  text <- stringr::str_subset(text, "[:alpha:]+") %>% 
    stringr::str_remove("^#+")
  
  detail_list <- list()
  detail_list["title"] <- text[1] %>% stringr::str_trim()
  detail_list["effect_names"] <- text[2] %>% stringr::str_match("\\*\\*\\s*(.*?)\\s*\\*\\*") %>% .[,2] %>% stringr::str_trim() %>% stringr::str_remove("\\.$")
  detail_list["effect_description"] <- text[2] %>% stringr::str_remove(stringr::fixed(detail_list[["effect_names"]])) %>% stringr::str_remove("^[^[:alpha:]]+")
  
  categories <- c("Status:", "Original paper:", "Critiques:", "Original effect size:", "Replication effect size:")
  
  for (i in 3:length(text)) {
    category <- categories[stringr::str_detect(text[i], categories)]
    if(length(category) > 0 && !is.na(category)) {
      detail_list[category] <- stringr::str_remove(text[i], category) %>% stringr::str_remove("^[^[:alpha:]]+")
    } else {
      detail_list[[length(detail_list)]] <- paste0(detail_list[[length(detail_list)]], "\n",  text[i])
    }
  }  
  
  return(detail_list)
}

write_md_file <- function(effect, filename) {
  text <- c(paste("####", effect$title, "\n"),
    paste("* **", effect$effect_names, ".**", effect$effect_description),
    purrr::map2_chr(names(effect[-c(1:3)]), effect[-c(1:3)], ~paste0("* _", .x, ":_ ", .y)))
  
  writeLines(text, file.path("./data", filename))
}

commit_and_push <- function(filename) {
  git2r::add(repo, filename)
  if(length(git2r::status(repo)$staged) > 0) {
    git2r::commit(repo, paste(commit_prefix, "update to", filename))
    git2r::push(repo, "origin", "refs/heads/main", credentials = git2r::cred_token())
    message("Pushed ", filename)
  }
}
  

if(exists("previous_file")) rm(previous_file)

# Set up git and get data 
Sys.setenv(GITHUB_PAT = "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") #Don't get excited - for this repo only!
commit_prefix <- "Lukas: " #Would be requested from user
if(!dir.exists("./data")) {
dir.create("./data", recursive=TRUE)
repo <- git2r::clone("https://github.com/LukasWallrich/shiny_edit_test_data", "./data")
} else {
  repo <- git2r::repository("./data")
  git2r::pull(repo)
}

git2r::config(repo, user.name="Shiny Edit", user.email="lukas.wallrich@gmail.com")

shinyApp(ui = ui, server = server)
