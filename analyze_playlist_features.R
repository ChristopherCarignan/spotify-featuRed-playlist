# Christopher Carignan, 2021
#
# analyze_playlist_features() analyzes 11 different acoustic/audio features from each song in the user's playlist. 
# The results are submitted to a principal components analysis (PCA) model in order to find the underlying dimensions shared by these features.
# Principal components (PCs) with eigenvalues >= 1 are retained for feature extraction.
# The acoustic features that are most heavily weighted across the retained PCs are used for feature estimation of playlist recommendation.
#
# inputs
# result (list): the result of the playlist query from query_playlist()
# token (character): authorization token provided by either get_tokens() or refresh_token()

analyze_playlist_features <- function (result, token) {
  
  # playlist name
  name <- result$name
  
  # find the total number of tracks in the playlist
  ntracks <- result$total
  
  # extract the playlist URL
  playlist <- stringr::str_remove(result$href, '\\?offset=0\\&limit=100')
  
  # acoustic features used by Spotify
  featnames <- c("danceability","energy","key","loudness","mode","speechiness","acousticness","instrumentalness","liveness","valence","tempo")
  
  # preallocate an array of acoustic features for all songs in the playlist
  acdata <- as.data.frame(matrix(data=0,nrow=ntracks,ncol=length(featnames)))
  colnames(acdata) <- featnames
  
  # preallocate variables
  thistrack <- 1
  offset <- 0
  
  # since the API will only allow playlist request for 100 songs at a time, the main while loop will continue until the playlist is exhausted
  while (ntracks > offset) {
    
    # make GET request to query the playlist
    req <- httr::GET(playlist, 
                     add_headers(
                       "Accept" = "application/json",
                       "Content-Type" = "application/json", 
                       "Authorization" = paste0("Bearer ", token)
                     ), query = list(offset = offset, limit=100))
    
    # convert results from JSON format
    result <- jsonlite::fromJSON(rawToChar(req$content))
    
    # if an API request limit has been hit, try again after 5 seconds
    while (length(result)==1) {
      print("Too many API requests. Trying again in 5 seconds.")
      Sys.sleep(5)
      
      # make new GET request to query the playlist
      req <- httr::GET(playlist, 
                       add_headers(
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
      features <- httr::GET(paste0("https://api.spotify.com/v1/audio-features/",trID),
                            add_headers("Authorization" = paste0("Bearer ", token)
                            ))
      
      # convert results from JSON format
      features <- jsonlite::fromJSON(rawToChar(features$content))
      
      # if an API request limit has been hit, try again after 5 seconds
      while (length(features)==1) {
        print("Too many API requests. Trying again in 5 seconds.")
        Sys.sleep(5)
        
        # get the acoustic/audio features associated with the track ID
        features <- httr::GET(paste0("https://api.spotify.com/v1/audio-features/",trID),
                              add_headers("Authorization" = paste0("Bearer ", token)
                              ))
        
        # convert results from JSON format
        features <- jsonlite::fromJSON(rawToChar(features$content))
      }
      for (feature in featnames) {
        # add the features to data frame
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
  
  # order the acoustic features by their (absolute) weightings for the retained PCs
  orddat <- rev(sort(rowMeans(abs(pca$rotation[,1:tokeep]))))
  
  # retain the relevant acoustic features
  avgfeatures <- as.data.frame(t(colMeans(acdata)))
  avgfeatures <- avgfeatures[,names(orddat)]
  
  payload <- c()
  # add the average feature values to the payload to be sent for playlist recommendation
  for (x in 1:tokeep) {
    payload[[paste0("target_",names(avgfeatures)[x])]] <- as.numeric(avgfeatures[x])
  }
  
  # add playlist name
  payload <- c(list(name = name), payload)
  
  return(payload)
}