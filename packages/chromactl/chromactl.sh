CHROMA_FOLDER=${XDG_CONFIG_HOME:-$HOME/.config}/chroma
THEMES_FILE="$CHROMA_FOLDER/themes.json"

activateTheme()
{
    THEME="$1"
    shift

    DIRECT=0
    # Systemd does not exist on macOS and launchd has no special handling for reloads
    [[ "$OSTYPE" == "darwin"* ]] && DIRECT=1
    if [ "${1:-}" = "--direct" ]; then
        DIRECT=1
        shift
    fi

    # Check that the theme exists
    if jq -r "index(\"$THEME\") == null" "$THEMES_FILE" | grep -q "true"; then
        echo "Theme $THEME does not exist"
        return 1
    fi

    ln -sfn "$CHROMA_FOLDER/themes/$THEME" "$CHROMA_FOLDER/active"

    if [ $DIRECT -eq 1 ]; then
        "$CHROMA_FOLDER/active/activate"
        "$CHROMA_FOLDER/active/reload"
    else
        if ! systemctl --user is-active --quiet chroma.service; then
            echo "WARNING: Chroma user service is not running. No reload is taking place." >&2
        else
            systemctl --user reload chroma.service
        fi
    fi
}

COMMAND="$1"
shift
case $COMMAND in
    activate-theme)
        activateTheme "$@"
        ;;
    list-themes)
        jq -r '.[]' "$THEMES_FILE"
        ;;
    next-theme)
        ACTIVE_THEME="$(jq -r '.name' "$CHROMA_FOLDER/active/info.json")"
        THEME="$(jq -r --arg active "$ACTIVE_THEME" '.[(index($active) + 1) % length]' "$THEMES_FILE")"
        activateTheme "$THEME" "$@"
        ;;
    previous-theme)
        ACTIVE_THEME="$(jq -r '.name' "$CHROMA_FOLDER/active/info.json")"
        THEME="$(jq -r --arg active "$ACTIVE_THEME" '.[(index($active) - 1) % length]' "$THEMES_FILE")"
        activateTheme "$THEME" "$@"
        ;;
    *)
        echo "Usage: chromactl <command>"
        echo "Commands:"
        echo "  activate-theme <theme>"
        echo "  list-themes"
        echo "  next-theme"
        echo "  previous-theme"
        ;;
esac
