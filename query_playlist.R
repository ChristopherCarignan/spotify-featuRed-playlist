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
                   add_headers(
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
                   add_headers(
                     "Accept" = "application/json",
                     "Content-Type" = "application/json", 
                     "Authorization" = paste0("Bearer ", token)
                   ), query = list(offset = 0, limit=100))
  
  # convert results from JSON format
  result <- jsonlite::fromJSON(rawToChar(req$content))
  
  # add playlist name
  result$name <- name
  
  return(result)
}