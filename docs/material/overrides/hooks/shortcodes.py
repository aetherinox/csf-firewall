# #
#   Copyright (c) 2024 Aetherinox
#
#   Permission is hereby granted, free of charge, to any person obtaining a copy
#   of this software and associated documentation files (the "Software"), to
#   deal in the Software without restriction, including without limitation the
#   rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
#   sell copies of the Software, and to permit persons to whom the Software is
#   furnished to do so, subject to the following conditions:
#
#   The above copyright notice and this permission notice shall be included in
#   all copies or substantial portions of the Software.
#
#   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#   FITNESS FOR A PARTICULAR PURPOSE AND NON-INFRINGEMENT. IN NO EVENT SHALL THE
#   AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
#   FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
#   IN THE SOFTWARE.
# #

# #
#   <!-- md:command `-s,  --start` -->
#   <!-- md:backers -->
#   <!-- md:flag metadata -->
#   <!-- md:default `false` -->
#   <!-- md:default none -->
#   <!-- md:default computed -->
#   <!-- md:flag required -->
#   <!-- md:flag customization -->
#   <!-- md:flag experimental -->
#   <!-- md:flag multiple -->
#   <!-- md:example my-example-file -->
#   <!-- md:3rdparty -->
#   <!-- md:3rdparty [mike] -->
#   <!-- md:option social.icon -->
#   <!-- md:setting config.reeee -->
#   <!-- md:feature -->
# #

from __future__ import annotations

# #
#   Import
# #

import posixpath
import re
import inspect

# #
#   From
# #

from mkdocs.config.defaults import MkDocsConfig
from mkdocs.structure.files import File, Files
from mkdocs.structure.pages import Page
from re import Match

# #
#   ASCII Colors
# #

class clr():
    BLACK = '\033[30m'
    RED = '\033[31m'
    GREEN = '\033[32m'
    YELLOW = '\033[33m'
    BLUE = '\033[34m'
    MAGENTA = '\033[35m'
    CYAN = '\033[36m'
    WHITE = '\033[37m'
    UNDERLINE = '\033[4m'
    RESET = '\033[0m'
    GREY = '\033[90m'

# #
#   Pages
#
#   these must be configured to a valid page path; otherwise the script will error
# #

PAGE_CHANGELOG ="about/changelog.md"
PAGE_BACKERS = "about/backers.md"
PAGE_CONVENTIONS = "about/conventions.md"

# #
#   Hooks > on_page_markdown
# #

def on_page_markdown(markdown: str, *, page: Page, config: MkDocsConfig, files: Files):

    print(clr.MAGENTA + 'VERBOSE - ' + clr.WHITE + ' Loading Page: ' + clr.YELLOW + str(page) + clr.WHITE )

    # Replace callback
    def replace(match: Match):
        type, args = match.groups()
        args = args.strip()

        if type == "version":
            if args.startswith( "beta-" ):
                return Version_Beta(args, page, files)
            elif args.startswith( "stable-" ):
                return Version_Stable( args, page, files )
            else:
                return Version( args, page, files )

        elif type == "backers":         return Badge_Backers(page, files)
        elif type == "control":         return Create_Control(args, page, files)
        elif type == "flag":            return Create_Flag(args, page, files)
        elif type == "option":          return Create_Option(args)
        elif type == "setting":         return Create_Setting(args)
        elif type == "command":         return Badge_Command(args, page, files)
        elif type == "feature":         return Badge_Feature(args, page, files)
        elif type == "plugin":          return Badge_Plugin(args, page, files)
        elif type == "extension":       return Badge_Extension(args, page, files)
        elif type == "3rdparty":        return Badge_3rdparty(args, page, files)
        elif type == "example":         return Badge_Example(args, page, files)
        elif type == "default":
            if   args == "none":        return Badge_DefaultValue_None(page, files)
            elif args == "computed":    return Badge_DefaultValue_Computed(page, files)
            else:                       return Badge_DefaultValue_Custom(args, page, files)

        # Otherwise, raise an error
        raise RuntimeError( f"Error in shortcodes.yp - Specified an unknown shortcode: {type}" )

    # Find and replace all external asset URLs in current page
    return re.sub(
        r"<!-- md:(\w+)(.*?) -->",
        replace, markdown, flags = re.I | re.M
    )

# #
#   Create > Flag
# #

def Create_Flag(args: str, page: Page, files: Files):
    type, *_ = args.split(" ", 1)
    if   type == "experimental":    return Badge_Flag_Experimental(page, files)
    elif type == "required":        return Badge_Flag_Required(page, files)
    elif type == "customization":   return Badge_Flag_Customization(page, files)
    elif type == "metadata":        return Badge_Flag_Metadata(page, files)
    elif type == "multiple":        return Badge_Flag_Multiple_Instances(page, files)
    elif type == "setting":         return Badge_Flag_Setting(page, files)
    raise RuntimeError(f"Unknown type: {type}")

# #
#   Create > Controls
# #

def Create_Control( args: str, page: Page, files: Files ):
    type, *_ = args.split( " ", 2 )
    if   type == "toggle":      return icon_control_toggle( page, files )
    elif type == "toggle_on":   return icon_control_toggle_on( page, files )
    elif type == "toggle_off":  return icon_control_toggle_off( page, files )
    elif type == "textbox":     return icon_control_textbox( page, files )
    elif type == "dropdown":    return icon_control_dropdown( page, files )
    elif type == "button":      return icon_control_button( page, files )
    elif type == "slider":      return icon_control_slider( page, files )
    elif type == "color":       return icon_control_color( args, page, files )
    else: return icon_control_default( page, files )

    raise RuntimeError(f"Unknown type: {type}")

# #
#   Create > Option
# #

def Create_Option(type: str):
    _, *_, name = re.split(r"[.:]", type)
    return f"[`{name}`](#+{type}){{ #+{type} }}\n\n"

# #
#   Create > Setting
# #

def Create_Setting(type: str):
    _, *_, name = re.split(r"[.*]", type)
    return f"`{name}` {{ #{type} }}\n\n[{type}]: #{type}\n\n"

# #
#   Resolve path of file relative to given page - the posixpath always includes
#   one additional level of `..` which we need to remove
# #

def _resolve_path(path: str, page: Page, files: Files):
    path, anchor, *_ = f"{path}#".split("#")
    path = _resolve(files.get_file_from_path(path), page)
    return "#".join([path, anchor]) if anchor else path

# #
#   Resolve path of file relative to given page - the posixpath always includes
#   one additional level of `..` which we need to remove
# #

def _resolve(file: File, page: Page):
    path = posixpath.relpath(file.src_uri, page.file.src_uri)
    return posixpath.sep.join(path.split(posixpath.sep)[1:])

# #
#   Create > Badge
# #

def Create_Badge(icon: str, text: str = "", type: str = ""):
    classes = f"mdx-badge mdx-badge--{type}" if type else "mdx-badge"
    return "".join([
        f"<span class=\"{classes}\">",
        *([f"<span class=\"mdx-badge__icon\">{icon}</span>"] if icon else []),
        *([f"<span class=\"mdx-badge__text\">{text}</span>"] if text else []),
        f"</span>",
    ])

# #
#   Badge > Color Palette
# #

def Badge_ColorPalette(icon: str, text: str = "", type: str = ""):
    args = type.split( " " )

    bg1_clr = "#000000"
    bg2_clr = "#000000"
    bg1_dis = "none"
    bg2_dis = "none"

    if len( args ) > 1:
        bg1_clr = args[ 1 ]
        bg1_dis = "inline-block"

    if len( args ) > 2:
        bg2_clr = args[ 2 ]
        bg2_dis = "inline-block"

    classes = f"mdx-badge mdx-badge--{type}" if type else "mdx-badge"
    return "".join([
        f"<span class=\"{classes}\">",
        *([f"<span class=\"mdx-badge__icon\">{icon}</span>"] if icon else []),
        *([f"<span class=\"mdx-badge__text\">{text}</span>"] if text else []),
        f"<span style=\"display: {bg1_dis};\" class=\"color-container\"><span class=\"color-box\" style=\"background-color:{bg1_clr};\">  </span></span>",
        f"<span style=\"display: {bg2_dis};\" class=\"color-container\"><span class=\"color-box\" style=\"background-color:{bg2_clr};\">  </span></span></span>",
    ])

# #
#   Badge > Sponsor / Backers
#
#       In order for the sponsor / backers badge to work, you must have a backers page created in your mkdocs.
#       add a new file; usually about/backers.md
#       create a new entry in your mkdocs.yml to add the page to your navigation
#
#       use the following tag in your md files:
#           <!-- md:sponsors --> __Sponsors only__ – this plugin is currently reserved to [our awesome sponsors].
#           <!-- md:sponsors -->
# #

def Badge_Backers(page: Page, files: Files):
    icon = "material-heart"
    href = _resolve_path(PAGE_BACKERS, page, files)
    return Create_Badge(
        icon = f"[:{icon}:]({href} 'Backers only')",
        type = "heart"
    )

# #
#   Badge > Version
#
#       In order for the version badge to work, you must have a corresponding version entry in your changelog.md.
#       if not, you will receive the console error `'NoneType' object has no attribute 'src_uri'`
#
#       use the following tag in your md file:
#           <!-- md:version stable-1.6.1 -->
# #

def Version( text: str, page: Page, files: Files ):
    spec = text
    path = f"{PAGE_CHANGELOG}#{spec}"

    # Return badge
    icon = "aetherx-axs-box"
    href = _resolve_path( f"{PAGE_CONVENTIONS}#version", page, files)

    print(clr.MAGENTA + 'VERBOSE - ' + clr.WHITE + ' Running ' + clr.YELLOW + inspect.stack()[0][3] + clr.WHITE + ' for page ' + clr.GREY + str(href) + clr.WHITE )

    return Create_Badge(
        icon = f"[:{icon}:]({href} 'Mkdocs Release')",
        text = f"[{text}]({_resolve_path(path, page, files)})" if spec else ""
    )

# #
#   Badge > Version > Stable
# # 

def Version_Stable( text: str, page: Page, files: Files ):
    spec = text.replace( "stable-", "" )
    path = f"{PAGE_CHANGELOG}#{spec}"

    # Return badge
    icon = "aetherx-axs-tag"
    href = _resolve_path( f"{PAGE_CONVENTIONS}#version-beta", page, files )
    output  = ""

    print(clr.MAGENTA + 'VERBOSE - ' + clr.WHITE + ' Running ' + clr.YELLOW + inspect.stack()[0][3] + clr.WHITE + ' for page ' + clr.GREY + str(href) + clr.WHITE )

    # spec not empty
    if spec:
        output = f"Requires version {spec}"
    else:
        output = f"Stable Release"
    
    return Create_Badge(
        icon = f"[:{icon}:]({href} '{output}' )",
        text = f"[{spec}]({_resolve_path(path, page, files)})" if spec else ""
    )

# #
#   Badge > Version > Beta
# # 

def Version_Beta( text: str, page: Page, files: Files ):
    spec = text.replace( "beta-", "" )
    path = f"{PAGE_CHANGELOG}#{spec}"

    # Return badge
    icon    = "aetherx-axs-b"
    href    = _resolve_path( f"{PAGE_CONVENTIONS}#version-beta", page, files )
    output  = ""

    print(clr.MAGENTA + 'VERBOSE - ' + clr.WHITE + ' Running ' + clr.YELLOW + inspect.stack()[0][3] + clr.WHITE + ' for page ' + clr.GREY + str(href) + clr.WHITE )

    # spec not empty
    if spec:
        output = f"Requires version {spec}"
    else:
        output = f"Beta Release"

    return Create_Badge(
        icon = f"[:{icon}:]({href} '{output}' )",
        text = f"[{text}]({_resolve_path(path, page, files)})" if spec else ""
    )

# #
#   Badge > Feature
#
#       use the following tag in your md file:
#           <!-- md:feature -->
# #

def Badge_Feature(text: str, page: Page, files: Files):
    icon = "material-toggle-switch"
    href = _resolve_path( f"{PAGE_CONVENTIONS}#feature", page, files)

    print(clr.MAGENTA + 'VERBOSE - ' + clr.WHITE + ' Running ' + clr.YELLOW + inspect.stack()[0][3] + clr.WHITE + ' for page ' + clr.GREY + str(href) + clr.WHITE )

    return Create_Badge(
        icon = f"[:{icon}:]({href} 'Optional feature')",
        text = text
    )

# #
#   Badge > Feature
#
#       use the following tag in your md file:
#           <!-- md:plugin -->
#           <!-- md:plugin [glightbox] -->
#           <!-- md:plugin [typeset] – built-in -->
# #

def Badge_Plugin(text: str, page: Page, files: Files):
    icon = "material-floppy"
    href = _resolve_path( f"{PAGE_CONVENTIONS}#plugin", page, files)

    print(clr.MAGENTA + 'VERBOSE - ' + clr.WHITE + ' Running ' + clr.YELLOW + inspect.stack()[0][3] + clr.WHITE + ' for page ' + clr.GREY + str(href) + clr.WHITE )

    return Create_Badge(
        icon = f"[:{icon}:]({href} 'Plugin')",
        text = text
    )

# #
#   Create badge for extension
#
#       use the following tag in your md file:
#           <!-- md:extension [admonition][Admonition] -->
# #

def Badge_Extension(text: str, page: Page, files: Files):
    icon = "material-language-markdown"
    href = _resolve_path( f"{PAGE_CONVENTIONS}#extension", page, files)

    print(clr.MAGENTA + 'VERBOSE - ' + clr.WHITE + ' Running ' + clr.YELLOW + inspect.stack()[0][3] + clr.WHITE + ' for page ' + clr.GREY + str(href) + clr.WHITE )

    return Create_Badge(
        icon = f"[:{icon}:]({href} 'Markdown extension')",
        text = text
    )

# #
#   Badge > Third Party Plugin / Utility
#
#       This symbol denotes that the item described is classified as something that changes the overall functionality of the plugin.
#
#       use the following tag in your md files:
#           <!-- md:3rdparty -->
#           <!-- md:3rdparty [mike] -->
# #

def Badge_3rdparty(text: str, page: Page, files: Files):
    icon = "material-package-variant"
    href = _resolve_path( f"{PAGE_CONVENTIONS}#3rdparty", page, files)

    print(clr.MAGENTA + 'VERBOSE - ' + clr.WHITE + ' Running ' + clr.YELLOW + inspect.stack()[0][3] + clr.WHITE + ' for page ' + clr.GREY + str(href) + clr.WHITE )

    return Create_Badge(
        icon = f"[:{icon}:]({href} 'Third-party utility')",
        text = text
    )

# #
#   Create Download Example > View
#
#       Creates a badge which allows a user to download a file.
#
#       The badge will have three sections:
#           - View Example
#           - Download Example
#           - .zip text
#
#       If you supply the code below with a title of `my-example-file`, the links generated will be:
#           - [View Example]            https://github.com/Aetherinox/csf-firewall/my-example-file/
#           - [Download Example]        https://github.com/Aetherinox/csf-firewall/my-example-file.zip
#           - [Zip]                     https://github.com/Aetherinox/csf-firewall/my-example-file.zip
#
#       use the following tag in your md files:
#           <!-- md:example my-example-file -->
# #

def Badge_Example(text: str, page: Page, files: Files):
    return "\n".join([
        Badge_Example_Download_Zip(text, page, files),
        Badge_Example_View(text, page, files)
    ])

def Badge_Example_View(text: str, page: Page, files: Files):
    icon = "material-folder-eye"
    href = f"https://github.com/Aetherinox/csf-firewall/{text}/"

    print(clr.MAGENTA + 'VERBOSE - ' + clr.WHITE + ' Running ' + clr.YELLOW + inspect.stack()[0][3] + clr.WHITE + ' for page ' + clr.GREY + str(href) + clr.WHITE )

    return Create_Badge(
        icon = f"[:{icon}:]({href} 'View example')",
        type = "right"
    )

def Badge_Example_Download_Zip(text: str, page: Page, files: Files):
    icon = "material-folder-download"
    href = f"https://github.com/Aetherinox/csf-firewall/{text}.zip"

    print(clr.MAGENTA + 'VERBOSE - ' + clr.WHITE + ' Running ' + clr.YELLOW + inspect.stack()[0][3] + clr.WHITE + ' for page ' + clr.GREY + str(href) + clr.WHITE )

    return Create_Badge(
        icon = f"[:{icon}:]({href} 'Download example')",
        text = f"[`.zip`]({href})",
        type = "right"
    )

# #
#   Badge > Command
#   
#   Used when specifying a command in an app
#
#       use the following tag in your md file:
#           <!-- md:command `-s,  --start` -->
# #

def Badge_Command(text: str, page: Page, files: Files):
    icon = "material-console-line"
    href = _resolve_path( f"{PAGE_CONVENTIONS}#command", page, files)

    print(clr.MAGENTA + 'VERBOSE - ' + clr.WHITE + ' Running ' + clr.YELLOW + inspect.stack()[0][3] + clr.WHITE + ' for page ' + clr.GREY + str(href) + clr.WHITE )

    return Create_Badge(
        icon = f"[:{icon}:]({href} 'Terminal / Console Command')",
        text = text
    )

# #
#   Badge > Default Value > Custom
#   
#   This defines what the default value for a setting is.
#
#       use the following tag in your md file:
#           <!-- md:default `false` -->
#           <!-- md:default `my settings value` -->
#           <!-- md:default computed -->
#           <!-- md:default none -->
# #

def Badge_DefaultValue_Custom(text: str, page: Page, files: Files):
    icon = "material-water"
    href = _resolve_path( f"{PAGE_CONVENTIONS}#default", page, files)

    print(clr.MAGENTA + 'VERBOSE - ' + clr.WHITE + ' Running ' + clr.YELLOW + inspect.stack()[0][3] + clr.WHITE + ' for page ' + clr.GREY + str(href) + clr.WHITE )

    return Create_Badge(
        icon = f"[:{icon}:]({href} 'Default value')",
        text = text
    )

# #
#   Badge > Default Value > None / Empty
#   
#   This defines what the default value for a setting is.
#
#       use the following tag in your md file:
#           <!-- md:default `false` -->
#           <!-- md:default `my settings value` -->
#           <!-- md:default computed -->
#           <!-- md:default none -->
# #

def Badge_DefaultValue_None(page: Page, files: Files):
    icon = "material-water-outline"
    href = _resolve_path( f"{PAGE_CONVENTIONS}#default", page, files)

    print(clr.MAGENTA + 'VERBOSE - ' + clr.WHITE + ' Running ' + clr.YELLOW + inspect.stack()[0][3] + clr.WHITE + ' for page ' + clr.GREY + str(href) + clr.WHITE )

    return Create_Badge(
        icon = f"[:{icon}:]({href} 'Default value is empty')"
    )

# #
#   Badge > Default Value > Computed
#   
#   This defines what the default value for a setting is.
#
#       use the following tag in your md file:
#           <!-- md:default `false` -->
#           <!-- md:default `my settings value` -->
#           <!-- md:default computed -->
#           <!-- md:default none -->
# #

def Badge_DefaultValue_Computed(page: Page, files: Files):
    icon = "material-water-check"
    href = _resolve_path( f"{PAGE_CONVENTIONS}#default", page, files)

    print(clr.MAGENTA + 'VERBOSE - ' + clr.WHITE + ' Running ' + clr.YELLOW + inspect.stack()[0][3] + clr.WHITE + ' for page ' + clr.GREY + str(href) + clr.WHITE )

    return Create_Badge(
        icon = f"[:{icon}:]({href} 'Default value is computed')"
    )

# #
#   Badge > Flag > Metadata Property
#
#   This symbol denotes that the item described is a metadata property, which can
#   be used in Markdown documents as part of the front matter definition.
#
#       use the following tag in your md file:
#           <!-- md:flag metadata -->
# #

def Badge_Flag_Metadata(page: Page, files: Files):
    icon = "material-list-box-outline"
    href = _resolve_path( f"{PAGE_CONVENTIONS}#metadata", page, files)

    print(clr.MAGENTA + 'VERBOSE - ' + clr.WHITE + ' Running ' + clr.YELLOW + inspect.stack()[0][3] + clr.WHITE + ' for page ' + clr.GREY + str(href) + clr.WHITE )

    return Create_Badge(
        icon = f"[:{icon}:]({href} 'Metadata property')"
    )

# #
#   Badge > Flag > Required
#
#   Specifies that a value is required.
#
#       use the following tag in your md file:
#           <!-- md:flag required -->
#           <!-- md:flag required -->  This option enables the content tabs
# #

def Badge_Flag_Required(page: Page, files: Files):
    icon = "material-alert"
    href = _resolve_path( f"{PAGE_CONVENTIONS}#required", page, files)

    print(clr.MAGENTA + 'VERBOSE - ' + clr.WHITE + ' Running ' + clr.YELLOW + inspect.stack()[0][3] + clr.WHITE + ' for page ' + clr.GREY + str(href) + clr.WHITE )

    return Create_Badge(
        icon = f"[:{icon}:]({href} 'Required value')"
    )

# #
#   Badge > Flag > Customization
#
#   This symbol denotes that the item described is a customization which affects the overall look of the app.
#
#       use the following tag in your md file:
#           <!-- md:flag customization -->
# #

def Badge_Flag_Customization(page: Page, files: Files):
    icon = "material-brush-variant"
    href = _resolve_path( f"{PAGE_CONVENTIONS}#customization", page, files)

    print(clr.MAGENTA + 'VERBOSE - ' + clr.WHITE + ' Running ' + clr.YELLOW + inspect.stack()[0][3] + clr.WHITE + ' for page ' + clr.GREY + str(href) + clr.WHITE )

    return Create_Badge(
        icon = f"[:{icon}:]({href} 'Customization')"
    )

# #
#   Badge > Flag > Experimental
#
#   This symbol denotes that the item described is Experimental
#
#   MUST add an entry in conventions.md
#
#       use the following tag in your md file:
#           <!-- md:flag experimental -->
# #

def Badge_Flag_Experimental(page: Page, files: Files):
    icon = "material-flask-outline"
    href = _resolve_path( f"{PAGE_CONVENTIONS}#experimental", page, files)

    print(clr.MAGENTA + 'VERBOSE - ' + clr.WHITE + ' Running ' + clr.YELLOW + inspect.stack()[0][3] + clr.WHITE + ' for page ' + clr.GREY + str(href) + clr.WHITE )

    return Create_Badge(
        icon = f"[:{icon}:]({href} 'Experimental')"
    )

# #
#   Badge > Flag > Multiple Instances
#
#   This symbol denotes that the plugin supports multiple instances, i.e, that it
#   can be used multiple times in the `plugins` setting
#
#   MUST add an entry in conventions.md
#
#       use the following tag in your md file:
#           <!-- md:flag multiple -->
# #

def Badge_Flag_Multiple_Instances(page: Page, files: Files):
    icon = "material-inbox-multiple"
    href = _resolve_path( f"{PAGE_CONVENTIONS}#multiple-instances", page, files)

    print(clr.MAGENTA + 'VERBOSE - ' + clr.WHITE + ' Running ' + clr.YELLOW + inspect.stack()[0][3] + clr.WHITE + ' for page ' + clr.GREY + str(href) + clr.WHITE )

    return Create_Badge(
        icon = f"[:{icon}:]({href} 'Multiple instances')"
    )

# #
#   Badge > Flag > Setting
#
#   This symbol denotes that the specified item is a customizable setting
#
#   MUST add an entry in conventions.md
#
#       use the following tag in your md file:
#           <!-- md:flag setting -->
# #

def Badge_Flag_Setting(page: Page, files: Files):
    icon = "material-cog"
    href = _resolve_path( f"{PAGE_CONVENTIONS}#setting", page, files)

    print(clr.MAGENTA + 'VERBOSE - ' + clr.WHITE + ' Running ' + clr.YELLOW + inspect.stack()[0][3] + clr.WHITE + ' for page ' + clr.GREY + str(href) + clr.WHITE )

    return Create_Badge(
        icon = f"[:{icon}:]({href} 'Configurable Setting')"
    )

# #
#   Icon : Control : Default
#
#   This function is activated if no control type specified
#
#       use the following tag in your md file:
#           <!-- md:control -->
# #

def icon_control_default( page: Page, files: Files ):
    icon = "aetherx-axs-hand-pointer"
    href = _resolve_path( f"{PAGE_CONVENTIONS}#control", page, files )

    print(clr.MAGENTA + 'VERBOSE - ' + clr.WHITE + ' Running ' + clr.YELLOW + inspect.stack()[0][3] + clr.WHITE + ' for page ' + clr.GREY + str(href) + clr.WHITE )

    return Create_Badge(
        icon = f"[:{icon}:]({href} 'Type: Textbox')"
    )

# #
#   Icon : Control : Textbox
#
#       use the following tag in your md file:
#           <!-- md:control textbox -->
# #

def icon_control_textbox( page: Page, files: Files ):
    icon = "aetherx-axs-input-text"
    href = _resolve_path( f"{PAGE_CONVENTIONS}#control", page, files )

    print(clr.MAGENTA + 'VERBOSE - ' + clr.WHITE + ' Running ' + clr.YELLOW + inspect.stack()[0][3] + clr.WHITE + ' for page ' + clr.GREY + str(href) + clr.WHITE )

    return Create_Badge(
        icon = f"[:{icon}:]({href} 'Type: Textbox')"
    )

# #
#   Icon : Control : Toggle Switch
#
#       use the following tag in your md file:
#           <!-- md:control toggle -->
#           <!-- md:control toggle_on --> `Enabled`
#           <!-- md:control toggle_off --> `Disabled`
# #

def icon_control_toggle( page: Page, files: Files ):
    icon = "aetherx-axs-toggle-large-on"
    href = _resolve_path( f"{PAGE_CONVENTIONS}#control", page, files)

    print(clr.MAGENTA + 'VERBOSE - ' + clr.WHITE + ' Running ' + clr.YELLOW + inspect.stack()[0][3] + clr.WHITE + ' for page ' + clr.GREY + str(href) + clr.WHITE )

    return Create_Badge(
        icon = f"[:{icon}:]({href} 'Type: Toggle Switch')"
    )

def icon_control_toggle_on( page: Page, files: Files ):
    icon = "aetherx-axd-toggle-on"
    href = _resolve_path( f"{PAGE_CONVENTIONS}#control", page, files)

    print(clr.MAGENTA + 'VERBOSE - ' + clr.WHITE + ' Running ' + clr.YELLOW + inspect.stack()[0][3] + clr.WHITE + ' for page ' + clr.GREY + str(href) + clr.WHITE )
    
    return Create_Badge(
        icon = f"[:{icon}:]({href} 'Toggle: Enabled')"
    )

def icon_control_toggle_off( page: Page, files: Files ):
    icon = "aetherx-axd-toggle-off"
    href = _resolve_path( f"{PAGE_CONVENTIONS}#control", page, files)

    print(clr.MAGENTA + 'VERBOSE - ' + clr.WHITE + ' Running ' + clr.YELLOW + inspect.stack()[0][3] + clr.WHITE + ' for page ' + clr.GREY + str(href) + clr.WHITE )

    return Create_Badge(
        icon = f"[:{icon}:]({href} 'Toggle: Disabled')"
    )

# #
#   Icon : Control : Dropdown
#
#       use the following tag in your md file:
#           <!-- md:control dropdown -->
# #

def icon_control_dropdown( page: Page, files: Files ):
    icon = "aetherx-axs-square-caret-down"
    href = _resolve_path( f"{PAGE_CONVENTIONS}#control", page, files)

    print(clr.MAGENTA + 'VERBOSE - ' + clr.WHITE + ' Running ' + clr.YELLOW + inspect.stack()[0][3] + clr.WHITE + ' for page ' + clr.GREY + str(href) + clr.WHITE )

    return Create_Badge(
        icon = f"[:{icon}:]({href} 'Type: Dropdown')"
    )

# #
#   Icon : Control : Button
#
#       use the following tag in your md file:
#           <!-- md:control button -->
# #

def icon_control_button( page: Page, files: Files ):
    icon = "material-button-pointer"
    href = _resolve_path( f"{PAGE_CONVENTIONS}#control", page, files )

    print(clr.MAGENTA + 'VERBOSE - ' + clr.WHITE + ' Running ' + clr.YELLOW + inspect.stack()[0][3] + clr.WHITE + ' for page ' + clr.GREY + str(href) + clr.WHITE )

    return Create_Badge(
        icon = f"[:{icon}:]({href} 'Type: Button')"
    )

# #
#   Icon : Control : Slider
#
#       use the following tag in your md file:
#           <!-- md:control slider -->
# #

def icon_control_slider( page: Page, files: Files ):
    icon = "aetherx-axd-sliders-simple"
    href = _resolve_path( f"{PAGE_CONVENTIONS}#control", page, files )

    print(clr.MAGENTA + 'VERBOSE - ' + clr.WHITE + ' Running ' + clr.YELLOW + inspect.stack()[0][3] + clr.WHITE + ' for page ' + clr.GREY + str(href) + clr.WHITE )

    return Create_Badge(
        icon = f"[:{icon}:]({href} 'Type: Slider')"
    )

# #
#   Icon : Control : Color
#
#       use the following tag in your md file:
#           <!-- md:control color #E5E5E5 #121315 -->
# #

def icon_control_color( text: str, page: Page, files: Files ):
    icon = "aetherx-axs-palette"
    href = _resolve_path( f"{PAGE_CONVENTIONS}#control", page, files )

    print(clr.MAGENTA + 'VERBOSE - ' + clr.WHITE + ' Running ' + clr.YELLOW + inspect.stack()[0][3] + clr.WHITE + ' for page ' + clr.GREY + str(href) + clr.WHITE )

    return Badge_ColorPalette(
        icon = f"[:{icon}:]({href} 'Type: Color Wheel')",
        type = text
    )