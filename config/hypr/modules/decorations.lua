hl.config({
    general = {
        gaps_in  = 8,
        gaps_out = 20,
        border_size = 1,
        resize_on_border = true,
        allow_tearing = false,
        layout = "dwindle",
        col = {
            active_border   = { colors = {"rgba(e8eaed88)"} },
            inactive_border = "rgba(59595955)",
        },
    },

    decoration = {
        rounding       = 20,
        rounding_power = 8,
        -- Change transparency of focused and unfocused windows
        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        shadow = {
            enabled      = true,
            range        = 20,
            render_power = 3,
--            color        = 0xee1a1a1a,
            color        = 0xaa000000,
        },

        blur = {
            enabled   = true,
            size      = 13,
            passes    = 3,
            vibrancy  = 0.1696,
        },
    }
})
