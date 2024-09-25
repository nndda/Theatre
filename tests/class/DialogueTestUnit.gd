extends RefCounted
class_name DialogueTestUnit

var _ref : Dialogue

var PASS_ICON := "[b]" + String.chr(0x2713) + "[/b] "
var FAIL_ICON := "[b]" + String.chr(0x2717) + "[/b] "

var _failed_tests : int = 0
var _fails_only : bool = false

var _test_ref_source_path : String = ""

func log_pass(string : String) -> void:
    if !_fails_only:
        print_rich(" [color=green]" + PASS_ICON + string + "[/color]")

func log_start(string : String) -> void:
    print_rich("  " + string)

func log_fail(string : String, ln_num : int = -1) -> void:
    print_rich(
        " [color=red]" + FAIL_ICON + string + "[/color]",
        "" if ln_num == -1 else \
        " at line %d" % ln_num
    )
    _failed_tests += 1

func _init(reference_dialogue : Dialogue, fails_only : bool = false) -> void:
    _fails_only = fails_only
    _ref = reference_dialogue

func test(target : Dialogue) -> void:
    log_start("Testing %s" % target._source_path)

    _test_ref_source_path = _ref.get_source_path()

    var target_sets : Array[Dictionary] = target._sets
    var ref_sets : Array[Dictionary] = _ref._sets

    if target_sets.size() != ref_sets.size():
        log_fail("Inconsistent Dialogue length: %d != %d" % [
            target_sets.size(), ref_sets.size()
        ])

    else:
        for n : int in ref_sets.size():
            var target_data : Dictionary = target_sets[n]
            var ref_data : Dictionary = ref_sets[n]

            if target_data["line"] != ref_data["line"]:
                log_fail("Inconsistent 'line' at: %d" % n, target_data[DialogueParser.__LINE_NUM])

            if target_data["line_raw"] != ref_data["line_raw"]:
                log_fail("Inconsistent 'line_raw' at: %d" % n, target_data[DialogueParser.__LINE_NUM])

            _test_vars(target_data, ref_data)
            _test_tags(target_data, ref_data)

    _test_finished()

func _test_vars(target_data : Dictionary, ref_data : Dictionary) -> void:
    var target_vars : PackedStringArray = target_data[DialogueParser.__VARS]
    var ref_vars : PackedStringArray = ref_data[DialogueParser.__VARS]

    target_vars.sort()
    ref_vars.sort()

    if !ref_vars.is_empty():
        log_start("Testing variables...")
        if target_vars.is_empty():
            log_fail("expected variables: %s" % str(ref_data[DialogueParser.__VARS]), target_data[DialogueParser.__LINE_NUM])
        elif target_vars.size() != ref_vars.size():
            log_fail("variable size mismatch: %d != %d" % [target_vars.size(), ref_vars.size()], target_data[DialogueParser.__LINE_NUM])
        else:
            for var_n : int in ref_vars.size():
                if ref_data[DialogueParser.__VARS][var_n] != target_data[DialogueParser.__VARS][var_n]:
                    log_fail("value mismatch: %s != %s" % [ref_data[DialogueParser.__VARS][var_n], target_data[DialogueParser.__VARS][var_n]], target_data[DialogueParser.__LINE_NUM])
                else:
                    log_pass("%s == %s" % [ref_data[DialogueParser.__VARS][var_n], target_data[DialogueParser.__VARS][var_n]])

func _test_tags(target_data : Dictionary, ref_data : Dictionary) -> void:
    for tag : String in ref_data[DialogueParser.__TAGS].keys():
        var target_tag_data : Dictionary = target_data[DialogueParser.__TAGS][tag]
        var ref_tag_data : Dictionary = ref_data[DialogueParser.__TAGS][tag]

        if !ref_tag_data.is_empty():
            log_start("Testing tag '%s'..." % tag)

            var ref_tag_data_keys := ref_tag_data.keys()
            ref_tag_data_keys.sort()

            var target_tag_data_keys := target_tag_data.keys()
            target_tag_data_keys.sort()

            if ref_tag_data_keys != target_tag_data_keys:
                log_fail("tag data mismatch %s != %s" % [ref_tag_data_keys, target_tag_data_keys], target_data[DialogueParser.__LINE_NUM])

            else:
                for tag_pos : int in ref_tag_data.keys():
                    if ref_tag_data[tag_pos] != target_tag_data[tag_pos]:
                        log_fail("value mismatch: %s != %s" % [ref_tag_data[tag_pos], target_tag_data[tag_pos]], target_data[DialogueParser.__LINE_NUM])
                    else:
                        log_pass("%s == %s" % [ref_tag_data[tag_pos], target_tag_data[tag_pos]])

func _test_finished() -> void:
    print(
        _test_ref_source_path + " " +
        "-".repeat(80 - _test_ref_source_path.length())
    )
    if _failed_tests <= 0:
        print("Test passed")
    else:
        print("Failed tests: %d" % _failed_tests)

static func create_reference(dlg_src : Variant) -> void:
    if dlg_src is String:
        ResourceSaver.save(
            load(dlg_src) as Dialogue, dlg_src + ".REF.tres"
        )
    if dlg_src is Dialogue:
        ResourceSaver.save(
            dlg_src, dlg_src._source_path + ".REF.tres"
        )
