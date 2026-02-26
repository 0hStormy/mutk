# MUTK

**M**ini **U**I **T**ool**k**it is a fast, lightweight, and easy to use GUI toolkit written in Nim.
It provides a simple widget tree system and a CSS renderer for styling.
Currently MUTK uses around 70mb of ram with static linking (most of that is just SDL).

## Widgets

Current widget set:
* Widget
* Root (Window)
* Box
* Frame
* Button

Planned widgets:
* TextBox
* Slider
* Dropdown
* SpinButton
* ProgressBar


## Demo

![demo](demo.png)

## Styling

### CSS Level 1 Compliance:

Key:
* No: Not implemented but planned
* Yes: Implemented
* Partial: Implemented partially
* N/A: Not applicable to MUTK

### Font Properties
* font-family: No
* font-style: No
* font-variant: N/A
* font-weight: No
* font-size: No
* font: N/A

### Color and Background
* color: No
* background-color: Yes
* background-image: Partial[1]
* background-repeat: No
* background-attachment: No
* background-position: No
* background: No[2]

### Text Properties
These aren't relevent to a GUI toolkit really, plea your case otherwise in the issue tab.

* word-spacing: N/A
* letter-spacing: N/A
* text-decoration: N/A
* vertical-align: N/A
* text-transform: N/A
* text-align: N/A
* text-indent: N/A
* line-height: N/A

### Box Properties
* margin-top: No
* margin-right: No
* margin-bottom: No
* margin-left: No
* margin: No
* padding-top: No
* padding-right: No
* padding-bottom: No
* padding-left: No
* padding: No
* border-top-width: No
* border-right-width: No
* border-bottom-width: No
* border-left-width: No
* border-width: Yes
* border-color: Yes
* border-style: No
* border-top: No
* border-right: No
* border-bottom: No
* border-left: No
* border: Partial[3]
* width: No
* height: No
* float: N/A
* clear: N/A

### Classification Properties
* display: No
* white-space: N/A
* list-style-type: N/A
* list-style-image: N/A
* list-style-position: N/A
* list-style: N/A

[1]: Only linear-gradient() currently

[2]: Use `background-color` and `background-image` for now

[3]: Only color and width are parsed currently