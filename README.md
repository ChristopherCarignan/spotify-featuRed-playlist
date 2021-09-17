# spotify-featuRed-playlist
Creates a custom Spotify playlist of recommended songs based on the most prevalent acoustic features across songs in a playlist provided by the user.

# Before starting
In order to use the API functions that are required for reading and writing to Spotify's data base, you must first create a Spotify Developer account (it's free, don't worry!) at [https://developer.spotify.com/dashboard/](https://developer.spotify.com/dashboard/).

Once you have an account, you will need to create your own app (call it whatever you like, it doesn't matter here) from the Dashboard. This will allow you to obtain a Client ID and a Client Secret, both of which you will need in order to use these R functions. 

When you have created your app and obtained your Client ID and Client Secret, the last thing you need to do is add the following Redirect URI after clicking on "EDIT SETTINGS". The URI must be written exactly as shown below, and you must click "SAVE" afterwards:

http://localhost:8888/callback/


# Getting started
The following R packages must first be installed locally on your computer before running these functions:

- jsonlite
- httr
- utils
- stringr

First, save your Spotify user ID and the playlist ID as the following variable names (the playlist ID string can be obtained by opening the playlist in the Spotify web browser and copying it from the address). The playlist ID shown below is for a Led Zeppelin playlist:

    userID <- "myusername"
    
    plID <- "4Tpa0M0JpNF5FVDoddUToF"


Now save your Client ID and Secret Client from your Developer account:

    clID <- "35fd[...]c7ac"
    
    secID <- "4Tpa[...]UToF"



# Authorization
There are a number of authorization steps that you need to take in order to give R to read/write access to your Spotify playlists. The first function will open a browser window to enable you to grant access to R:

    authorize_access(clID)


At this point you will be redirected to a blank web page... that's good! Take a look at the address in your browser: there should be a lot of stuff in there. Copy the entire address line and use it as a string input to the handshake function:

    key <- handshake("http://localhost:8888/callback/?code=AQCJ[...]OVjK")


If you've done this correctly, you can now get authorization tokens using the key output from the handshake function:


    tokens <- get_tokens(key, clID, secID)


There are two types of tokens you can extract from this list: the initial authorization token, and a refresh token:

    token <- tokens[[1]]
    
    refresh <- tokens[[2]]


The initial authorization token is only active for 1 hour. If the token expires, you'll need to do the whole browser authorization from the beginning. However, you can refresh the token to obtain a new one at any point within that hour window, and you'll get a new authorization token that will be good for another hour:


    token <- refresh_token(refresh, clID, secID)



# Analyzing the playlist
Now that all of the authorization has been taken care of, we can get down to business! 

Spotify has done a lot of acoustic analysis on their song base, which (I'm assuming) is what they generally use in making recommendations. However, some of those recommendations can be a bit heavy-handed and focused on specific artists that show up often in the playlist. What we're going to do here is remove that constraint and make recommendations on <em>patterns</em> that underly the acoustic features in your playlist. Pretty cool, huh?

The first thing to do is get some basic information about the playlist you want to analyze. This will include all of the regular playlist info provided by the Spotify API, but also a list of the 5 most common genres in the (up to) 100 first songs in the playlist:


    plfeatures <- query_playlist(plID, token)
    
    features <- plfeatures[[1]]
    
    genres <- plfeatures[[2]]



Now here comes the fun bit. The next function will analyze all of the acoustic/audio features for all of the songs in your playlist, and perform a principal components analysis (PCA) on all of these features. This will extract underlying patterns in your listening habits that you probably didn't even know were there! This function may take a bit of time if you have many songs in the playlist, because we'll need to take some breaks if your API requests are getting too quick/numerous:


    payload <- analyze_playlist_features(plfeatures, token)


# Generating a recommended playlist
The hard part is done! 

Now that you have analyzed your initial playlist, you can generate <em>new</em> playlists full of songs that have <em>similar acoustic features</em> associated with those hidden, underlying patterns in your listening habits. The recommendation will also be based on genres, so you can either use the 5 most common genres already extracted from your initial playlist... 

    create_featured_playlist(payload, genres, 50, userID, token)

...or you can provide a completely different genre! The cool thing is that you can do this for any music genre you want: make a country music list based on your hip-hop listening habits, or a punk list based on your classical music habits! A full list of the available genre names is given in the "genres.R" file. You can also control how many songs are in the playlist (100 maximum).

Here's an example for a folk playlist of 50 songs, which match the acoustic features of the Led Zeppelin example playlist we're using here:


    create_featured_playlist(payload, "folk", 50, userID, token)


At this point, the playlist should be saved to your Spotify account. Now go listen!