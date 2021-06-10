-- Configuration file for Xmonad Window Manager, place this file at ~/.xmonad/xmonad.hs

import Data.Char (toLower)
import qualified Data.Map as Map
import Data.Monoid
import Graphics.X11.ExtraTypes.XF86
import System.Exit
import XMonad
import XMonad.Actions.WindowGo (raiseMaybe)
import XMonad.Actions.WindowMenu (windowMenu)
import XMonad.Hooks.DynamicLog (dynamicLog, statusBar, xmobarPP)
import XMonad.Hooks.EwmhDesktops (ewmh)
import XMonad.Hooks.ManageDocks
import XMonad.Layout.Spacing
import XMonad.Prompt.AppLauncher (launchApp)
import XMonad.Prompt.RunOrRaise (runOrRaisePrompt)
import XMonad.Prompt.Shell (shellPrompt)
import qualified XMonad.StackSet as W

-- Check the app name (ignore the letter case)
check :: String -> Query Bool
check appName = (appName ==) . (map toLower) <$> className

-- Some user define commands
toggleXmobarCmd =
  "dbus-send --session --dest=org.Xmobar.Control --type=method_call --print-reply "
    ++ "'/org/Xmobar/Control' org.Xmobar.Control.SendSignal 'string:Toggle 0'" -- Hide or reveal the xmobar

browserCmd = "google-chrome-stable" -- Browser

lockCmd = "dm-tool lock" -- Screen locker

myStatusBar = "xmobar"

myTerminal = "vte"

myTerminalCmd = myTerminal ++ " -W -P never -g 120x40 -n 5000 --reverse"

myFocusFollowsMouse = False -- Whether focus follows the mouse pointer

myClickJustFocuses = False -- Whether clicking on a window to focus also passes the click to the window

myBorderWidth = 2 -- Width of the window border in pixels.

myModMask = mod4Mask -- Use "Win" as mod key

myWorkspaces = ["main"] ++ map show [2 .. 9]

-- Border colors for unfocused and focused windows, respectively.
myNormalBorderColor = "#dddddd"

myFocusedBorderColor = "#0000ff"

-- Key bindings. Add, modify or remove key bindings here.
myKeys conf =
  Map.fromList $
    [ ((myModMask, xK_Return), raiseMaybe (spawn myTerminalCmd) $ check myTerminal),
      ((myModMask .|. controlMask, xK_Return), spawn myTerminalCmd),
      ((0, xF86XK_AudioMute), spawn "amixer set Master toggle"), -- change the sound volume
      ((0, xF86XK_AudioLowerVolume), spawn "amixer set Master 5%-"),
      ((0, xF86XK_AudioRaiseVolume), spawn "amixer set Master 5%+"),
      ((controlMask, xF86XK_AudioLowerVolume), spawn "amixer set Master 1%-"),
      ((controlMask, xF86XK_AudioRaiseVolume), spawn "amixer set Master 1%+"),
      ((myModMask, xK_p), windowMenu),
      ((myModMask, xK_x), shellPrompt def),
      ((myModMask, xK_b), spawn browserCmd),
      ((myModMask, xK_w), kill), -- close focused window
      ((myModMask, xK_h), withFocused hide), -- hide focused window
      ((myModMask, xK_space), sendMessage NextLayout), -- Rotate through the available layout algorithms
      ((myModMask .|. shiftMask, xK_space), setLayout $ XMonad.layoutHook conf), -- Reset the layouts on the current workspace to default
      ((myModMask, xK_l), spawn lockCmd), -- Use switch-to-greeter to LOCK SCREEN
      ((myModMask, xK_n), refresh), -- Resize viewed windows to the correct size
      ((myModMask, xK_r), runOrRaisePrompt def),
      ((myModMask .|. controlMask, xK_f), withFocused $ windows . W.sink), -- Push window back into tiling
      ((myModMask, xK_Tab), windows W.focusDown), -- Move focus to the next window
      ((myModMask, xK_j), windows W.focusDown), -- Move focus to the next window
      ((myModMask, xK_k), windows W.focusUp), -- Move focus to the previous window
      ((myModMask, xK_m), windows W.focusMaster), -- Move focus to the master window
      ((myModMask .|. controlMask, xK_m), windows W.swapMaster), -- Swap the focused window and the master window
      ((myModMask .|. controlMask, xK_j), windows W.swapDown), -- Swap the focused window with the next window
      ((myModMask .|. controlMask, xK_k), windows W.swapUp), -- Swap the focused window with the previous window
      ((myModMask .|. controlMask, xK_h), sendMessage Shrink), -- Shrink the master area
      ((myModMask .|. controlMask, xK_l), sendMessage Expand), -- Expand the master area
      ((myModMask, xK_comma), sendMessage $ IncMasterN 1), -- Increment the number of windows in the master area
      ((myModMask, xK_period), sendMessage $ IncMasterN (-1)), -- Deincrement the number of windows in the master area
      ((myModMask, xK_t), sendMessage ToggleStruts >> spawn toggleXmobarCmd), -- Toggle the status bar
      -- ((myModMask, xK_h), windows (\s -> (hide . W.focus) <$> (W.stack . W.workspace . W.current $ s))), -- Hide current window
      ((myModMask .|. controlMask, xK_q), io $ exitWith ExitSuccess), -- Quit xmonad
      ((myModMask, xK_q), spawn "xmonad --recompile; xmonad --restart") -- Restart xmonad
    ]
      ++ [
           -- mod-[1..9], Switch to workspace N
           -- mod-shift-[1..9], Move client to workspace N
           ((m .|. myModMask, k), windows $ f i)
           | (i, k) <- zip (XMonad.workspaces conf) [xK_1 .. xK_9],
             (f, m) <- [(W.greedyView, 0), (W.shift, controlMask)]
         ]

-- Mouse bindings: default actions bound to mouse events
myMouseBindings _ =
  Map.fromList $
    [ -- button1 == mouse left click
      -- button2 == mouse middle click
      -- button3 == mouse right click
      -- mod-button1, Set the window to floating mode and move by dragging
      ((myModMask, button1), \w -> focus w >> mouseMoveWindow w >> windows W.shiftMaster),
      -- mod-button2, Raise the window to the top of the stack
      ((myModMask, button2), \w -> focus w >> windows W.shiftMaster),
      -- mod-control-left-click, Set the window to floating mode and resize by dragging
      ((myModMask .|. controlMask, button1), \w -> focus w >> mouseResizeWindow w >> windows W.shiftMaster)
      -- you may also bind events to the mouse scroll wheel (button4 and button5)
    ]

-- Layouts:
-- You can specify and transform your layouts by modifying these values.
-- If you change layout bindings be sure to use 'mod-shift-space' after
-- restarting (with 'mod-q') to reset your layout state to the new
-- defaults, as xmonad preserves your old layout settings by default.
-- The available layouts.  Note that each layout is separated by |||,
-- which denotes layout choice.
myLayout =
  spacingRaw
    enbaleSmartBorder
    border
    enableScreenBorder
    border
    enableWindowBorder
    $ layoutHook def
  where
    -- smart border means the border will be disabled if there is only one window in current workspace
    (enbaleSmartBorder, enableScreenBorder, enableWindowBorder) = (False, True, True)
    border =
      Border -- border size
        { top = 5,
          bottom = 5,
          right = 5,
          left = 5
        }

-- Window rules:
-- Execute arbitrary actions and WindowSet manipulations when managing
-- a new window. You can use this to, for example, always float a
-- particular program, or have a client always appear on a particular
-- workspace.
-- To find the property name associated with a program, use
-- > xprop | grep WM_CLASS
-- and click on the client you're interested in.
-- To match on the WM_NAME, you can use 'title' in the same way that
-- 'className' and 'resource' are used below.
myManageHook =
  composeAll
    [ check myTerminal --> doFloat
    -- resource =? "desktop_window" --> doIgnore,
    -- resource =? "kdesktop"--> doIgnore
    ]

-- Start some applications when window manager start up
myStartupHook = spawn "xcompmgr"

-- Run xmonad with the settings you specify. No need to modify this.
main = do
  (xmonad =<<) $
    statusBar myStatusBar xmobarPP (const (myModMask .|. controlMask, xK_b)) $
      ewmh $
        def
          { -- simple stuff
            terminal = myTerminal,
            focusFollowsMouse = myFocusFollowsMouse,
            clickJustFocuses = myClickJustFocuses,
            borderWidth = myBorderWidth,
            modMask = myModMask,
            workspaces = myWorkspaces,
            normalBorderColor = myNormalBorderColor,
            focusedBorderColor = myFocusedBorderColor,
            -- key bindings
            keys = myKeys,
            mouseBindings = myMouseBindings,
            -- hooks, layouts
            logHook = dynamicLog,
            layoutHook = myLayout,
            startupHook = myStartupHook,
            manageHook = myManageHook
          }
