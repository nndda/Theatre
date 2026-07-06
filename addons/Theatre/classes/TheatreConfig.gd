@abstract
extends RefCounted
class_name TheatreConfig

const TheatrePluginConfig := preload("res://addons/Theatre/classes/TheatrePluginConfig.gd")

enum {
    parser,
    tags,
    defaults,
}

const update_check := TheatrePluginConfig.GENERAL_AUTO_UPDATE
const multi_threaded := TheatrePluginConfig.PARSER_MULTI_THREADS
const delay := TheatrePluginConfig.PARSER_TAGS_DEFAULT_DELAY
const speed := TheatrePluginConfig.PARSER_TAGS_DEFAULT_SPEED
const bbcode_aliases := TheatrePluginConfig.PARSER_TAGSBB_ALIASES

var _cfg: Dictionary = {}

var _dict: Dictionary
# TODO: more robust schema validation
func rec_dict(cfg: Dictionary) -> void:
    for n in cfg:
        if cfg[n] is Dictionary:
            if n == bbcode_aliases:
                var bb_dict: Dictionary[String, PackedStringArray] = {}
                for bb in cfg[n]:
                    bb_dict[bb] = PackedStringArray(cfg[n][bb])

                _dict[n] = bb_dict
            else:
                rec_dict(cfg[n])
        else:
            _dict[n] = cfg[n]

func _get_config() -> Dictionary:
    _dict.clear()
    rec_dict(config())
    return _dict

@abstract func config() -> Dictionary
