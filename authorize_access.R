# Christopher Carignan, 2021
#
# authorize_access() opens a Spotify page in the browser to allow access to reading and writing user playlists.
# After granting access, the user must copy the entire browser address that appears in the redirect page.
#
# inputs
# clID (character): client ID from Spotify Developer web API

authorize_access <- function(clID) {
  
  authurl <- paste0("https://accounts.spotify.com/authorize?client_id=",
                    clID,"&scope=playlist-modify-private,playlist-modify-public",
                    "&response_type=code&redirect_uri=http://localhost:8888/callback/")
  
  utils::browseURL(authurl)
  
}