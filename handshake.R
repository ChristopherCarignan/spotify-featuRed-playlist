# Christopher Carignan, 2021
#
# handshake() returns a handshake key for granting access to user playlists
#
# inputs
# accessURL (character): the entire browser address that appears in the redirect page when completing authorization from authorize_access()

handshake <- function(accessURL) {

  key <- stringr::str_remove(accessURL, 'http://localhost:8888/callback/\\?code=')
  
  return(key)
  
}