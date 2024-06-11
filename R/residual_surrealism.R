#' Residual (Sur)Realism
#'
#' A dataset containing residuals from a surreal model.
#'
#' @format 
#' A data frame with 5,395 rows and 7 columns:
#'
#' @examples
#' data(residual_surrealism)
#' 
#' model = lm(V1 ~ ., residual_surrealism)
#' 
#' plot(fitted(model),resid(model))
#' abline(0, 0, col = "red")
#' 
#' @source 
#' Leonard A Stefanski
#' <https://www.tandfonline.com/doi/abs/10.1198/000313007X190079>
"residual_surrealism"
