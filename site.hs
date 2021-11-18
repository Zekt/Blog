{-# LANGUAGE ViewPatterns #-}
{-# LANGUAGE LambdaCase #-}
{-# LANGUAGE ScopedTypeVariables #-}
--------------------------------------------------------------------------------
{-# LANGUAGE OverloadedStrings #-}
import           Data.Maybe
import           Data.Monoid                   (mappend)
import           Data.List                     (sortBy)
import           Data.Ord                      (comparing)
import           Hakyll
import           Control.Monad                 (liftM, liftM2, forM_, filterM, mapM, join, foldM)
import           System.FilePath               (takeBaseName)
import           System.Environment            (getArgs)
import           MovieImage

--------------------------------------------------------------------------------

main :: IO ()
main = getArgs >>= \args ->
    let baseCtx = if elem "watch" args
                      then constField "baseurl" "http://localhost:8000"
                      else constField "baseurl" "https://viktorl.in/Blog"
        siteCtx :: Context String
        siteCtx =
            baseCtx `mappend`
            constField "site_description" "" `mappend`
            constField "site-url" "https://zekt.github.io/Blog" `mappend`
            constField "tagline" "& Absurd Reasoning" `mappend`
            constField "site-title" "Literally Programming" `mappend`
            constField "copy-year" "2021" `mappend`
            constField "github-repo" "https://github.com/Zekt/Blog" `mappend`
            defaultContext

        baseNodeCtx :: Context String
        baseNodeCtx =
            urlField "node-url" `mappend`
            titleField "title" `mappend`
            baseCtx
        
        baseSidebarCtx = sidebarCtx baseNodeCtx
    in
    hakyll $ do
    match ("images/**" .||. "js/*") $ do
        route   idRoute
        compile copyFileCompiler

    match "css/**" $ do
        route   idRoute
        compile compressCssCompiler

    match "error/*" $ do
        route (gsubRoute "error/" (const "") `composeRoutes` setExtension "html")
        compile $ pandocCompiler
            >>= applyAsTemplate siteCtx
            >>= loadAndApplyTemplate "templates/default.html" (baseSidebarCtx <> siteCtx)

    match "pages/*" $ do
        route $ setExtension "html"
        compile $ do
            pageName <- takeBaseName . toFilePath <$> getUnderlying
            let pageCtx = constField pageName "" `mappend`
                          baseNodeCtx
            let evalCtx = functionField "get-meta" getMetadataKey `mappend`
                          functionField "eval" (evalCtxKey pageCtx)
            let activeSidebarCtx = sidebarCtx (evalCtx <> pageCtx)

            pandocCompiler
                >>= saveSnapshot "page-content"
                >>= loadAndApplyTemplate "templates/page.html"    siteCtx
                >>= loadAndApplyTemplate "templates/default.html" (activeSidebarCtx <> siteCtx)
                >>= relativizeUrls

    tags <- buildTags "posts/*" (fromCapture "tags/*.html")

    tagsRules tags $ \tag pattern -> do
        let title = "Posts tagged \"" ++ tag ++ "\""
        --if tag == "電影" then route (constRoute "movies.html") else route idRoute
        route idRoute
        compile $ do
            posts <- recentFirst =<< loadAll pattern
            let ctx = constField "title" title
                      `mappend` listField "posts" (postCtxWithTags tags) (return posts)
                      `mappend` (baseSidebarCtx <> siteCtx)

            --makeItem ""
            --  >>= loadAndApplyTemplate "templates/comments.html" ctx
            --  >>= saveSnapshot "movies"
            
            makeItem ""
                >>= loadAndApplyTemplate "templates/tag.html" ctx
                >>= loadAndApplyTemplate "templates/default.html" ctx
                >>= relativizeUrls

    match "posts/*" $ version "meta" $ do
        route   $ setExtension "html"
        compile getResourceBody

    match "posts/*" $ do
        route $ setExtension "html"
        compile $ do
            posts <- loadAll ("posts/*" .&&. hasVersion "meta")
            let taggedPostCtx = postCtxWithTags tags          `mappend`
                                relatedPostsCtx posts 3
            pandocCompiler
                >>= applyAsTemplate baseNodeCtx
                >>= saveSnapshot "content"
                >>= loadAndApplyTemplate "templates/post.html" taggedPostCtx
                >>= loadAndApplyTemplate "templates/default.html" (taggedPostCtx <> baseSidebarCtx <> siteCtx)
                >>= relativizeUrls

    create ["movies.html"] $ do
        route idRoute
        compile $ do
            posts <- recentFirst =<< loadAllSnapshots ("posts/*" .&&. hasNoVersion) "content"
            selectedPosts <- filterM (fmap isJust . isComment) posts
            let ctx = postCtx <>
                      field
                        "movie_image_url"
                        (\item -> isComment item >>= \case
                                    Just c -> getMetadataField' (itemIdentifier item) "movie_title1" >>= \name ->
                                              getMetadataField (itemIdentifier item) "year" >>= \year ->
                                              unsafeCompiler (getImg c name $ fromMaybe "" year)
                                    Nothing -> return "")
            let archiveCtx =
                    listField "posts" ctx (return selectedPosts) `mappend`
                    constField "title" "Movies"                  `mappend`
                    constField "movies" ""                       `mappend`
                    siteCtx

            makeItem ""
                >>= loadAndApplyTemplate "templates/comments.html" archiveCtx
                >>= loadAndApplyTemplate "templates/default.html" (baseSidebarCtx <> archiveCtx)
                >>= relativizeUrls
            --let archiveCtx =
            --        constField "title" "Movies"       `mappend`
            --        constField "movies" ""            
            --        siteCtx
            --        --listField "posts"
            --        --          (postCtx <>
            --        --           field
            --        --             "movie_image_url"
            --        --             (\item -> case isComment item of
            --        --                         Just _ -> getMetadataField' (itemIdentifier item) "movie_title1" >>= \name ->
            --        --                                   getMetadataField (itemIdentifier item) "year" >>= \year ->
            --        --                                   unsafeCompiler (getImg name $ fromMaybe "" year)
            --        --                         Nothing -> return "")
            --        --          (return selectedPosts) `mappend`
            --    >>= loadAndApplyTemplate "templates/comments.html" archiveCtx
            --    >>= loadAndApplyTemplate "templates/default.html" (baseSidebarCtx <> archiveCtx)
            --    >>= relativizeUrls

    create ["archive.html"] $ do
        route idRoute
        compile $ do
            posts <- recentFirst =<< loadAllSnapshots ("posts/*" .&&. hasNoVersion) "content"
            let archiveCtx =
                    listField "posts" postCtx (return posts) `mappend`
                    constField "title" "Archive"             `mappend`
                    constField "archive" ""                  `mappend`
                    siteCtx

            makeItem ""
                >>= loadAndApplyTemplate "templates/archive.html" archiveCtx
                >>= loadAndApplyTemplate "templates/default.html" (baseSidebarCtx <> archiveCtx)
                >>= relativizeUrls

    create ["tag-cloud.html"] $ do
        route idRoute
        compile $ do
            tagCloud <- renderTagCloud 100.0 300.0 tags
            let tagsCtx =
                    constField "tags" tagCloud     `mappend`
                    constField "tag-cloud" ""      `mappend`
                    siteCtx

            makeItem ""
                >>= loadAndApplyTemplate "templates/tag-cloud.html" tagsCtx
                >>= loadAndApplyTemplate "templates/default.html" (baseSidebarCtx <> tagsCtx)
                >>= relativizeUrls

    paginate <- buildPaginateWith postsGrouper "posts/*" postsPageId

    paginateRules paginate $ \page pattern -> do
        route idRoute
        compile $ do
            posts <- recentFirst =<< loadAllSnapshots (pattern .&&. hasNoVersion) "content"
            let indexCtx =
                    constField "title" (if page == 1 then "Home"
                                                     else "Blog posts, page " ++ show page) `mappend`
                    listField "posts" postCtx (return posts) `mappend`
                    constField "home" ""                     `mappend`
                    paginateContext paginate page            `mappend`
                    siteCtx

            makeItem ""
                >>= applyAsTemplate indexCtx
                >>= loadAndApplyTemplate "templates/index.html" indexCtx
                >>= loadAndApplyTemplate "templates/default.html" (baseSidebarCtx <> indexCtx)
                >>= relativizeUrls

    match "templates/*" $ compile templateBodyCompiler

    create ["atom.xml"] $ do
        route idRoute
        compile $ do
            let feedCtx = postCtx `mappend`
                    bodyField "description"
            posts <- fmap (take 10) . recentFirst =<< loadAllSnapshots ("posts/*" .&&. hasNoVersion) "content"
            renderAtom feedConfig feedCtx posts

--------------------------------------------------------------------------------

postsGrouper :: (MonadMetadata m, MonadFail m) => [Identifier] -> m [[Identifier]]
postsGrouper = liftM (paginateEvery 5) . sortRecentFirst

postsPageId :: PageNumber -> Identifier
postsPageId n = fromFilePath $ if n == 1 then "index.html" else show n ++ "/index.html"

--------------------------------------------------------------------------------

feedConfig :: FeedConfiguration
feedConfig = FeedConfiguration
    { feedTitle       = "Literally Programming"
    , feedDescription = ""
    , feedAuthorName  = "Viktor Lin "
    , feedAuthorEmail = "hi@viktorl.in"
    , feedRoot        = "https://zekt.github.io/Blog"
    }

--------------------------------------------------------------------------------

postCtx :: Context String
postCtx =
    dateField "date" "%B %e, %Y" `mappend`
    defaultContext

postCtxWithTags :: Tags -> Context String
postCtxWithTags tags = tagsField "tags" tags `mappend` postCtx

tagsRulesVersioned tags rules =
    forM_ (tagsMap tags) $ \(tag, identifiers) ->
        rulesExtraDependencies [tagsDependency tags] $
            create [tagsMakeId tags tag] $
                rules tag identifiers

relatedPostsCtx
  :: [Item String]  -> Int  -> Context String
relatedPostsCtx posts n = listFieldWith "related_posts" postCtx selectPosts
  where
    rateItem ts i = length . filter (`elem` ts) <$> (getTags $ itemIdentifier i)
    selectPosts s = do
      postTags <- getTags $ itemIdentifier s
      let trimmedItems = filter (not . matchPath s) posts
      take n . reverse <$> sortOnM (rateItem postTags) trimmedItems

matchPath :: Item String -> Item String -> Bool
matchPath x y = eqOn (toFilePath . itemIdentifier) x y

eqOn :: Eq b => (a -> b) -> a -> a -> Bool
eqOn f x y = f x == f y

sortOnM :: (Monad m, Ord b) => (a -> m b) -> [a] -> m [a]
sortOnM f xs = map fst . sortBy (comparing snd) . zip xs <$> mapM f xs

--------------------------------------------------------------------------------

sidebarCtx :: Context String -> Context String
sidebarCtx nodeCtx =
    listField "list_pages" nodeCtx (loadAllSnapshots ("pages/*" .&&. hasNoVersion) "page-content") `mappend`
    defaultContext


evalCtxKey :: Context String -> [String] -> Item String -> Compiler String
evalCtxKey context [key] item = unContext context key [] item >>= \case
            StringField s -> return s
            _             -> error "Internal error: StringField expected"

getMetadataKey :: [String] -> Item String -> Compiler String
getMetadataKey [key] item = getMetadataField' (itemIdentifier item) key

isComment :: Item a -> Compiler (Maybe Category)
isComment item = do
  meta <- getMetadata (itemIdentifier item)
  return $ lookupStringList "tags" meta >>= f
  where
    f res 
      | "電影" `elem` res = Just Movie
      | "影集" `elem` res = Just TV
      | otherwise = Nothing