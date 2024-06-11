#' Detect if the version of R is built using Web Assembly (WASM)
#' 
#' The function checks whether the compiled version of _R_ shows an architecture
#' that matches `"emscripten"` . If it's the case, we're likely using webR to access
#' R.
#' 
#' @export
#' @examples
#' # Check to see if WASM is active
#' in_webr()
in_webr <- function() { R.Version()$os == "emscripten" }
