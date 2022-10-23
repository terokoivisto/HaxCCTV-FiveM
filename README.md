# Haxwel's CCTV Menu

### Usage in scripts
Open the camera menu with `exports.haxcctv:OpenCCTVMenu()`

### Updating the cameras list to contain all cameras in your world
1. Open CodeWalker with all your building mods loaded in. Make sure the DLC level matches your server DLC level.
2. Go to Tools -> World Search and search for `cctv_cam` on the Entity Search tab. Make sure `Loaded Files Only` is checked.
3. After the search has finished, export the results into a text file using `Export results...` -button.
4. Open https://regex101.com and choose `Flavor` as `ECMAScript (JavaScript)` and `Function` as `Subsititution`.
5. Apart from the first header line, paste your exported text file contents in the `TEST STRING` textarea.
6. As your regular expression, paste `^(?<prop>\w+), (?<pos>-?\d+\.*\d*, -?\d+\.*\d*, -?\d+\.*\d*).*$`
7. On the `SUBSTITUTION` paste `{Prop="$1", Pos = vec3($2)},`
8. Copy everything and replace all the entries in `cameras.lua`