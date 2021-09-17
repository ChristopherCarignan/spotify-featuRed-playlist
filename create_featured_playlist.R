# Christopher Carignan, 2021
#
# created_featured_playlist() will create a customized playlist based on the acoustic features retained from analyze_playlist_features().
# The Spotify API does not allow for searching by these features alone, but requires at least one seed for track, artist, and/or genre.
# I have chosen to make the seed by genre, so that the user can generate any number of different playlists containing music that matches the target
# acoustic/audio feature values, but from a wide range of genres. Make a playlist for any genre you like! 
#
# NB: a full list of the available genre names is given in genres.R
#
# inputs
# payload (list): the result of the acoustic/audio feature analysis from analyze_playlist_features()
# genre (character): a music genre name, to be used as a seed in playlist recommendation
# ntracks (integer): number of desired songs to appear in the playlist
# userID (character): the user's Spotify profile name; the playlist will be saved to this user profile
# token (character): authorization token provided by either get_tokens() or refresh_token()

create_featured_playlist <- function (payload, genre, ntracks, userID, token) {
  
  if (ntracks > 100) {
    stop("You can request a maximum of 100 tracks!")
  }
  
  # extract playlist name
  name <- payload$name
  
  # remove playlist name from payload
  payload <- payload[1:(length(payload)-1)]
  
  # add the genre and track number to the payload of acoustic features
  payload <- c(list(seed_genres = noquote(paste0(genre,collapse=",")), limit = ntracks), payload)
  
  # make GET request to obtain recommendations
  rec <- httr::GET("https://api.spotify.com/v1/recommendations",
                   httr::add_headers(
                     "Accept" = "application/json",
                     "Content-Type" = "application/json", 
                     "Authorization" = paste0("Bearer ", token)
                   ),
                   query = payload, encode = "form")
  
  # convert results from JSON format
  recpl <- jsonlite::fromJSON(rawToChar(rec$content))
  
  # sometimes a result will not be returned if there are too many acoustic parameters used
  # in this case, the request is iterated, removing one acoustic feature each time, until a successful GET request is obtained
  while (length(recpl)==1) {
    
    # remove one feature (the least important in the current list of features)
    payload <- payload[1:(length(payload)-1)]
    
    # make new GET request to obtain recommendations
    rec <- httr::GET("https://api.spotify.com/v1/recommendations",
                     httr::add_headers(
                       "Accept" = "application/json",
                       "Content-Type" = "application/json", 
                       "Authorization" = paste0("Bearer ", token)
                     ),
                     query = payload, encode = "form")
    
    # convert results from JSON format
    recpl <- jsonlite::fromJSON(rawToChar(rec$content))
  }
  
  
  # make POST request to create an empty playlist in the user's profile
  if (length(genre)==1) {
  req <- httr::POST(paste0("https://api.spotify.com/v1/users/",userID,"/playlists"),
                    httr::accept_json(),
                    httr::add_headers(
                      "Accept" = "application/json",
                      "Content-Type" = "application/json", 
                      "Authorization" = paste0("Bearer ", token)
                    ),
                    body = list(
                      name = paste0("featuRed: ",name," (", payload$seed_genres, ")"),
                      description = "Recommended playlist based on acoustic feature patterns",
                      public = "false"
                    ), encode = "json")
  } else {
    req <- httr::POST(paste0("https://api.spotify.com/v1/users/",userID,"/playlists"),
                      httr::accept_json(),
                      httr::add_headers(
                        "Accept" = "application/json",
                        "Content-Type" = "application/json", 
                        "Authorization" = paste0("Bearer ", token)
                      ),
                      body = list(
                        name = paste0("featuRed: ",name),
                        description = "Recommended playlist based on acoustic feature patterns",
                        public = "false"
                      ), encode = "json")
  }
  
  # convert results from JSON format
  newpl <- jsonlite::fromJSON(rawToChar(req$content))
  
  # get the unique ID associated with the newly created playlist
  plID <- newpl$id
  
  # break up the requested tracks into blocks of 50 to avoid URLs that are too long
  blocks <- 50*(0:(ntracks %/% 50))
  if (ntracks %% 50 > 0) {
    blocks <- c(blocks, ntracks %% 50 + blocks[length(blocks)])
  }
  
  for (block in 1:(length(blocks)-1) ) {
    # get the number of tracks for this block
    tracks <- (blocks[block]+1):blocks[block+1]
    
    # get the URIs associated with the recommended tracks
    rectracks <- noquote(paste0(recpl$tracks$uri[tracks],collapse=","))
    
    # make POST request to add the tracks to the playlist
    savedpl <- httr::POST(paste0("https://api.spotify.com/v1/playlists/",plID,"/tracks"),
                          httr::add_headers(
                            "Accept" = "application/json",
                            "Content-Type" = "application/json", 
                            "Authorization" = paste0("Bearer ", token)
                          ),
                          query = list(
                            uris = rectracks
                          ), encode = "form")
  }
}