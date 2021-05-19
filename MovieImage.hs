{-# LANGUAGE OverloadedStrings #-}

module MovieImage where


import Control.Monad.IO.Class
import Data.Maybe (fromMaybe)
import Data.Aeson
import Data.Aeson.Types
import Network.HTTP.Req

data MovieInfo = MovieInfo { imageUrl :: String }

instance FromJSON MovieInfo where
    parseJSON = withObject "response object" $ \o -> do
        res <- o .: "results"
        url <- head res .: "backdrop_path"
        return $ MovieInfo url

movieMain :: IO String
-- You can either make your monad an instance of 'MonadHttp', or use
-- 'runReq' in any IO-enabled monad without defining new instances.
movieMain = runReq defaultHttpConfig $ do
  let apiKey = ""
  -- One function—full power and flexibility, automatic retrying on timeouts
  -- and such, automatic connection sharing.
  r <- req GET (https "api.themoviedb.org" /: "3" /: "search" /: "movie") NoReqBody jsonResponse ("api_key" =: (apiKey :: String) <> "query" =: ("Trainspotting" :: String))
  let p = parseMaybe (parseJSON :: Value -> Parser MovieInfo) (responseBody r)
  return $ maybe "Parsing Failed\n" imageUrl p
