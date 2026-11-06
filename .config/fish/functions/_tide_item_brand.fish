function _tide_item_brand --description 'tide item: the active Ghostty theme mark (replaces the OS icon)'
    # tide_brand_style is set by tide_ghostty_colors from the theme name.
    switch "$tide_brand_style"
        case gta
            # The VI logo has no font glyph: draw it — a bold "V" in sunset
            # orange and "I" in hot pink (the logo's gradient ends).
            _tide_print_item brand (set_color -o $tide_brand_v_color)V(set_color -o $tide_brand_i_color)I
        case gotham
            _tide_print_item brand \U000f0594 # moon
        case '*'
            _tide_print_item brand $tide_os_icon
    end
end
