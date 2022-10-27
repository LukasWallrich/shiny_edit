library(magrittr)

# Set up git and get data 
PAT <- "6769746875625f7061745f3131414f4b364e474930704a7a434c7763665264634e5f4456784f774f515a6f3977396138564b4c4576516f44456f646c743069456962704a38346b79474265795152594b365556494f76434a5077427355"
sst <- strsplit(PAT, "")[[1]]
sst <- paste0(sst[c(TRUE, FALSE)], sst[c(FALSE, TRUE)]) %>% strtoi(16) %>% as.raw()
Sys.setenv(GITHUB_PAT = rawToChar(sst)) #Don't get excited if you can decode it - for this repo only!

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
