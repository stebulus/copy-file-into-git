{-# LANGUAGE OverloadedStrings #-}
module Main where

import           Control.Exception (ErrorCall(..))
import           Control.Monad.Catch (MonadThrow, throwM)
import           Control.Monad.Loops (firstM)
import qualified Data.ByteString as B
import           Data.Monoid ((<>))
import           Data.Tagged (Tagged(unTagged))
import qualified Data.Text as T
import           Data.Text.Encoding (decodeUtf8, encodeUtf8)
import           Git
import           Git.Libgit2 (lgFactory)
import           System.Directory (canonicalizePath, doesDirectoryExist)
import           System.Environment (getArgs, getProgName)
import           System.Exit (exitFailure)
import           System.FilePath ((</>), makeRelative, takeDirectory)
import           System.IO (hPutStrLn, stderr)

cpIntoGit :: FilePath -> FilePath -> RefName -> TreeFilePath -> IO String
cpIntoGit src gitdir ref dest = do
    bytes <- B.readFile src
    withRepository lgFactory gitdir $ do
        moid <- resolveReference ref
        obj <- case moid of
            Nothing -> panic $ T.unpack ref ++ " doesn't resolve"
            Just oid -> lookupObject oid
        hd <- case obj of
            CommitObj hd -> return hd
            _ -> panic $ T.unpack ref ++ " isn't a commit"
        bloboid <- createBlob (BlobString bytes)
        treeoid <- mutateTreeOid (commitTree hd)
            (putBlob dest bloboid)
        hd' <- createCommit [commitOid hd]
            treeoid
            defaultSignature
            defaultSignature
            ("Add " <> decodeUtf8 dest)
            Nothing
        let hd'oid = unTagged (commitOid hd')
        updateReference ref (RefObj hd'oid)
        return (show hd'oid)

findGitRoot :: FilePath -> IO (Maybe FilePath)
findGitRoot path = do
    mexist <- firstM doesDirectoryExist (parents path)
    exist <- case mexist of
        Nothing -> panic ("no part of " <> path <> " exists")
        Just x -> return x
    exist' <- canonicalizePath exist
    firstM (\ d -> doesDirectoryExist (d </> ".git")) (parents exist')

parents :: FilePath -> [FilePath]
parents path = path : rest
    where rest =
            let path' = takeDirectory path
            in if path' == path
                 then []
                 else parents path'

panic :: MonadThrow m => String -> m a
panic s = throwM (ErrorCall s)

usage :: IO String
usage = do
    progname <- getProgName
    return $ "usage: " ++ progname ++ " BRANCH SOURCE DEST"

toByteString :: String -> B.ByteString
toByteString = encodeUtf8 . T.pack

main :: IO ()
main = do
    args <- getArgs
    case args of
        [branch, src, dest] -> do
            mgit <- findGitRoot dest
            gitdir <- case mgit of
                Nothing -> panic $ dest ++ " isn't in a git directory"
                Just x -> return x
            oid <- cpIntoGit src
                        gitdir
                        ("refs/heads/" <> T.pack branch)
                        (toByteString $ makeRelative gitdir dest)
            putStrLn oid
        _ -> do usage >>= hPutStrLn stderr
                exitFailure
