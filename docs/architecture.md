# Architecture

`config/components.json` contains component metadata. `setup.ps1` handles selection, detection, progress and dispatch. Each component has its own installer script.

Adding a component should normally require adding metadata and one installer script rather than rewriting the menu.
