{-# LANGUAGE OverloadedStrings #-}

module MovieImage where

import Control.Monad.IO.Class
import Data.Maybe
import Data.Aeson
import Data.Aeson.Types
import Network.HTTP.Req

data MovieInfo = MovieInfo { imgUrl :: String }
data Category = Movie | TV

instance FromJSON MovieInfo where
    parseJSON = withObject "response object" $ \o -> do
        res <- o .: "results"
        --url <- maybe (pure "") (\res -> catMaybes [(res .:? "backdrop_path"), (res.:? "poster_path")]) (listToMaybe res)
        case listToMaybe res of
          Just res -> do img1 <- res .:? "backdrop_path"
                         img2 <- res .:? "poster_path"
                         return $ MovieInfo $ fromMaybe "" (listToMaybe $ catMaybes [img1, img2])
          Nothing -> return $ MovieInfo ""
        --let maybeUrl = listToMaybe res >>= \res ->
        --               listToMaybe $ catMaybes [(res .:? "backdrop_path"), (res.:? "poster_path")]
        --url <- fromMaybe (pure "") maybeUrl
        --return $ MovieInfo url

getImg :: Category -> String -> String -> IO String
-- You can either make your monad an instance of 'MonadHttp', or use
-- 'runReq' in any IO-enabled monad without defining new instances.
getImg category movieName year = runReq defaultHttpConfig $ do
  let apiKey = "a2a1775c85aa5feced8de95a9c8370f7"
  -- One function—full power and flexibility, automatic retrying on timeouts
  -- and such, automatic connection sharing.
  let category = case cat of
              Movie = "movie"
              TV    = "tv"
  r <- req GET
           (https "api.themoviedb.org" /: "3" /: "search" /: category)
           NoReqBody
           jsonResponse
           ("api_key" =: (apiKey :: String) <> "query" =: (movieName :: String) <> "year" =: year <> "include_adult" =: ("true" :: String))
  let p = parseMaybe (parseJSON :: Value -> Parser MovieInfo) (responseBody r)
  return $ maybe "Parsing Failed\n" imgUrl p
