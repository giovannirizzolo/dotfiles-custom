function pcd_get_code_root --description 'Get or prompt for the coding repo root dir'
    set -l root (git config --global --get ghq.root 2>/dev/null)

    if test -z "$root"
        if set -q CODEROOT
            set root $CODEROOT
        else
            echo "No coding projects root dir found (ghq.root/CODEROOT)."
            read -P "Enter your base code directory (e.g. ~/Code or ~/Development): " -l input
            if test -z "$input"
                echo "No dir provided, setting CODEROOT to $HOME/src"
                set input "$HOME/src"
            end
            set root (string replace -r '^~' $HOME -- $input)
            mkdir -p "$root"
            git config --global ghq.root "$root"
        end
    end

    echo "$root"
end

function _peco_change_directory
    if [ (count $argv) ]
        peco --layout=bottom-up --query "$argv " | perl -pe 's/([ ()])/\\\\$1/g' | read foo
    else
        peco --layout=bottom-up | perl -pe 's/([ ()])/\\\\$1/g' | read foo
    end
    if [ $foo ]
        builtin cd $foo
    else
        commandline ''
    end
end

function peco_change_directory
    set -l code_root (pcd_get_code_root)

    begin
        # 1) ghq-managed repos (absolute paths), if ghq exists
        if type -q ghq
            ghq list -p
        end

        # 2) current directory's immediate subdirs (NO wildcards that can fail)
        set -l here (pwd -P)
        for name in (command ls -1A 2>/dev/null)
            set -l path "$here/$name"
            if test -d "$path"; and not string match -q '*/.git*' -- "$path"
                echo "$path"
            end
        end

        # 3) repos under the code root (depth 1–2) — avoid failing globs
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
        | _peco_change_directory $argv
end
