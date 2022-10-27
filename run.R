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

# Run app
library(shiny)
runApp(port = 8080, host = "0.0.0.0",launch.browser = FALSE)
