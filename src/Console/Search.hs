
module Console.Search(actionSearch) where

import CmdLine.All
import Data.Range
import Data.TagStr
import General.Code
import Hoogle.Query.All
import Hoogle.Search.All
import Hoogle.Item.All
import Data.Binary.Defer.Index


actionSearch :: CmdLine -> Query -> IO ()
actionSearch flags q = do
    (missing,dbs) <- loadQueryDatabases (databases flags) q
    unless (null missing) $
        error $ "Could not find some databases: " ++ unwords missing

    let sug = suggestQuery dbs q
    when (isJust sug) $
        putStrLn $ showTag $ fromJust sug
    when verbose $ putStrLn "= ANSWERS ="

    when (isJust (typeSig q) && color flags) $ do
        let view = [ArgPosNum i i | i <- [0..10]]
            tags = renderEntryText view $ renderTypeSig $ fromJust $ typeSig q
        putStrLn $ "Searching for: " ++ showTag tags

    let res = search dbs q
    if null res then
        putStrLn "No results found"
     else if info flags then do
        let ent = fromLink $ resultEntry $ head res
            pkg = fromLink $ entryPackage ent
        putStrLns 2 $ f $ renderResult $ head res
        putStrLns 2 $ showTag $ renderHaddock $ entryDocs ent
        putStrLn $ "From package " ++ packageName pkg ++ ", version " ++ packageVersion pkg
        putStrLns 1 $ entryURL ent
     else
        putStr $ unlines $ map (f . renderResult) res
    where
        search | start2 == 0 && count2 == maxBound = searchAll
               | otherwise = searchRange (rangeStartCount start2 count2)
            where start2 = maybe 0 (subtract 1) $ start flags
                  count2 = fromMaybe maxBound $ count flags

        showTag = if color flags then showTagConsole else showTagText
        verbose = False

        f (m,r,v) = maybe "" (\m -> showModule m ++ " ") m ++
                    showTag r ++ (if verbose then "  -- " ++ v else "")


-- Put out a string with some blank links following
-- Do not put out the blank lines if no text output
putStrLns :: Int -> String -> IO ()
putStrLns n xs = when (xs /= "") $ do
                     putStr xs
                     putStr $ replicate n '\n'
