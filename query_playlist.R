# Christopher Carignan, 2021
#
# query_playlist() will access the user's playlist in order to get some initial information.
#
# inputs
# plID (character): the unique ID of the Spotify playlist to query
# token (character): authorization token provided by either get_tokens() or refresh_token()

query_playlist <- function (plID, token) {
  
  # the API URL of the playlist
  playlist <- paste0("https://api.spotify.com/v1/playlists/",plID)
  
  # make GET request to query the playlist
  req <- httr::GET(playlist, 
                   httr::add_headers(
                     "Accept" = "application/json",
                     "Content-Type" = "application/json", 
                     "Authorization" = paste0("Bearer ", token)
                   ))
  
  # convert results from JSON format
  result <- jsonlite::fromJSON(rawToChar(req$content))
  
  # playlist name
  name <- result$name
  
  # make GET request to query the playlist tracks
  req <- httr::GET(paste0(playlist,"/tracks"), 
                   httr::add_headers(
                     "Accept" = "application/json",
                     "Content-Type" = "application/json", 
                     "Authorization" = paste0("Bearer ", token)
                   ), query = list(offset = 0, limit=100))
  
  # convert results from JSON format
  result <- jsonlite::fromJSON(rawToChar(req$content))
  
  # add playlist name
  result$name <- name
  
  # get genres of first 100 songs (has to be done by artist, unfortunately)
  genres <- c()
  for (track in result$items$track$artists) {
    
    # extract info on track artist
    if (is.null(track[[1]]$id)) {
      artist <- track$id
    } else {
      artist <- track[[1]]$id
    }
    
    # if there are multiple artists, get the first one
    artist <- artist[1]
    
    # make GET request to query the artist info
    req <- httr::GET(paste0("https://api.spotify.com/v1/artists/",artist), 
                     httr::add_headers(
                       "Accept" = "application/json",
                       "Content-Type" = "application/json", 
                       "Authorization" = paste0("Bearer ", token)
                     ))
    # convert results from JSON format
    info <- jsonlite::fromJSON(rawToChar(req$content))
    
    # add genres
    for (genre in 1:length(info$genres)) {
      genres <- c(genres,info$genres[genre])
    }
  }
  
  # retain the top 5 genres
  genres <- names(rev(sort(table(genres)))[1:5])
  genres <- genres[!is.na(genres)]
  
  return(list(result,genres))
}