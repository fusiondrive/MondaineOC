# Swiss Railway Clock - A Mondaine Clock Mockup

<p align="center">
  <img src="https://github.com/fusiondrive/MondaineOC/blob/main/preview.png" alt="Swiss Railway Clock Preview" width="400"/>
</p>
<p align="center">
  <i>An iOS 6 built-in clock style mockup by the classic Mondaine design.</i>
</p>

---

This project is a tribute to the timeless design of the Swiss Railway Clock, famously licensed by Mondaine. It's a fully functional clock application for iOS, designed to replicate the aesthetic and unique movement of this horological icon.

A key feature of this project is its meticulous attention to detail. All visual assets, from the clean clock face and a sans-serif dial to the iconic hands, were hand-drawn from scratch in **Figma**. The implementation brings these static designs to life with smooth animations and dynamic features.

## Features

* **Classic Mondaine Design**: A faithful recreation of the minimalist and highly readable clock face designed by Hans Hilfiker in 1944.
* **Dynamic Appearance**: The clock seamlessly adapts to both Light and Dark Mode, ensuring perfect readability in any environment.
* **Hand-Drawn Assets**: Every visual component was crafted in Figma, offering a sharp, vector-quality look.
* **The Famous "stop2go" Feature**: This project implements the legendary movement of the Swiss Railway Clock:
    * The red second hand glides smoothly around the face in approximately 58.5 seconds, creating a continuous, fluid motion (`Uhr mit schleichender Sekunde`).
    * It then briefly **pauses** at the 12 o'clock position.
    * During this pause, the minute hand elegantly **jumps** forward to the next minute mark.
    * Finally, the second hand begins its next rotation, ensuring every train (and in our case, every minute) departs precisely on time.
* **Built with Core Animation**: The entire clock is rendered using Apple's powerful `CALayer` framework, ensuring high performance and fluid animations.

## Design Process

The creation of this clock was a design-first process. The goal was not just to replicate the function, but also the "feel" of the original.

1.  **Reference & Study**: Extensive research was done on the design principles of the SBB clock, including its proportions, typography, and the exact shape of the hands (especially the red second hand, reminiscent of a railway guard's signaling disc).
2.  **Figma Prototyping**: All assets were drawn in Figma. This allowed for rapid iteration and pixel-perfect control over every element. The process involved:
    * Drawing the precise tick marks for minutes and hours.
    * Crafting the minimalist hour and minute hands.
    * Recreating the iconic red "paddle" second hand.
3.  **Asset Export**: The finalized components were exported as high-resolution PNGs to be used within the iOS application.


## Technical Details

* **Platform**: iOS
* **Language**: Objective-C 
* **Core Frameworks**: UIKit, QuartzCore (Core Animation)
* **Design Tools**: Figma

## License

This project is licensed under the **GNU Affero General Public License v3.0**. See the [LICENSE](https://github.com/fusiondrive/MondaineOC/blob/main/LICENSE.txt) file for the full license text.

---

*Disclaimer: This project is a personal tribute and is not affiliated with, sponsored, or endorsed by the Swiss Federal Railways (SBB) or Mondaine.*
