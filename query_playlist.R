# Christopher Carignan, 2021
#
# query_playlist() will access the user's playlist in order to get some initial information.
#
# inputs
# plID (character): the unique ID of the Spotify playlist to query
# token (character): authorization token provided by either get_tokens() or refresh_token()

query_playlist <- function (plID, token) {
  
  # list of available Spotify music genre seeds
  available <- c(
    "acoustic",
    "afrobeat",
    "alt-rock",
    "alternative",
    "ambient",
    "anime",
    "black-metal",
    "bluegrass",
    "blues",
    "bossanova",
    "brazil",
    "breakbeat",
    "british",
    "cantopop",
    "chicago-house",
    "children",
    "chill",
    "classical",
    "club",
    "comedy",
    "country",
    "dance",
    "dancehall",
    "death-metal",
    "deep-house",
    "detroit-techno",
    "disco",
    "disney",
    "drum-and-bass",
    "dub",
    "dubstep",
    "edm",
    "electro",
    "electronic",
    "emo",
    "folk",
    "forro",
    "french",
    "funk",
    "garage",
    "german",
    "gospel",
    "goth",
    "grindcore",
    "groove",
    "grunge",
    "guitar",
    "happy",
    "hard-rock",
    "hardcore",
    "hardstyle",
    "heavy-metal",
    "hip-hop",
    "holidays",
    "honky-tonk",
    "house",
    "idm",
    "indian",
    "indie",
    "indie-pop",
    "industrial",
    "iranian",
    "j-dance",
    "j-idol",
    "j-pop",
    "j-rock",
    "jazz",
    "k-pop",
    "kids",
    "latin",
    "latino",
    "malay",
    "mandopop",
    "metal",
    "metal-misc",
    "metalcore",
    "minimal-techno",
    "movies",
    "mpb",
    "new-age",
    "new-release",
    "opera",
    "pagode",
    "party",
    "philippines-opm",
    "piano",
    "pop",
    "pop-film",
    "post-dubstep",
    "power-pop",
    "progressive-house",
    "psych-rock",
    "punk",
    "punk-rock",
    "r-n-b",
    "rainy-day",
    "reggae",
    "reggaeton",
    "road-trip",
    "rock",
    "rock-n-roll",
    "rockabilly",
    "romance",
    "sad",
    "salsa",
    "samba",
    "sertanejo",
    "show-tunes",
    "singer-songwriter",
    "ska",
    "sleep",
    "songwriter",
    "soul",
    "soundtracks",
    "spanish",
    "study",
    "summer",
    "swedish",
    "synth-pop",
    "tango",
    "techno",
    "trance",
    "trip-hop",
    "turkish",
    "work-out",
    "world-music"
  )
  
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
  
  # get genres and popularity of first 100 songs (has to be done by artist, unfortunately)
  genres <- c()
  popularity <- c()
  for (track in result$items$track$artists) {
    
    # extract info on track artist
    if (is.null(track[[1]]$id)) {
      artists <- track$id
    } else {
      artists <- track[[1]]$id
    }
    
    # if there are multiple artists, get info on each one
    for (artist in artists) {
      
      # make GET request to query the artist info
      req <- httr::GET(paste0("https://api.spotify.com/v1/artists/",artist), 
                       httr::add_headers(
                         "Accept" = "application/json",
                         "Content-Type" = "application/json", 
                         "Authorization" = paste0("Bearer ", token)
                       ))
      # convert results from JSON format
      info <- jsonlite::fromJSON(rawToChar(req$content))
      
      # if an API request limit has been hit, try again after 5 seconds
      while (length(info)==1) {
        print("Too many API requests. Trying again in 5 seconds.")
        Sys.sleep(5)
        
        # make new GET request to query the artist info
        req <- httr::GET(paste0("https://api.spotify.com/v1/artists/",artist), 
                         httr::add_headers(
                           "Accept" = "application/json",
                           "Content-Type" = "application/json", 
                           "Authorization" = paste0("Bearer ", token)
                         ))
        # convert results from JSON format
        info <- jsonlite::fromJSON(rawToChar(req$content))
      }
      
      # add genres
      if (length(info$genres)>0) {
        for (genre in 1:length(info$genres)) {
          genres <- c(genres,info$genres[genre])
        }
      }
      
      # add popularity
      popularity <- c(popularity,info$popularity)
    }
  }
  
  
  # change some genre names to match available API queries
  genres[genres=="psychedelic rock"] <- "psych-rock"
  genres[genres=="hard rock"] <- "hard-rock"
  
  # retain and sort genres that match available API queries
  genres <- genres[genres %in% available]
  genres <- sort(table(genres),decreasing=T)
  
  # reduce to 5 genres if need be
  if (length(genres)>=5) {
    genres <- genres[1:5]
  }
  
  # retain the top genres (by standard deviation of counts)
  if (length(genres)>1) {
    genres <- names(genres[genres>sd(genres)])
  } else {
    genres <- names(genres)
  }
  
  # add the average popularity
  result$popularity <- round(mean(popularity))
  
  return(list(result,genres))
}