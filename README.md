# MondaineOC - Swiss Railway Clock for macOS

\<p align="center"\>
\<img src="[https://github.com/fusiondrive/MondaineOC/blob/main/preview\_landscape.png](https://www.google.com/search?q=https://github.com/fusiondrive/MondaineOC/blob/main/preview_landscape.png)" alt="Landscape Mode" width="600"/\>
\</p\>
\<p align="center"\>
\<i\>A pixel-perfect tribute to the classic Mondaine design, blending iOS 6 nostalgia with modern macOS desktop functionality.\</i\>
\</p\>

-----

This project is a high-fidelity recreation of the iconic Swiss Railway Clock for the macOS desktop. Originally designed by Hans Hilfiker in 1944, this implementation brings the legendary "stop2go" movement to your Mac, enhanced with real-time location and weather data.

## Features

  * **Classic "stop2go" Movement**: A meticulous recreation of the SBB clock's signature 58.5s sweep, a 1.5s pause at the top, and a crisp minute hand jump.
  * **Responsive Three-State Layout**:
      * **Landscape**: Symmetrical layout with location/date on the left and live weather on the right.
      * **Portrait**: An elegant vertical stack inspired by the iOS 6 built-in clock, featuring centered typography and top-aligned info.
      * **Widget/Square**: A minimalist, distraction-free clock face that fits perfectly in any corner of your screen.
  * **Dynamic Letterpress Aesthetics**: Features a sophisticated "engraved" visual style where text appears carved into the background, with light/dark mode adaptive shadows.
  * **Smart Information Layer**:
      * **Real-time Location**: Automatically geocodes your current city (e.g., Columbus, OH).
      * **Live Weather**: Fetches current temperature via Open-Meteo API.
      * **Skeuomorphic Shadows**: Native macOS window shadows combined with custom Core Animation layer shadows for depth.
  * **Native Desktop Integration**: Built with Objective-C and Core Animation for near-zero CPU impact, even with 60fps smooth sweeping animations.

\<p align="center"\>
\<img src="[https://github.com/fusiondrive/MondaineOC/blob/main/preview\_portrait.png](https://www.google.com/search?q=https://github.com/fusiondrive/MondaineOC/blob/main/preview_portrait.png)" alt="Portrait Mode" width="300" style="margin-right: 20px;"/\>
\<img src="[https://github.com/fusiondrive/MondaineOC/blob/main/preview\_dark.png](https://www.google.com/search?q=https://github.com/fusiondrive/MondaineOC/blob/main/preview_dark.png)" alt="Dark Mode" width="450"/\>
\</p\>

## Technical Details

  * **Platform**: macOS 12.0+
  * **Language**: Objective-C
  * **Core Frameworks**: AppKit, Core Animation (QuartzCore), Core Location, Foundation.
  * **Assets**: All vector components hand-drawn in Figma.
  * **Data Sources**: Reverse geocoding via Apple Core Location, Weather data via Open-Meteo.

## Design Process

The application is built on a "Layer-First" architecture. Every tick mark, hand, and shadow is a separate `CALayer`, allowing for independent animation and high-DPI scaling without quality loss. The "Letterpress" effect was achieved by precisely manipulating shadow offsets and colors to mimic light hitting carved indentations on a physical surface.

## Installation & Requirements

1.  Clone the repository.
2.  Open `MondaineOC.xcodeproj` in Xcode.
3.  **Important**: Enable **Location** and **Outgoing Connections (Client)** in the *App Sandbox* settings to allow for geocoding and weather updates.
4.  Build and Run.

## License

This project is licensed under the **GNU Affero General Public License v3.0**. See the [LICENSE](https://www.google.com/search?q=LICENSE.txt) file for details.

-----

*Disclaimer: This project is a personal tribute and is not affiliated with, sponsored, or endorsed by the Swiss Federal Railways (SBB) or Mondaine.*
