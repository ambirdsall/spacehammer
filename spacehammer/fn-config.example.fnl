(local {: menu!
        : action!} (require :spacehammer.forge))
(local windows (require :spacehammer.windows))

(fn activator
  [app-name]
  "
  A higher order function to activate a target app. It's useful for quickly
  binding a modal menu action or hotkey action to launch or focus on an app.
  Takes a string application name
  Returns a function to activate that app.

  Example:
  (local launch-emacs (activator \"Emacs\"))
  (launch-emacs)
  "
  (fn activate []
    (windows.activate-app app-name)))

(action! {:mods [:alt] :key :space} "Activate Modal" "spacehammer.lib.modal:activate-modal")

(menu! "w" "Window")
(action! [:w {:key :space}] "Last Window" "windows:jump-to-last-window")
(action! [:w {:key :h :mods [:cmd]}] "Jump Left" "windows:jump-window-left")
(action! [:w {:key :j :mods [:cmd]}] "Jump Up" "windows:jump-window-above")
(action! [:w {:key :k :mods [:cmd]}] "Jump Down" "windows:jump-window-below")
(action! [:w {:key :l :mods [:cmd]}] "Jump Right" "windows:jump-window-right")
;; TODO is this even a thing
(action! :wj "Jump" "windows:jump")

(menu! "a" "Apps")
(action! :ae "Emacs" (activator "Emacs"))
(action! :ag "Chrome" (activator "Google Chrome"))
(action! :af "Firefox" (activator "Firefox"))
(action! :ai "iTerm" (activator "iTerm"))
(action! :as "Slack" (activator "Slack"))
(action! :ab "Brave" (activator "Brave Browser"))

(menu! "m" "Media")
(action! :ms "Play or Pause" "multimedia:play-or-pause")
(action! :mh "Previous Track" "multimedia:prev-track")
(action! :ml "Next Track" "multimedia:next-track")
(action! :mj "Volume Down" "multimedia:volume-down")
(action! :mk "Volume Up" "multimedia:volume-up")

(menu! "x" "Emacs")
(action! :xc "Capture" "emacs:capture")
(action! :xz "Note" "emacs:note")
(action! :xv "Split" "emacs:vertical-split-with-emacs")
(action! :xf "Full Screen" "emacs:full-screen")


(action! {:key :space} "Spotlight" #(hs.eventtap.keyStroke [:cmd] :space))
;; alternately, replace with this:
;; (action! {:key :space} "Alfred" (activator "Alfred 4"))

;; TODO create separate function for defining top-level bindings (or just use hs.hotkey.bind??)
(action! {:mods [:alt] :key :n} "Next App" "apps:next-app")
(action! {:mods [:alt] :key :p} "Previous App" "apps:prev-app")
(action! {:mods [:cmd :ctrl] :key "`"} "hs.toggleConsole" "Toggle Console")
(action! {:mods [:cmd :ctrl] :key :o} "emacs:edit-with-emacs" "Edit with Emacs")
