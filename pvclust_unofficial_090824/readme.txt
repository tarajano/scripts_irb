### About this (unofficial) version of pvclust ###

# In this version you can use arbitrary distance functions.
# This function has not been tested well yet (especially in parallel version),
# so please be careful and remember that there is no warranty.

### Example ###

source("pvclust.R")
source("pvclust-internal.R")
library(MASS)

# Define a distance function. It should return an object of class "dist".
# Data should be "x" in the function and there should be "..." in the last of the argument list.

cosine <- function(x, ...) {
    x <- as.matrix(x)
    y <- t(x) %*% x
    res <- 1 - y / (sqrt(diag(y)) %*% t(sqrt(diag(y))))
    res <- as.dist(res)
    attr(res, "method") <- "cosine"
    return(res)
}

# Give the function to pvclust as method.dist

result <- pvclust(Boston, method.dist=cosine, nboot=100)
plot(result)     # You can see "Distance: cosine" in the plot
