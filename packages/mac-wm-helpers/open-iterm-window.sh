#!/bin/bash

# For some reason I cannot perform this all in one AppleScript.
# Even though each individual command works, the whole script does not.
# Thus, we wire the parts together with bash.

IS_RUNNING=$(printf "if application \"iTerm2\" is running then\nreturn \"y\"\nelse\nreturn \"n\"\nend if" | osascript)
if [ "$IS_RUNNING" == "n" ]; then
  # Yes, the running application is iTerm2, but to start it, we open iTerm
  open -a iTerm
else
  osascript -e 'tell application "iTerm2" to create window with default profile'
fi