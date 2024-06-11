# Debug ----

# Function to show all environment variables
display_env_vars <- function() {
  env_vars <- Sys.getenv()
  env_var_names <- names(env_vars)
  
  sink("env_vars.txt")
  cat("Environment Variables:\n")
  for (i in seq_along(env_var_names)) {
    cat(env_var_names[i], "=", env_vars[i], "\n", sep = "")
  }
  sink()
}

# Call the function to show environment variables
display_env_vars()
