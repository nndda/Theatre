import re


classes_any = re.compile(r"\[([A-Z]\w+)\](?!\(.*?\))")

# prop_local = re.compile(r"\[(\w+)\](?!\(.*?\))")
bbcodes = [
    "i",
    "b",
    "u",
    "fx1",
    "fx1",
    "fx1",
    "wavy",
    "img",
    "c",
    "col",
    "color",
    "bg",
    "bgcolor",
    "fg",
    "fgcolor",
    "lb",
    "rb",
]

member_local = re.compile(r"\[([a-z]\w+(?:\(\))?)\](?!\(.*?\))")
def member_local_repl(matchobj):
    member_name = matchobj.group(1)

    if member_name in bbcodes:
        return matchobj.group(0)

    if member_name in classes_godot:
        return f"<code markdown>[{member_name}](https://docs.godotengine.org/en/4.4/classes/class_{member_name}.html){{ target=\"_blank\" }}</code>"

    return f"<code markdown>[{member_name}](#{re.sub(r"(\(|\))", "", member_name)})</code>"

def class_godot_repl(matchobj):
    class_name = matchobj.group(1)

    return f"<code class=\"gd-class\" markdown> {
        "" if class_name in classes_nonimg
        else imgify(f"/assets/icons/godot/Object.svg") if class_name in classes_objimg
        else imgify(f"/assets/icons/godot/{class_name}.svg")
    } [{class_name}]({format_class_url(class_name)})</code>"

def imgify(url):
    return f"<img src=\"{url}\">"

classes_theatre_defs = {
    "Dialogue": {
        "icon": imgify("/assets/icons/theatre/Dialogue.svg"),
        "desc": {
            "prop": "",
        },
    },
    "TheatreStage": {
        "icon": imgify("/assets/icons/theatre/TheatreStage.svg"),
        "desc": {
            "prop": "",
        },
    },
    "DialogueLabel": {
        "icon": imgify("/assets/icons/theatre/DialogueLabel.svg"),
        "desc": {
            "prop": "",
        },
    },
}

classes_theatre = list(classes_theatre_defs.keys())
classes_nonimg = [
    *classes_theatre,
    "String",
    "Array",
    "Dictionary",
    "Variant",
]
classes_objimg = [
    "Engine",
    "OS",
    "Resource",
    "RefCounted",
    "WeakRef",
]

classes_godot = [
    "int",
    "float",
]


def format_class_url(class_name):
    if class_name in classes_theatre:
        return f"/class/{class_name.lower()}/references/index.md"

    return f"https://docs.godotengine.org/en/4.4/classes/class_{class_name.lower()}.html"

# def create_class_link(class_name):
#     return f"<code markdown> [{class_name}]({format_class_url(class_name)}){{ target=\"_blank\" }} </code>"


classes_theatre_re = re.compile(r"\[(Dialogue|TheatreStage|DialogueLabel)\]")
def class_repl(matchobj):
    class_name = matchobj.group(1)

    return f"<code class=\"gd-class\" markdown>{classes_theatre_defs[class_name]["icon"] or ""} [{class_name}]({format_class_url(class_name)})</code>"


properties_table_re = re.compile(r"^p\s+(\[\w+](?:\[\[.*?\]\])?)\s+\b(\w+?)\b\s+([\s\S]+?)(?:\b|\B)\n([\s\S]+?)\n\n\n", flags=re.MULTILINE)
def prop_repl(matchobj):
    return_type = matchobj.group(1)
    property_name = matchobj.group(2)
    default = matchobj.group(3) or ""
    desc = matchobj.group(4)

    return f"| {return_type} | `{property_name}` | `{default}` |\n"


methods_table_re = re.compile(r"^m\s+([\s\S]+?)\s+((\w+)(\([\s\S]+?))(?:\b|\B)\n([\s\S]+?)\n\n\n", flags=re.MULTILINE)
def method_repl(matchobj):
    return_type = matchobj.group(1)
    method_name = matchobj.group(3)
    param = matchobj.group(4)
    desc = matchobj.group(5)

    return f"| {return_type} | <code markdown>[{method_name}](#{method_name}){param}</code> |\n"


def on_page_content(html, page, **kwargs):
    if page.url.endswith("/references/"):
        for toc_main in page.toc.items:
            if toc_main.title in classes_theatre:

                for toc_1 in toc_main.children:
                    if toc_1.title == "Property Descriptions":
                        for toc_prop in toc_1.children:
                            reformatted_title = re.sub(r"\s*(\[|,)\s*", "", toc_prop.title).replace(r"] ", " ")

                            toc_prop.title = f"<code>{reformatted_title.split(" ", 2)[1]}</code>"

                    elif toc_1.title == "Method Descriptions":
                        for toc_method in toc_1.children:
                            toc_method.title = f"<code>{re.search(r"(\w+?)\(", toc_method.title).group(1)}</code>"

                    elif toc_1.title == "Signals":
                        for toc_sig in toc_1.children:
                            # match = re.search(r"(\w+?)\(", toc_sig.title)

                            # # I'm forced
                            # if match:
                            #     match = match.group(1)

                            # toc_sig.title = f"<code>{match}</code>"
                            toc_sig.title = f"<code>{re.search(r"(\w+?)\(", toc_sig.title).group(1)}</code>"


def on_page_markdown(markdown, page, **kwargs):

    if page.url.endswith("/references/"):
        prop_desc_arr = []

        for prop_match in re.finditer(properties_table_re, markdown):
            return_type = prop_match.group(1)
            property_name = prop_match.group(2)
            default = prop_match.group(3) or ""
            desc = prop_match.group(4)

            prop_desc_arr.append(f"<h3 class=\"prop\" id=\"{property_name}\" markdown> <small>{return_type}</small> {property_name} {"" if default == "" else f"<small>= {default}</small>"} </h3>\n {desc} \n ---")

        markdown = properties_table_re.sub(prop_repl, markdown)
        markdown = re.sub(r"<!-- property descriptions -->", "\n".join(prop_desc_arr), markdown)

        # ---------------------------------------------------------------------

        method_desc_arr = []

        for prop_match in re.finditer(methods_table_re, markdown):
            return_type = prop_match.group(1)
            method_name = prop_match.group(3)
            param = prop_match.group(4)
            desc = prop_match.group(5)

            method_desc_arr.append(f"<h3 class=\"method\" id=\"{method_name}\" markdown> <small>{return_type}</small> {method_name}<span class=\"fun-param\">{param}</span> </h3>\n {desc} \n ---")

        markdown = methods_table_re.sub(method_repl, markdown)
        markdown = re.sub(r"<!-- method descriptions -->", "\n".join(method_desc_arr), markdown)



    markdown = classes_theatre_re.sub(class_repl, markdown)

    markdown = classes_any.sub(class_godot_repl, markdown)

    markdown = member_local.sub(member_local_repl, markdown)

    return markdown