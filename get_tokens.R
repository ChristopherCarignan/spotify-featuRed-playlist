# Christopher Carignan, 2021
#
# get_tokens() provides a set of authorization and refresh tokens for further web API usage.
# The initial authorization token expires after 1 hour. If the user wants to continue using the API, they will need to get another token before the 
# expiration by using refresh_token() to get another token for 1 hour.
#
# inputs
# key (character): handshake key provided by handshake()
# clID (character): client ID from Spotify Developer web API
# secID (character): secret client ID from Spotify Devloper web API

get_tokens <- function(key, clID, secID) {
  
  # make POST request
  req <- httr::POST("https://accounts.spotify.com/api/token",
                    accept_json(),
                    body = list(
                      client_id = clID,
                      client_secret = secID,
                      grant_type = "authorization_code",
                      code = key,
                      scope = "playlist-modify-private,playlist-modify-public",
                      redirect_uri = "http://localhost:8888/callback/"
                    ), encode = "form")
  
  # convert results from JSON format
  tokenaccess <- jsonlite::fromJSON(rawToChar(req$content))
  
  # get tokens
  token <- tokenaccess$access_token
  refresh <- tokenaccess$refresh_token
  
  return(list(token,refresh))
}