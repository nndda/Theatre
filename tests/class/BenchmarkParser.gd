extends RefCounted

func _parser_warmup() -> void:
    DialogueParser._initialize_regex_multi_threaded()

func _init(
    dialogue_paths : PackedStringArray,
    iterations: int,
) -> void:
    _parser_warmup()

    var dlg_data : Dictionary[String, Dictionary] = {}

    for dlg_path in dialogue_paths:
        var dlg_obj := Dialogue.load(dlg_path)
        var dlg_raw := FileAccess.open(dlg_path, FileAccess.READ)
        dlg_raw.get_as_text()

        dlg_data[dlg_path] = {
            &"string": dlg_raw.get_as_text(),
            &"size": String.humanize_size(dlg_raw.get_length()),
            &"lines": dlg_obj.get_length(),
        }

    print("CPU: %s, %d cores" % [OS.get_processor_name(), OS.get_processor_count()])
    print("Static memory peak usage: %s" % String.humanize_size(OS.get_static_memory_peak_usage()))
    print("Starting dialogue benchmark of %d iterations, on %d dialogues..." % [iterations, dialogue_paths.size()])

    print("%-38s %-7s %-10s %-12s %-9s %-12s %-9s %-9s" % ["Dialogue", "lines", "size", "total (ms)", "avg (ms)", "median (ms)", "min (ms)", "max (ms)"])

    for dlg_path : String in dialogue_paths:
        var time : float
        var num_data : PackedFloat32Array = []
        num_data.resize(iterations)

        for n : int in iterations:
            time = Time.get_ticks_usec()

            var _dlg := Dialogue.new(dlg_data[dlg_path][&"string"])

            num_data[n] = Time.get_ticks_usec() - time

        var time_total : float = .0
        var time_min : float = INF
        var time_max : float = .0
        for us in num_data:
            time_total += us
            if us < time_min:
                time_min = us
            if us > time_max:
                time_max = us

        var time_avg : float = time_total / float(iterations)

        num_data.sort()
        var num_data_size : int = num_data.size()
        var num_data_size_half : int = floori(num_data_size * .5)
        var time_median : float = .0
        if num_data_size % 2 == 0:
            time_median = (
                num_data[num_data_size_half] +
                num_data[num_data_size_half - 1]
            ) * .5
        else:
            time_median = num_data[num_data_size_half]

        print("%-38s %-7s %-10s %-12.2f %-9.2f %-12.2f %-9.2f %-9.2f" % [
            dlg_path,
            dlg_data[dlg_path]["lines"],
            dlg_data[dlg_path]["size"],
            time_total / 1000.,
            time_avg  / 1000.,
            time_median / 1000.,
            time_min / 1000.,
            time_max / 1000.,
        ])

    print("Static memory peak usage: %s" % String.humanize_size(OS.get_static_memory_peak_usage()))
