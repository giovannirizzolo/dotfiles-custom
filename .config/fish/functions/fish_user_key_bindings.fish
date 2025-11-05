function __is_macos
    test (uname) = Darwin
end

function fish_user_key_bindings
    # peco
    if __is_macos
        bind \cf peco_change_directory # Bind for peco change directory to Ctrl+F
        bind \cr peco_select_history # Bind for peco select history to Ctrl+R
    else
        bind \cf fzf_change_directory # Bind for fzf change directory to Ctrl+F
        bind \cr _fzf_select_history # Bind for fzf select history to Ctrl+R
    end

    # vim-like
    bind \cl forward-char

    # prevent iterm2 from closing when typing Ctrl-D (EOF)
    bind \cd delete-char
end
