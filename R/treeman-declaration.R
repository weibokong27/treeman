#' @name TreeMan
#' @title TreeMan Class
#' @description S4 Class for representing phylogenetic trees as a list of nodes.
#' @details
#' A \code{TreeMan} object holds a list of nodes. The idea of the \code{TreeMan}
#' class is to make adding and removing nodes as similar as possible to adding
#' and removing elements in a list. Note that internal nodes and tips are
#' both considered nodes. Trees can be unrooted and polytomous.
#' 
#' 
#' Each node within the \code{TreeMan} \code{nodelist} contains the following data slots:
#' \itemize{
#'    \item \code{id}: character string for the node ID
#'    \item \code{span}: length of the preceding branch
#'    \item \code{prenode}: ID of the preceding node
#'    \item \code{postnode}: IDs of the connecting nodes
#'    \item \code{children}: descending tip IDs
#'    \item \code{pd}: phylogenetic diversity represented by node
#'    \item \code{predist}: prenode distance (distance to root if rooted or
#'    most distal tip if unrooted)
#' }
#' These data slots are updated whenever a node is modified, added or removed.
#' 
#' Currently available methods:
#' \itemize{
#'   \item \code{tips()}: list all tips
#'   \item \code{nodes()}: list all internal nodes
#'   \item \code{nTips()}: count all tips
#'   \item \code{nNodes()}: count all internal nodes
#'   \item \code{rootNode()}: return root node ID, NULL if unrooted
#'   \item \code{[[]]}: extract \code{Node}
#'   \item \code{pd()}: get total branch length of tree
#'   \item \code{age()}: get max root to tip distance
#'   \item \code{ultrmtrc()}: is ultrametric T/F
#'   \item \code{plytms()}: is polytomous T/F
#'   \item \code{extant()}: return extant tips
#'   \item \code{extinct()}: return extinct tips
#'   \item \code{setTol()}: set tolerance (default 1e-8)
#' }
#' 
#' See below in 'Examples' for these methods in use.
#' @seealso
#' \code{\link{randTree}}
#' @exportClass TreeMan
#' @examples
#' library (treeman)
#' # Generate random tree
#' tree <- randTree (10)
#' # Print to get basic stats
#' print(tree)
#' # Currently available methods
#' tips(tree)  # return all tips IDs
#' nodes(tree)  # return all internal node IDs
#' nTips(tree)  # count all tips
#' nNodes(tree)  # count all internal nodes
#' rootNode(tree)  # identify root node
#' tree[['t1']]  # return t1 node object
#' pd(tree)  # return phylogenetic diversity
#' age(tree)  # return age of tree
#' ultrmtrc(tree)  # is ultrametric?
#' plytms(tree)  # is polytomous?
#' extant(tree)  # return all extant tip IDs
#' extinct(tree)  # return all extinct tip IDs
#' tree <- setTol (tree, 10)  # reset tolerance, default 1e-8
#' # now tol is higher more tips will be classed as extant
#' extant (tree)
#' # Because all nodes are lists with metadata we can readily
#' #  get specific information on nodes of interest
#' node <- tree[['n2']]
#' node$pd
#' node$children  # etc ....
# TODO: create validity check
setClass ('TreeMan', representation=representation (
  nodelist='list',       # list of Node objects
  nodes='vector',        # vector of Node ids that are internal nodes
  tips='vector',         # vector of Node ids that are tips
  age='numeric',         # numeric of max root to tip distance
  pd='numeric',          # numeric of total branch length of tree
  extant='vector',       # vector of Node ids of all tips with 0 age
  extinct='vector',      # vector of Node ids of all tips with age > 0
  brnchlngth='logical',  # logical, do nodes have span
  ultrmtrc='logical',    # logical, do all tips end at 0
  plytms='logical',      # logical, is tree bifurcating
  tol='numeric',         # numeric of tolerance for determining extant
  root='character'),     # character of Node id of root
  prototype=prototype (tol=1e-8))

# Manip methods
setMethod ('[[', c ('TreeMan', 'character', 'missing'),
           function(x, i, j, ...) {
             x@nodelist[[i]]
           })
setGeneric ("tips<-", signature=c("x"),
            function (x, value) {
              standardGeneric("tips<-")
            })
setReplaceMethod ("tips", "TreeMan",
                  function (x, value) {
                    if (any (duplicated (value))) {
                      stop ('Tip names must be unique')
                    }
                    old_tips <- x@tips
                    n <- length (old_tips)
                    if (n != length (value)) {
                      stop ('Incorrect number of replacement tips')
                    }
                    mis <- match (old_tips, names (x@nodelist))
                    for (i in 1:n) {
                      x@nodelist[[old_tips[i]]]$id <- value[i]
                    }
                    names (x@nodelist)[mis] <- value
                    .update (x)
                  })
setGeneric ("nodes<-", signature=c("x"),
            function (x, value) {
              standardGeneric("nodes<-")
            })
setReplaceMethod ("nodes", "TreeMan",
                  function (x, value) {
                    if (any (duplicated (value))) {
                      stop ('Node names must be unique')
                    }
                    old_nodes <- x@nodes
                    n <- length (old_nodes)
                    if (n != length (value)) {
                      stop ('Incorrect number of replacement nodes')
                    }
                    mis <- match (old_nodes, names (x@nodelist))
                    for (i in 1:n) {
                      x@nodelist[[old_nodes[i]]]$id <- value[i]
                    }
                    names (x@nodelist)[mis] <- value
                    .update (x)
                  })
setGeneric ('.update', signature=c('x'),
            function(x) {
              genericFunction ('.update')
            })
setMethod ('.update', 'TreeMan',
           function (x) {
             with_pstndes <- sapply (x@nodelist,
                                     function (x) length (x$postnode) == 0)
             x@tips <- names (with_pstndes)[with_pstndes]
             x@nodes <- names (with_pstndes)[!with_pstndes]
             x@brnchlngth <- all (sapply (x@nodelist, function (x) length (x$span) > 0))
             if (x@brnchlngth) {
               if (length (x@root) > 0) {
                 x@age <- max (sapply (x@nodelist, function (x) x$predist))
                 extant_is <- unlist (sapply (x@tips, function (i) {
                   (x@age - x@nodelist[[i]]$predist) <= x@tol}))
                 x@extant <- names (extant_is)[extant_is]
                 x@extinct <- x@tips[!x@tips %in% x@extant]
                 x@ultrmtrc <- all (x@tips %in% extant (x))
               }
               x@pd <- x@nodelist[[x@root]]$pd
             }
             x@plytms <- any (sapply (x@nodelist, function (x) length (x$postnode) > 2))
             initialize (x)
           })

# Accessor method
setGeneric ('setTol', signature=c('x', 'n'),
            function(x, n) {
              genericFunction ('setTol')
            })
setMethod ('setTol', c ('TreeMan', 'numeric'),
           function(x, n){
             x@tol <- n
             .update (x)
           })

# Info methods (user friendly)
setGeneric ('tips', signature=c('x'),
            function(x) {
              genericFunction ('tips')
            })
setMethod ('tips', 'TreeMan',
           function(x){
             x@tips
           })
setGeneric ('nodes', signature=c('x'),
            function(x) {
              genericFunction ('nodes')
            })
setMethod ('nodes', 'TreeMan',
           function(x){
             x@nodes
           })
setGeneric ('nTips', signature=c('x'),
            function(x) {
              genericFunction ('nTips')
            })
setMethod ('nTips', 'TreeMan',
           function(x){
             length (x@tips)
           })
setGeneric ('plytms', signature=c('x'),
            function(x) {
              genericFunction ('plytms')
            }) 
setMethod ('plytms', 'TreeMan',
           function(x) {
             x@plytms
           })
setGeneric ('ultrmtrc', signature=c('x'),
            function(x) {
              genericFunction ('ultrmtrc')
            }) 
setMethod ('ultrmtrc', 'TreeMan',
           function(x) {
             x@ultrmtrc
           })
setGeneric ('extant', signature=c('x'),
            function(x) {
              genericFunction ('extant')
            }) 
setMethod ('extant', 'TreeMan',
           function(x) {
             if (length (x@extant) == 0) {
               return (NULL)
             }
             x@extant
           })
setGeneric ('extinct', signature=c('x'),
            function(x) {
              genericFunction ('extinct')
            }) 
setMethod ('extinct', 'TreeMan',
           function(x) {
             if (length (x@extinct) == 0) {
               return (NULL)
             }
             x@extinct
           })
setGeneric ('nNodes', signature=c('x'),
            function(x) {
              genericFunction ('nNodes')
            })
setMethod ('nNodes', 'TreeMan',
           function(x){
             length (x@nodes)
           })
setGeneric ('rootNode', signature=c('x'),
            function(x) {
              genericFunction ('rootNode')
            })
setMethod ('rootNode', 'TreeMan',
           function(x) {
             if (length (x@root) == 0) {
               return (NA)
             }
             x@root
           })
setGeneric ('age', signature=c('x'),
            function(x) {
              genericFunction ('age')
            })
setMethod ('age', 'TreeMan',
           function(x){
             if (length (x@age) == 0) {
               return (NA)
             }
             x@age
           })
setGeneric ('pd', signature=c('x'),
            function(x) {
              genericFunction ('pd')
            })
setMethod ('pd', 'TreeMan',
           function(x){
             if (length (x@pd) == 0) {
               return (NA)
             }
             x@pd
           })