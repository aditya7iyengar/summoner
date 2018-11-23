module Summoner.Tui.Form
       ( SummonForm (..)
       , mkForm
       ) where


import Brick (Padding (Max), Widget, hBox, padRight, str, txt, vBox, vLimit)
import Brick.Forms (Form, checkboxField, editField, editTextField, listField, newForm, radioField,
                    setFieldConcat, setFormConcat, (@@=))
import Lens.Micro ((^.))

import Summoner.GhcVer (parseGhcVer, showGhcVer)
import Summoner.License (LicenseName)
import Summoner.Text (intercalateMap)
import Summoner.Tui.Field (activeCheckboxField, strField)
import Summoner.Tui.GroupBorder (groupBorder, (|>))
import Summoner.Tui.Kit
import Summoner.Tui.Widget (borderLabel, hArrange, label)

import qualified Brick.Widgets.Center as C
import qualified Data.Text as T


-- | Form that is used for @new@ command.
data SummonForm
    -- User
    = UserOwner
    | UserFullName
    | UserEmail

    -- Project
    | ProjectName
    | ProjectDesc
    | ProjectCat
    | ProjectLicense

    -- Build tools
    | CabalField
    | StackField

    -- Project Meta
    | Lib
    | Exe
    | Test
    | Bench
    | CustomPreludeName
    | CustomPreludeModule
    | Ghcs

      -- GitHub fields
    | GitHubEnable
    | GitHubDisable
    | GitHubPrivate
    | GitHubTravis
    | GitHubAppVeyor
    deriving (Eq, Ord, Show)


-- | Creates the input form from the given initial 'SummonKit'.
mkForm :: forall e . SummonKit -> Form SummonKit e SummonForm
mkForm sk = setFormConcat arrangeColumns $ newForm
    ( groupBorder "User"
        [ 2 |> label "Owner     " @@= editTextField (user . owner) UserOwner (Just 1)
        , 1 |> label "Full name " @@= editTextField (user . fullName) UserFullName (Just 1)
        , 2 |> label "Email     " @@= editTextField (user . email) UserEmail (Just 1)
        ]
   ++ groupBorder "Project"
        [ 2 |> label "Name        " @@= editTextField (project . repo) ProjectName (Just 1)
        , 3 |> label "Description " @@= editTextField (project . desc) ProjectDesc (Just 2)
        , 2 |> label "Category    " @@= editTextField (project . category) ProjectCat (Just 1)
        , 4 |> vLimit 3 . label "License " @@= listField (const (fromList $ universe @LicenseName))
              maybeLicense widgetList 1 ProjectLicense
        ]
   -- ++ groupBorder "Tools"
   --      [ 2 |> checkboxField cabal CabalField "Cabal"
   --      , 2 |> checkboxField stack StackField "Stack"
   --      ]
   ++   [ checkboxField cabal CabalField "Cabal"
        , checkboxField stack StackField "Stack"
        ]

   ++ groupBorder "Project Meta"
        [ 2 |> checkboxField (projectMeta . lib) Lib "Library"
        , 1 |> checkboxField (projectMeta . exe) Exe "Executable"
        , 1 |> checkboxField (projectMeta . test) Test "Tests"
        , 2 |> checkboxField (projectMeta . bench) Bench "Benchmarks"
        , 1 |> strField "Custom prelude"
        , 1 |> label "Name   " @@= editTextField (projectMeta . preludeName) CustomPreludeName (Just 1)
        , 2 |> label "Module " @@= editTextField (projectMeta . preludeModule) CustomPreludeModule (Just 1)
        , 2 |> label "GHC versions " @@= editField (projectMeta . ghcs) Ghcs (Just 1) (intercalateMap " " showGhcVer) (traverse parseGhcVer . words . T.intercalate " ") (txt . T.intercalate "\n") id
        ]
   ++ groupBorder "GitHub"
        [ 2 |> setFieldConcat hArrange . radioField (gitHub . enabled)
            [ (True, GitHubEnable, "Enable")
            , (False, GitHubDisable, "Disable")
            ]
        , 1 |> activeCheckboxField (gitHub . private)  isGitHubEnabled GitHubPrivate  "Private"
        , 1 |> activeCheckboxField (gitHub . travis)   isGitHubEnabled GitHubTravis   "Travis"
        , 2 |> activeCheckboxField (gitHub . appVeyor) isGitHubEnabled GitHubAppVeyor "AppVeyor"
        ]
    ) sk
  where
    isGitHubEnabled :: Bool
    isGitHubEnabled = sk ^. gitHub . enabled

    widgetList :: Bool -> LicenseName -> Widget SummonForm
    widgetList p l = C.hCenter $ str $ if p then "[" ++ show l ++ "]" else show l

    arrangeColumns :: [Widget SummonForm] -> Widget SummonForm
    arrangeColumns widgets =
        let (column1, columns2) = splitAt 7 widgets in
        let (tools, column2) = splitAt 2 columns2 in
        hBox [ vBox $ column1 ++ [borderLabel "Tools" $ padRight Max (hArrange tools)]
             , vBox column2
             ]