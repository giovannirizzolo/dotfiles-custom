function tide_ghostty_colors --description 'Paint the tide prompt with the active Ghostty theme'
    # Reads the theme Ghostty uses (current-theme.ghostty, else `theme =` in
    # config.ghostty) and writes tide's color vars (to a cache file) to its exact hex
    # values, so every open shell repaints on its next prompt.
    # Run by `ghostty_theme` on every switch; safe to run by hand.
    set -l dir ~/.config/ghostty
    set -l builtin /Applications/Ghostty.app/Contents/Resources/ghostty/themes

    set -l name
    for f in $dir/current-theme.ghostty $dir/config.ghostty
        test -f $f; or continue
        set name (string match -rg '^\s*theme\s*=\s*"?([^"]*?)"?\s*$' <$f)[1]
        test -n "$name"; and break
    end
    set name (string replace -r '^~/' "$HOME/" -- $name)
    set -l theme
    if string match -q '/*' -- $name
        set theme $name
    else
        for d in $dir/themes $builtin
            test -f "$d/$name"; and set theme "$d/$name"; and break
        end
    end
    if not test -f "$theme"
        echo "tide_ghostty_colors: can't find Ghostty theme '$name'" >&2
        return 1
    end

    # theme keys -> bare hex (tide wants rrggbb without '#')
    function __tgc_key -V theme
        string match -rg "^\s*$argv[1]\s*=\s*#?([0-9a-fA-F]{6})" <$theme | string lower | head -1
    end
    set -l p
    for i in (seq 0 15)
        set -a p (string match -rg "^\s*palette\s*=\s*$i\s*=\s*#?([0-9a-fA-F]{6})" <$theme | string lower | head -1)
    end
    set -l bg (__tgc_key background)
    set -l fg (__tgc_key foreground)
    set -l accent (__tgc_key cursor-color); test -n "$accent"; or set accent $p[12]
    set -l sel (__tgc_key selection-background); test -n "$sel"; or set sel $p[9]
    functions -e __tgc_key
    if test (count $p) -ne 16; or test -z "$bg"; or test -z "$fg"
        echo "tide_ghostty_colors: incomplete theme $theme" >&2
        return 1
    end

    # ANSI role -> theme hex ($p is 1-indexed: palette N = $p[N+1]).
    # "black" text becomes the theme background (dark ink on colored pills),
    # "white" pills become the theme accent.
    set -l roles black brblack red green yellow blue magenta cyan white \
        brred brgreen bryellow brblue brmagenta brcyan brwhite
    set -l hexes $bg $p[9] $p[2] $p[3] $p[4] $p[5] $p[6] $p[7] $accent \
        $p[10] $p[11] $p[12] $p[13] $p[14] $p[15] $p[16]

    # tide's default role for each color var (from `tide configure`, rainbow).
    set -l defaults \
        aws_bg_color yellow aws_color brblack bun_bg_color white bun_color black \
        character_color brgreen character_color_failure brred \
        cmd_duration_bg_color yellow cmd_duration_color black \
        context_bg_color brblack context_color_default yellow context_color_root yellow context_color_ssh yellow \
        crystal_bg_color brwhite crystal_color black \
        direnv_bg_color bryellow direnv_bg_color_denied brred direnv_color black direnv_color_denied black \
        distrobox_bg_color brmagenta distrobox_color black docker_bg_color blue docker_color black \
        elixir_bg_color magenta elixir_color black gcloud_bg_color blue gcloud_color black \
        git_bg_color green git_bg_color_unstable yellow git_bg_color_urgent red \
        git_color_branch black git_color_conflicted black git_color_dirty black git_color_operation black \
        git_color_staged black git_color_stash black git_color_untracked black git_color_upstream black \
        go_bg_color brcyan go_color black java_bg_color yellow java_color black \
        jobs_bg_color brblack jobs_color green kubectl_bg_color blue kubectl_color black \
        nix_shell_bg_color brblue nix_shell_color black node_bg_color green node_color black \
        os_bg_color white os_color black php_bg_color blue php_color black \
        private_mode_bg_color brwhite private_mode_color black \
        prompt_color_frame_and_connection brblack prompt_color_separator_same_color brblack \
        pulumi_bg_color yellow pulumi_color black python_bg_color brblack python_color cyan \
        ruby_bg_color red ruby_color black rustc_bg_color red rustc_color black \
        shlvl_bg_color yellow shlvl_color black \
        status_bg_color black status_bg_color_failure red status_color green status_color_failure bryellow \
        terraform_bg_color magenta terraform_color black time_bg_color white time_color black \
        toolbox_bg_color magenta toolbox_color black \
        vi_mode_bg_color_default white vi_mode_bg_color_insert cyan vi_mode_bg_color_replace green \
        vi_mode_bg_color_visual yellow vi_mode_color_default black vi_mode_color_insert black \
        vi_mode_color_replace black vi_mode_color_visual black zig_bg_color yellow zig_color black

    for i in (seq 1 2 (count $defaults))
        set -l idx (contains -i -- $defaults[(math $i + 1)] $roles)
        set -g tide_$defaults[$i] $hexes[$idx]
    end

    # The path pill: selection color with the theme's own text colors.
    set -g tide_pwd_bg_color $sel
    set -g tide_pwd_color_dirs $fg
    set -g tide_pwd_color_anchors $p[16]
    set -g tide_pwd_color_truncated_dirs $p[8]
    # Time / jobs / context / python sit on a neutral pill: use light text.
    set -g tide_time_bg_color $p[1]
    set -g tide_time_color $fg
    set -g tide_status_bg_color $p[1]
    set -g tide_prompt_color_separator_same_color $p[9]
    set -g tide_prompt_color_frame_and_connection $p[9]

    # ── Per-theme style: logo pill, separator shapes, prompt arrow ──────
    # The brand pill replaces tide's OS icon (see _tide_item_brand).
    set -l items (string replace -r '^os$' brand -- $tide_left_prompt_items)
    contains brand $items; or set items brand $items
    set -g tide_left_prompt_items $items
    set -g tide_brand_bg_color $p[1]
    set -g tide_brand_color $accent
    switch (string lower -- (path basename -- $theme))
        case 'gta*'
            set -g tide_brand_style gta
            set -g tide_brand_v_color $p[12] # sunset orange
            set -g tide_brand_i_color $p[2] # hot pink
            # Rounded pills (\ue0b4/\ue0b6 half-circles).
            set -g tide_left_prompt_separator_diff_color 
            set -g tide_left_prompt_separator_same_color 
            set -g tide_left_prompt_prefix 
            set -g tide_left_prompt_suffix 
            set -g tide_right_prompt_separator_diff_color 
            set -g tide_right_prompt_separator_same_color 
            set -g tide_right_prompt_prefix 
            set -g tide_right_prompt_suffix 
            set -g tide_prompt_icon_connection ─
            set -g tide_character_icon ▶
            set -g tide_character_color $accent
        case 'gotham*'
            set -g tide_brand_style gotham
            # Rounded pills, a dotted rooftop line, a narrow arrow.
            set -g tide_left_prompt_separator_diff_color 
            set -g tide_left_prompt_separator_same_color 
            set -g tide_left_prompt_prefix 
            set -g tide_left_prompt_suffix 
            set -g tide_right_prompt_separator_diff_color 
            set -g tide_right_prompt_separator_same_color 
            set -g tide_right_prompt_prefix 
            set -g tide_right_prompt_suffix 
            set -g tide_prompt_icon_connection ┄
            set -g tide_character_icon ›
            set -g tide_character_color $accent
        case '*'
            set -g tide_brand_style default
    end

    # Write them all to one cache file that conf.d/tide_ghostty_sync.fish
    # sources in every fish (including tide's background prompt job).
    # One file instead of ~100 universal vars: each `set -U` woke every open
    # shell, which made a switch take ~15s.
    set -l cache ~/.cache/fish/tide_ghostty.fish
    mkdir -p (path dirname $cache)
    set -g | string match -r '^tide_\S+.*' | string match -rv '^tide_theme_stamp' |
        string replace -r '^' 'set -g ' >$cache.tmp
    and mv $cache.tmp $cache
    # Tell every open shell to reload its prompt.
    set -U tide_theme_stamp (date +%s)(random)
end
