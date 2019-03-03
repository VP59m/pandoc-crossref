{-
pandoc-crossref is a pandoc filter for numbering figures,
equations, tables and cross-references to them.
Copyright (C) 2017  Nikolay Yakimov <root@livid.pp.ru>

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License along
with this program; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
-}

module Text.Pandoc.CrossRef.Util.Prefixes (
    getPrefixes
  , module Types
) where

import Text.Pandoc.Definition
import Text.Pandoc.CrossRef.Util.Template
import Text.Pandoc.CrossRef.Util.Prefixes.Types as Types
import Text.Pandoc.CrossRef.Util.Settings.Types
import Text.Pandoc.CrossRef.Util.Meta
import Text.Pandoc.CrossRef.Util.CustomLabels
import qualified Data.Map as M
import Data.Maybe

getPrefixes :: String -> Settings -> Prefixes
getPrefixes varN dtv
  | Just (MetaMap m) <- lookupSettings varN dtv = M.mapWithKey m2p m
  | otherwise = error "Prefixes not defined"
  where
    m2p k (MetaMap kv') = Prefix {
        prefixCaptionTemplate = makeTemplate kv $ getTemplDefault "captionTemplate"
      , prefixReferenceTemplate = makeRefTemplate kv $ getTemplDefault "referenceTemplate"
      , prefixReferenceIndexTemplate = makeTemplate kv $ getTemplDefault "referenceIndexTemplate"
      , prefixCaptionIndexTemplate = makeTemplate kv $ getTemplDefault "captionIndexTemplate"
      , prefixListItemTemplate = makeTemplate kv $ getTemplDefault "listItemTemplate"
      , prefixScope = getMetaStringList "scope" kv
      , prefixNumbering = \lvl ->
          let prettyVarName = varN <> "." <> k <> "." <> varName
              varName = "numbering"
          in mkLabel prettyVarName
                  (fromMaybe (reportError prettyVarName "Numbering")
                        $ lookupSettings varName kv >>= getList lvl)
      , prefixListOfTitle = makeBlockTemplate kv $ getMetaBlock "listOfTitle" kv
      , prefixTitle = getMetaInlines "title" kv
      }
      where kv = Settings (Meta kv') <> dtv
            getTemplDefault n =
              if isJust $ lookupSettings n kv
              then getMetaInlines n kv
              else reportError n "Template"
            reportError n what = error $ what <> " meta variable " <> n <> " not set for "
                              <> varN <> "." <> k <> ". This should not happen. Please report a bug"
    m2p k _ = error $ "Invalid value for prefix " <> k