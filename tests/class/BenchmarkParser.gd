extends RefCounted

func _parser_warmup() -> void:
    DialogueParser._initialize_regex_multi_threaded()

func differ(
    value : Variant,
    humanize : bool = false,
    rich : bool = false,
) -> String:
    var is_negative : bool = sign(value) < 0

    # Heavens forgive me
    return (("[color=%s]" % ("red" if is_negative else "green")) if rich else "") + (
        "" if value == 0 else "-" if is_negative else "+"
    ) + (
        String.humanize_size(value) if humanize else str(value)
    ) + ("[/color]" if rich else "")

func _init(
    dialogue_paths : PackedStringArray,
    iterations: int,
) -> void:
    _parser_warmup()

    var time_start_mark : int = Time.get_ticks_usec()

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

    var memory_info: Dictionary = OS.get_memory_info()

    print("CPU: %s, %d cores\nMEMORY: %s\n" % [OS.get_processor_name(), OS.get_processor_count(), String.humanize_size(memory_info["available"])])

    const PERF_TEMPLATE := "%-20s %-12s %-12s %-12s"

    var perf_static_memory_peak : int = 0
    var perf_static_memory_used : int = 0
    var perf_object_count : int = 0
    var perf_resource_count : int = 0

    var perf_static_memory_peak_post : int = 0
    var perf_static_memory_used_post : int = 0
    var perf_object_count_post : int = 0
    var perf_resource_count_post : int = 0

    perf_static_memory_peak = OS.get_static_memory_peak_usage()
    perf_static_memory_used = int(Performance.get_monitor(Performance.MEMORY_STATIC))
    perf_object_count = int(Performance.get_monitor(Performance.OBJECT_COUNT))
    perf_resource_count = int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT))

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

    perf_static_memory_peak_post = OS.get_static_memory_peak_usage()
    perf_static_memory_used_post = int(Performance.get_monitor(Performance.MEMORY_STATIC))
    perf_object_count_post = int(Performance.get_monitor(Performance.OBJECT_COUNT))
    perf_resource_count_post = int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT))

    print("\n", PERF_TEMPLATE % ["", "pre", "post", "diff"])

    print_rich(PERF_TEMPLATE % [
        "Static memory peak",
        String.humanize_size(perf_static_memory_peak),
        String.humanize_size(perf_static_memory_peak_post),
        differ(perf_static_memory_peak_post - perf_static_memory_peak, true, true),
    ])

    print_rich(PERF_TEMPLATE % [
        "Static memory used",
        String.humanize_size(perf_static_memory_used),
        String.humanize_size(perf_static_memory_used_post),
        differ(perf_static_memory_used_post - perf_static_memory_used, true, true),
    ])

    print_rich(PERF_TEMPLATE % [
        "Object count",
        str(perf_object_count),
        str(perf_object_count_post),
        differ(perf_object_count_post - perf_object_count, false, true),
    ])
    print_rich(PERF_TEMPLATE % [
        "Resource count",
        str(perf_resource_count),
        str(perf_resource_count_post),
        differ(perf_resource_count_post - perf_resource_count, false, true),
    ])

    print("")
    print("Finished in %0.2fms" % ((Time.get_ticks_usec() - time_start_mark) / 1000.))
