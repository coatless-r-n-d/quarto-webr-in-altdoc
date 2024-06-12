#' Residual (Sur)Realism
#'
#' A dataset that yields a model with surreal residuals.
#'
#' @format 
#' A data frame with 5,395 rows and 7 columns:
#' \describe{
#'   \item{V1}{Target variable of interest}
#'   \item{V2}{First predictor variable}
#'   \item{V3}{Second predictor variable}
#'   \item{V4}{Third predictor variable}
#'   \item{V5}{Fourth predictor variable}
#'   \item{V6}{Fiveth predictor variable}
#'   \item{V7}{Sixth predictor variable}
#' }
#' 
#' @examples
#' # Load the data
#' data(residual_surrealism)
#' 
#' # Fit a model
#' model = lm(V1 ~ ., residual_surrealism)
#' 
#' # Graph the residuals vs. fitted values
#' plot(fitted(model),resid(model))
#' 
#' # Add a line at y = 0
#' abline(0, 0, col = "red")
#' 
#' @source 
#' Leonard A Stefanski
#' <https://www.tandfonline.com/doi/abs/10.1198/000313007X190079>
"residual_surrealism"
