# Christopher Carignan, 2021
#
# refresh_tokens() will refresh an additional authorization token for further web API usage.
# The authorization token expires after 1 hour. Run this function again within that time to receive another authorization token for 1 hour.
#
# inputs
# refresh (character): refresh token provided by get_tokens()
# clID (character): client ID from Spotify Developer web API
# secID (character): secret client ID from Spotify Devloper web API

refresh_token <- function (refresh, clID, secID) {
  
  # make POST request to refresh the authorization token
  req <- httr::POST("https://accounts.spotify.com/api/token",
                    accept_json(),
                    body = list(
                      client_id = clID,
                      client_secret = secID,
                      grant_type = "refresh_token",
                      refresh_token = refresh
                    ), encode = "form")
  
  # convert results from JSON format
  tokenaccess <- jsonlite::fromJSON(rawToChar(req$content))
  
  # get token
  token <- tokenaccess$access_token
  
  return(token)
}