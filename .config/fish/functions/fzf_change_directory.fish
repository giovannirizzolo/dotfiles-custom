function _fzf_change_directory
    fzf | perl -pe 's/([ ()])/\\\\$1/g' | read foo
    if [ $foo ]
        builtin cd $foo
        commandline -r ''
        commandline -f repaint
    else
        commandline ''
    end
end

function __resolve_coderoot --description 'Get or prompt for code root'
    # 1) prefer env var if already set (expand ~)
    if set -q CODEROOT
        echo (string replace -r '^~' $HOME -- $CODEROOT)
        return
    end

    # 2) try ghq.root from git config
    set -l root (git config --global --get ghq.root 2>/dev/null)
    if test -n "$root"
        echo $root
        return
    end

    # 3) ask the user (no default)
    echo "CODEROOT is not set."
    read -P "Enter your base code directory (absolute or with ~): " -l input
    if test -z "$input"
        echo "Aborted: no directory entered." >&2
        return 1
    end

    set root (string replace -r '^~' $HOME -- $input)
    mkdir -p "$root"

    # persist outside ~/.config: store in git config
    git config --global ghq.root "$root"

    # export for this session only (no fish universal var)
    set -gx CODEROOT "$root"

    echo $root
end

function fzf_change_directory --description 'fzf picker for repos/dirs using CODEROOT or ghq.root'
    set -l code_root (__resolve_coderoot)
    or return

    begin
        # 1) ghq-managed repos (absolute paths), if ghq exists
        if type -q ghq
            ghq list -p
        end

        # 2) current directory's immediate subdirs (safe even if empty)
        set -l here (pwd -P)
        echo $HOME/.config/
        for name in (command ls -1A 2>/dev/null)
            set -l path "$here/$name"
            if test -d "$path"; and not string match -q '*/.git*' -- "$path"
                echo "$path"
            end
        end

        # 3) directories under $code_root (depth 1–2), portable (no GNU-only flags)
        if test -d "$code_root"
            for p in $code_root/* $code_root/*/*
                if test -d "$p"; and not string match -q '*/.git*' -- "$p"
                    echo "$p"
                end
            end
        end
    end \
        | sed -e 's:/*$::' \
        | awk '!a[$0]++' \
        | _fzf_change_directory $argv
end
