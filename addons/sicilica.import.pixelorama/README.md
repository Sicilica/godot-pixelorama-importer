# Godot Pixelorama Importer

This is a plugin for importing [Pixelorama](https://orama-interactive.itch.io/pixelorama) projects into the [Godot](https://godotengine.org/) game engine.
After trying several other implementations and finding them lacking, I decided to write my own.

## Features

- Imports Pixelorama `*.pxo` files as SpriteFrames
- Each tag in the Pixelorama project is imported as a separate animation, or optionally all frames can be imported as `default`
- Can optionally flatten all layers together, or create separate animations for each layer
- Automatically packs frames into a single texture atlas

## Installation

Add the addon folder from this repo to your project, then enable the plugin in Project Settings > Plugins.

## Usage

Your files should appear in the file viewer inside Godot and be imported automatically.

If you want to change the import settings for a file, select the file and open the Import settings pane.
(By default, it's a tab in the left side dock, next to the Scene tree view.)

## FAQ

### What versions are supported?

This works with recent version of Pixelorama (using version 5 of the pxo format). If you are unable to import a file created with an older version of Pixelorama, try saving it again with the latest version.

Any version of Godot 4.x should work.

### Do I need to set "Include blended images"?

When saving projects in Pixelorama, there is an option to include blended images in the saved file. This renders a combined image for each frame and stores it in the project on disk.

If you want each layer to be imported separately, then this setting doesn't matter.

If you want to combine all layers when importing into Godot anyway, then you may get better results by enabling this option.
Otherwise, this plugin will attempt to blend the layers together during import, but some effects from Pixelorama may not be implemented correctly.

### My imported images look different than they do in Pixelorama!

See the previous question.
