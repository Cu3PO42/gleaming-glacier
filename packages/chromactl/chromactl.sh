CHROMA_FOLDER=${XDG_CONFIG_HOME:-$HOME/.config}/chroma
THEMES_FILE="$CHROMA_FOLDER/themes.json"

activateTheme()
{
    # Check that the theme exists
    if jq -r "index(\"$1\") == null" "$THEMES_FILE" | grep -q "true"; then
        echo "Theme $1 does not exist"
        return 1
    fi
    ln -sfn "$CHROMA_FOLDER/themes/$1" "$CHROMA_FOLDER/active"
    "$CHROMA_FOLDER/active/activate"
    "$CHROMA_FOLDER/active/reload"
}

case $1 in
    activate-theme)
        activateTheme "$2"
        ;;
    list-themes)
        jq -r '.[]' "$THEMES_FILE"
        ;;
    next-theme)
        ACTIVE_THEME="$(jq -r '.name' "$CHROMA_FOLDER/active/info.json")"
        THEME="$(jq -r --arg active "$ACTIVE_THEME" '.[(index($active) + 1) % length]' "$THEMES_FILE")"
        activateTheme "$THEME"
        ;;
    previous-theme)
        ACTIVE_THEME="$(jq -r '.name' "$CHROMA_FOLDER/active/info.json")"
        THEME="$(jq -r --arg active "$ACTIVE_THEME" '.[(index($active) - 1) % length]' "$THEMES_FILE")"
        activateTheme "$THEME"
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
