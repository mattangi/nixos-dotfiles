hl.config({
    input = {
        kb_layout  = "us",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        follow_mouse = 1,
        repeat_rate = 100,
        repeat_delay = 300,
        sensitivity = 0, -- -1.0 - 1.0, 0 means no modification.
        natural_scroll = false,

        touchpad = {
            natural_scroll = true,
        },
    },
})

hl.config({
    cursor = {
        inactive_timeout = 30,
        no_hardware_cursors = true,
    },
})

hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace"
})

