extends TheatreConfig; func config(): return {

    update_check: true,

    parser: {
        multi_threaded: OS.get_processor_count() >= 2,
    },

    bbcode_aliases: {
        "title": [
            "b",
            "u",
            "wavy",
            "font=res://demo/assets/fonts/gabriela.tres"
        ],
        "gd": [
            "u",
            "color=77dfdf",
        ],
    },

}
