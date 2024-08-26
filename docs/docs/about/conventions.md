# Conventions
This documentation use some symbols for illustration purposes. Before you read
on, please make sure you've made yourself familiar with the following list of
conventions:

<br />

### <!-- md:version --> Release Type { data-toc-label="Version" }

The tag symbol in conjunction with a version number denotes when a specific feature or behavior was added. Make sure you're at least on this version if you want to use it.

:   <!-- md:version stable- --> stable
:   <!-- md:version beta- --> beta

<br />

### <!-- md:control --> Controls { #default data-toc-label="Control" }

These icons define what type of control a specified setting uses.

:   <!-- md:control toggle --> toggle
:   <!-- md:control textbox --> textbox
:   <!-- md:control dropdown --> dropdown
:   <!-- md:control button --> button
:   <!-- md:control slider --> slider
:   <!-- md:control color --> color wheel

<br />

### <!-- md:default --> – Default Value { #default data-toc-label="Default value" }

This defines what the default value for a setting is.

:   <!-- md:default --> Specified setting has a default value
:   <!-- md:default none --> Specified setting has no default value and is empty
:   <!-- md:default computed --> Specified setting is automatically computed by the app

<br />

### <!-- md:command --> – Command { #command data-toc-label="Command" }

This defines a command

:   <!-- md:command --> Specified setting has a default value

<br />

### <!-- md:flag experimental --> – Experimental { data-toc-label="Experimental" }

Anything listed with this icon are features or functionality that are still in development and may change in future versions.

<br />

### <!-- md:flag required --> – Required value { #required data-toc-label="Required value" }

Items listed with this symbol indicate that they are required to be set.

<br />

### <!-- md:flag customization --> – Customization { #customization data-toc-label="Customization" }

This symbol denotes that the item described is a customization which affects the overall look of the app.

<br />

### <!-- md:3rdparty --> – 3rd Party { data-toc-label="3rd Party" }

This symbol denotes that the item described is classified as something that changes the overall functionality of the plugin.

<br />

### <!-- md:flag metadata --> – Metadata property { #metadata data-toc-label="Metadata property" }

This symbol denotes that the item described is a metadata property, which can
be used in Markdown documents as part of the front matter definition.

<br />

### <!-- md:flag setting --> – Configurable Setting { #setting data-toc-label="Configurable Setting" }

This symbol denotes that an item is configurable by the user

<br />

### <!-- md:flag multiple --> – Multiple instances { #multiple-instances data-toc-label="Multiple instances" }

This symbol denotes that the plugin supports multiple instances, i.e, that it
can be used multiple times in the `plugins` setting in `mkdocs.yml`.

<br />

### <!-- md:feature --> – Optional feature { #feature data-toc-label="Optional feature" }

Most of the features are hidden behind feature flags, which means they must
be explicitly enabled via `mkdocs.yml`. This allows for the existence of
potentially orthogonal features.

<br />

### <!-- md:backers --> – Backers only { data-toc-label="Backers only" }

The pumping heart symbol denotes that a specific feature or behavior is only
available to backers. Normal users will not have access to this particular item.

<br />

---

<br />