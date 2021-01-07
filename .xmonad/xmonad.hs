------------------------------------------------------------------------
---IMPORTS
------------------------------------------------------------------------
    -- Base
import XMonad
import XMonad.Config.Desktop
import Data.Monoid
import Data.Ratio
import Data.Maybe (isJust)
import System.IO (hPutStrLn)
import System.Exit (exitSuccess)
import qualified XMonad.StackSet as W

    -- Utilities
import XMonad.Util.Loggers
import XMonad.Util.EZConfig (additionalKeysP)
import XMonad.Util.Run (safeSpawnProg, safeSpawn, spawnPipe)

    -- Hooks
import XMonad.ManageHook (composeAll)
import XMonad.Hooks.DynamicLog (dynamicLogWithPP, xmobarPP, xmobarColor, shorten, wrap, PP(..))
import XMonad.Hooks.ManageDocks (manageDocks)
import XMonad.Hooks.ManageHelpers (isFullscreen,  doFullFloat, doRectFloat, isDialog) 
import XMonad.Hooks.EwmhDesktops   -- required for xcomposite in obs to work

    -- Actions
import XMonad.Actions.Promote (promote)
import XMonad.Actions.RotSlaves (rotSlavesDown, rotAllDown)
import XMonad.Actions.CopyWindow (kill1, copyToAll, killAllOtherCopies)
import XMonad.Actions.WithAll (sinkAll, killAll)
import XMonad.Actions.CycleWS (moveTo, shiftTo, WSType(..)) 
import qualified XMonad.Actions.ConstrainedResize as Sqr

    -- Prompts
import XMonad.Prompt (Direction1D(..))

------------------------------------------------------------------------
---CONFIG
------------------------------------------------------------------------
myFont          = "xft:Monolisa-Medium:pixelsize=13"
myModMask       = mod4Mask  -- Sets modkey to super/windows key
myTerminal      = "alacritty"      -- Sets default terminal
myTextEditor    = "nvim"     -- Sets default text editor
myBorderWidth   = 0         -- Sets border width for windows
windowCount     = gets $ Just . show . length . W.integrate' . W.stack . W.workspace . W.current . windowset

main = do
    -- Starting postgres
    _ <- spawnPipe "start_postgres"
    -- Launching xmobar.
    xmproc <- spawnPipe "xmobar $HOME/.config/xmobar/xmobarrc"
        -- the xmonad, ya know...what the WM is named after!
    xmonad $ ewmh desktopConfig
        { manageHook = myManageHook <+> pbManageHook 
        , logHook = dynamicLogWithPP xmobarPP
                        { ppOutput = \x -> hPutStrLn xmproc x 
                        , ppCurrent = xmobarColor "#c3e88d" "" . wrap "[" "]" -- Current workspace in xmobar
                        , ppVisible = xmobarColor "#c3e88d" ""                -- Visible but not current workspace
                        , ppHidden = xmobarColor "#82AAFF" "" . wrap "*" ""   -- Hidden workspaces in xmobar
                        , ppHiddenNoWindows = xmobarColor "#F07178" ""        -- Hidden workspaces (no windows)
                        , ppTitle = xmobarColor "#d0d0d0" "" . shorten 80     -- Title of active window in xmobar
                        , ppSep =  "<fc=#9AEDFE> : </fc>"                     -- Separators in xmobar
                        , ppUrgent = xmobarColor "#C45500" "" . wrap "!" "!"  -- Urgent workspace
                        , ppExtras  = [windowCount]                           -- # of windows current workspace
                        , ppOrder  = \(ws:l:t:ex) -> [ws,l]++ex++[t]
                        }
        , modMask            = myModMask
        , terminal           = myTerminal
        , borderWidth        = myBorderWidth
        , normalBorderColor  = "#292d3e"
        , focusedBorderColor = "#bbc5ff"
        } `additionalKeysP`         myKeys 

------------------------------------------------------------------------
---KEYBINDINGS
------------------------------------------------------------------------
myKeys :: [(String, X())]
myKeys =
    --- Xmonad
        [ ("M-C-r", safeSpawn "xmonad" ["--recompile"])      -- Recompiles xmonad
        , ("M-S-r", safeSpawn "xmonad" ["--restart"])        -- Restarts xmonad
        , ("M-S-q", io exitSuccess)                  -- Quits xmonad
    
    --- Windows
        , ("M-q", kill1)                           -- Kill the currently focused client
        , ("M-S-a", killAll)                         -- Kill all the windows on current workspace

    --- Floating windows
        , ("M-<Delete>", withFocused $ windows . W.sink)  -- Push floating window back to tile.
        , ("M-S-<Delete>", sinkAll)                  -- Push ALL floating windows back to tile.

    --- Windows navigation
        , ("M-m", windows W.focusMaster)             -- Move focus to the master window
        , ("M-<Left>", windows W.focusDown)
        , ("M-<Right>", windows W.focusUp)
        , ("M-S-j", windows W.swapDown)              -- Swap the focused window with the next window
        , ("M-S-k", windows W.swapUp)                -- Swap the focused window with the prev window
        , ("M-<Backspace>", promote)                 -- Moves focused window to master, all others maintain order
        , ("M1-S-<Tab>", rotSlavesDown)              -- Rotate all windows except master and keep focus in place
        , ("M1-C-<Tab>", rotAllDown)                 -- Rotate all the windows in the current stack
        , ("M-S-s", windows copyToAll)  
        , ("M-C-s", killAllOtherCopies) 

    --- Workspaces
        , ("M-<KP_Add>", moveTo Next nonNSP)                                -- Go to next workspace
        , ("M-<KP_Subtract>", moveTo Prev nonNSP)                           -- Go to previous workspace
        , ("M-S-<KP_Add>", shiftTo Next nonNSP >> moveTo Next nonNSP)       -- Shifts focused window to next workspace
        , ("M-S-<KP_Subtract>", shiftTo Prev nonNSP >> moveTo Prev nonNSP)  -- Shifts focused window to previous workspace

    --- Open Terminal
        , ("M-<Return>", safeSpawnProg myTerminal)

    --- My Applications
        , ("M-t", safeSpawn myTerminal ["-e ytop"])
        , ("M-w", safeSpawnProg "microsoft-edge-dev")
        , ("M-r", safeSpawn myTerminal ["-e nnn"])
        , ("M-f", safeSpawn myTerminal ["-e nvim ~/.config/fish/"])
        , ("M-v", safeSpawn myTerminal ["-e nvim"])
        , ("M-S-y", safeSpawnProg "full_screenshot")
        , ("M-m", safeSpawnProg "spotify")
        , ("M-S-m", safeSpawnProg "discord")
        , ("M-c", safeSpawnProg "clipmenu")

    --- System
        , ("M-x", safeSpawnProg "reboot")
        , ("M-S-x", safeSpawn "shutdown" ["-h now"])
        , ("<XF86AudioLowerVolume>", safeSpawn "pactl" ["set-sink-volume @DEFAULT_SINK@ -10%"])
        , ("<XF86AudioRaiseVolume>", safeSpawn "pactl" ["set-sink-volume @DEFAULT_SINK@ +10%"])
        , ("<XF86AudioMute>", safeSpawn "pactl" ["set-sink-mute @DEFAULT_SINK@ toggle"])
        ] where nonNSP          = WSIs (return (\ws -> W.tag ws /= "nsp"))
                nonEmptyNonNSP  = WSIs (return (\ws -> isJust (W.stack ws) && W.tag ws /= "nsp"))

pbManageHook :: ManageHook
pbManageHook = composeAll $ concat
    [ [ manageDocks                                      ]
    , [ manageHook defaultConfig                         ]
    , [ isDialog     --> doRectFloat (W.RationalRect (1 % 4) (1 % 4) (1 % 2) (1 % 2)) ]
    , [ isFullscreen --> doF W.focusDown <+> doFullFloat ]
    ]

myManageHook :: ManageHook
myManageHook = composeAll [ matchAny v --> a | (v,a) <- myActions ]
    where myActions = [ ("spotify"   , doShift "9" )
                      , ("discord"   , doShift "8" )
                      ]

matchAny :: String -> Query Bool
matchAny x = foldr ((<||>) . (=? x)) (return False) [className, title, name, role]

name :: Query String
name = stringProperty "WM_NAME"

role :: Query String
role = stringProperty "WM_ROLE"