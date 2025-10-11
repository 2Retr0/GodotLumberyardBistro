# GodotLumberyardBistro
A port of the popular "Lumberyard Bistro" scene in the Godot Engine originally created by elite3d studios. This project was created primarily as a simple demo environment/starting point to be used in other personal projects.

![lumberyard_bistro](https://github.com/user-attachments/assets/5f6a86ea-c701-4318-bc9c-d8aa64b13da1)

The final scene has been optimized to be able to be run on a wide-variety of hardware while maintaining high visual fidelity. [add performance metric lol]

Most notably contained within this repository is a cleaned and minimized [`.glb` version](assets/lumberyard_bistro/lumberyard_bistro.glb) of the original mesh, which has been optimized for easy use in other projects. Meshes have been deduplicated wherever possible, with transforms (mostly) corrected.  Textures have been downsampled based on mesh sizes. Animations from the original scene have been adjusted to be fully loopable.

The `.glb` file should be fairly easy to import into other software, although its embedded normal maps may need to be inverted depending on the engine. Note that larger modifcations which deviate more-significantly from the original scene were separately implemented through a Godot [import script](assets/lumberyard_bistro/lumberyard_bistro_import.gd).

# References
**elite3d studios**. **["Bistro Scene" created for Amazon Lumberyard Engine](https://www.artstation.com/artwork/bnDKr)**. (2017).\
**John James Gutib**. **[Bistro-Demo-Tweaked](https://github.com/Jamsers/Bistro-Demo-Tweaked)**. (2025).

# Attribution
**[Amazon Lumberyard Bistro](https://developer.nvidia.com/orca/amazon-lumberyard-bistro)** by **Amazon Lumberyard** is modified and used under the [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) license.\
**[Evening Road 01 (Pure Sky)](https://polyhaven.com/a/evening_road_01_puresky)** by **Jarod Guest** is used under the [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/) license.
