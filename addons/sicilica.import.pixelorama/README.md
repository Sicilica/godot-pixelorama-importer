# Godot Pixelorama Importer

This is a plugin for importing [Pixelorama](https://orama-interactive.itch.io/pixelorama) projects into the [Godot](https://godotengine.org/) game engine.
After trying several other implementations and finding them lacking, I decided to write my own.

## Features

- Imports Pixelorama `*.pxo` files as SpriteFrames
- Each tag in the Pixelorama project is imported as a separate animation, or optionally all frames can be imported as `default`
- Can optionally flatten all layers together, or create separate animations for each layer
- Automatically packs frames into a single texture atlas

## Installation

Add the addon folder from this repo to your project, then enable the plugin in Project Settings.
