# Christopher Carignan, 2021
#
# analyze_playlist_features() analyzes 12 different acoustic/audio features from each song in the user's playlist. 
# The results are submitted to a principal components analysis (PCA) model in order to find the underlying dimensions shared by these features.
# Principal components (PCs) with eigenvalues >= 1 are retained for feature extraction.
# The acoustic features that are most heavily weighted across the retained PCs are used for feature estimation of playlist recommendation.
#
# inputs
# result (list): the result of the playlist query from query_playlist()
# token (character): authorization token provided by either get_tokens() or refresh_token()

analyze_playlist_features <- function (info, token) {
  
  # playlist name
  name <- info$name
  
  # target popularity
  popularity <- info$popularity
  
  # find the total number of tracks in the playlist
  ntracks <- info$total
  
  # acoustic features used by Spotify
  featnames <- c("danceability","energy","key","loudness","mode","speechiness","acousticness","instrumentalness","liveness","valence","tempo","time_signature")
  
  # preallocate an array of acoustic features for all songs in the playlist
  acdata <- as.data.frame(matrix(data=0,nrow=ntracks,ncol=length(featnames)))
  colnames(acdata) <- featnames
  
  # preallocate variables
  thistrack <- 1
  offset <- 0
  
  # since the API will only allow playlist request for 100 songs at a time, this main while loop will continue until the playlist is exhausted
  while (ntracks > offset) {
    
    # make GET request to query the playlist
    req <- httr::GET(paste0("https://api.spotify.com/v1/playlists/",info$ID,"/tracks/"),
                     httr::add_headers(
                       "Accept" = "application/json",
                       "Content-Type" = "application/json", 
                       "Authorization" = paste0("Bearer ", token)
                     ), query = list(offset=offset, limit=100))
    
    # convert results from JSON format
    result <- jsonlite::fromJSON(rawToChar(req$content))
    
    # if an API request limit has been hit, try again after requested cooldown period
    while (length(result)==1) {
      buffer <- req$all_headers[[1]]$headers$`retry-after`
      if (is.null(buffer)) {
        buffer <- "1"
      }
      print(paste0("Too many API requests. Trying again in ",buffer," second(s)."))
      Sys.sleep(as.numeric(buffer))
      
      # make new GET request to query the playlist
      req <- httr::GET(paste0("https://api.spotify.com/v1/playlists/",info$ID,"/tracks/"),
                       httr::add_headers(
                         "Accept" = "application/json",
                         "Content-Type" = "application/json", 
                         "Authorization" = paste0("Bearer ", token)
                       ), query = list(offset = offset, limit=100))
      
      # convert results from JSON format
      result <- jsonlite::fromJSON(rawToChar(req$content))
    }
    
    # loop through all tracks to get the features
    for (track in 1:length(result$items$track$track)) {
      
      # get track ID
      trID <- result$items$track$id[track]
      
      # get the acoustic/audio features associated with the track ID
      req <- httr::GET(paste0("https://api.spotify.com/v1/audio-features/",trID),
                       httr::add_headers("Authorization" = paste0("Bearer ", token)
                       ))
      
      # convert results from JSON format
      features <- jsonlite::fromJSON(rawToChar(req$content))
      
      # if an API request limit has been hit, try again after requested cooldown period
      while (length(features)==1) {
        buffer <- req$all_headers[[1]]$headers$`retry-after`
        if (is.null(buffer)) {
          buffer <- "1"
        }
        print(paste0("Too many API requests. Trying again in ",buffer," second(s)."))
        Sys.sleep(as.numeric(buffer))
        
        # get the acoustic/audio features associated with the track ID
        req <- httr::GET(paste0("https://api.spotify.com/v1/audio-features/",trID),
                         httr::add_headers("Authorization" = paste0("Bearer ", token)
                         ))
        
        # convert results from JSON format
        features <- jsonlite::fromJSON(rawToChar(req$content))
      }
      
      # add the features to data frame
      for (feature in featnames) {
        acdata[[feature]][thistrack] <- features[[feature]]
      }
      
      # iterate the track number
      thistrack <- thistrack + 1
    }
    # iterate the offset used for addtional playlist GET requests
    offset <- offset + length(result$items$track$track)
  }
  
  # PCA model of acoustic features
  pca <- prcomp(acdata, center=T, scale.=T)
  
  # Determine the variance explained by the PCs
  vars    <- apply(pca$x, 2, var)
  
  # Keep PCs with eigenvalues >= 1 (i.e., Kaiser criterion)
  tokeep  <- length(which(vars >= 1)) 
  
  # order the (absolute) scores for the retained PCs, to be used as a weighting
  orddat <- rowMeans(abs(pca$x[,1:tokeep]))
  orddat <- cbind(1:length(orddat),orddat)
  orddat <- orddat[order(orddat[,2],decreasing=T),]
  
  # retain the top weighted tracks, based on PC scores
  orddat <- orddat[orddat[,2]>=1,]
  
  # extract the PC loadings and apply weighting based on eigenvalues
  loadings <- pca$rotation[,1:tokeep]
  for (PC in 1:tokeep) {
    loadings[,PC] <- loadings[,PC]*vars[PC]
  }
  
  # sort the acoustic features based on importance
  sortfeatures <- sort(rowMeans(abs(loadings)),decreasing=T)
  
  # retain important acoustic features (mean - 1 SD)
  thresh <- mean(sortfeatures) - sd(sortfeatures)
  features <- sortfeatures[sortfeatures>=thresh]
  
  # get the relevant acoustic features for the retained tracks
  filtdat <- acdata[orddat[,1],names(features)]
  avgfeatures <- as.data.frame(t(colMeans(filtdat)))
  
  # for integer features, find the most common one
  if (!is.null(avgfeatures$key)) {
    avgfeatures$key <- as.numeric(names(rev(sort(table(filtdat$key))))[1])
  }
  if (!is.null(avgfeatures$mode)) {
    avgfeatures$mode <- as.numeric(names(rev(sort(table(filtdat$mode))))[1])
  }
  if (!is.null(avgfeatures$time_signature)) {
    avgfeatures$time_signature <- as.numeric(names(rev(sort(table(filtdat$time_signature))))[1])
  }
  
  payload <- c()
  # add the average feature values to the payload to be sent for playlist recommendation
  for (x in 1:length(features)) {
    payload[[paste0("target_",names(avgfeatures)[x])]] <- as.numeric(avgfeatures[x])
  }
  
  # add target popularity 
  payload$target_popularity <- popularity
  
  # add playlist name
  payload$name <- name
  
  return(payload)
}