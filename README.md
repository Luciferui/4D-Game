# 4D Game — time as a fourth spatial axis

A first-person puzzle prototype in **Godot 4.7** where the fourth dimension is not a
shader trick or a scripted dissolve: every prop in the level is really a stack of
**time slices** sitting at different coordinates `w`, and what you see on screen is a
genuine 3D cross-section of that 4D scene. Rotating the `XW` plane turns the room's
own history into geometry you can walk around — a seal that was broken becomes the
fan of slabs it used to be.

<!-- ============================================================================
     GIF 01 — À FOURNIR  ·  gif principal, juste sous le titre
     fichier : docs/media/01_hero.gif
     montrer : la boucle complète — marcher dans le hall, [X] ouvrir le plan XW,
               les tranches s'écarter en éventail, [I] rembobiner vers le passé
     format  : 960x540 · 10-15 s · boucle sans coupure · < 8 Mo
============================================================================ -->
![Walking through the hall, opening the XW plane into a fan of slices, then rewinding to the past](docs/media/01_hero.gif)

*Solo project: code, shaders, level and art direction are mine. Godot 4.7 · GDScript · no textures and no imported 3D models — every surface is a shaded engine primitive.*

---

## What it is

* **A 4D → 3D renderer.** `World4D` projects every slice of every object through a
  rotation of the `XW` plane around "now", then keeps only the slices whose `w'` is
  almost zero: that hyperplane is the 3D world the camera lives in.
* **Time slices instead of animation.** `Object4D` clones its template `time_slices`
  times and freezes each clone's `AnimationPlayer` at its own instant, so a door's
  opening animation becomes the door's *shape along the `w` axis*.
* **4D rotation matrices, not easing curves.** `x' = x·cos θ + w·sin θ` and
  `w' = −x·sin θ + w·cos θ`. Turning θ turns the room's history into geometry.
* **Custom shaders, offset per slice.** Clone `i` renders with `TIME − i·0.08 s` so a
  stack of hundreds of translucent slabs still reads as one coherent, breathing
  object instead of a stroboscope.
* **Collision follows visibility.** A slice that is not rendered does not block the
  player, so walking past the `w` where the floor exists makes you fall through the
  hole in time.

### The idea

A 3D scene is a slice of a 4D one. If `w` is the extra axis, the familiar `(x, y, z)`
room is what you get by cutting the 4D world with the hyperplane `w = 0`. Move or
rotate that hyperplane and objects appear, change or vanish — so *"the seal is broken
here, intact there"* stops being a timeline and becomes **shape**. From there, two
operations are enough to build a whole game:

1. **Slicing** — an object with a temporal extent (`w_start … w_end`) is spread along
   `w` as `time_slices` clones, each frozen at its own moment.
2. **Rotating the cut** — instead of cutting with `w = 0`, cut with a plane rotated by
   `angle_XW`. Space and time mix, and an object's history is laid out as a fan of
   slabs in front of you.

<!-- ============================================================================
     GIF 02 — À FOURNIR  ·  la rotation du plan XW  (le cœur du projet)
     fichier : docs/media/02_xw_rotation.gif
     montrer : caméra immobile dans le hall, [X] maintenu : la porte scellée
               (2000 tranches) s'ouvre en éventail jusqu'au plan à 90°
     format  : 800x450 · 8-12 s · boucle · ne pas bouger la caméra, garder
               un plan lisible
============================================================================ -->
![Rotating the XW plane unfolds the sealed gate into a fan of time slices](docs/media/02_xw_rotation.gif)

<!-- ============================================================================
     GIF 03 — À FOURNIR  ·  rembobinage vers le passé  ([I])
     fichier : docs/media/03_rewind_past.gif
     montrer : le sceau intact, puis [I] : le sceau disparaît, le monolithe de
               cristal et le Label3D « PASSÉ • LE SCEAU EST ROMPU » apparaissent
     format  : 800x450 · 6-10 s · boucle  (aller-retour I puis attente)
============================================================================ -->
![Rewinding with I brings back the broken seal and the past monolith](docs/media/03_rewind_past.gif)

---

## Controls

| Input | Action (`project.godot`) | What it does |
| --- | --- | --- |
| `W` `A` `S` `D` | `move_forward` … | walk (bound by **physical key position**, so it stays ZQSD-friendly on an AZERTY keyboard) |
| `Space` / `Shift` | `move_up` / `move_down` | jump / descend |
| Mouse | — | look around; the pointer is captured at start, `Esc` toggles it free and a click captures it again |
| `X` / `Z` | `rotate_xw_plus` / `rotate_xw_minus` | rotate the `XW` slice plane — the level unfolds into slabs |
| `O` | `reinit_xw` | snap the plane back to the present (`angle_XW = 0`) |
| `P` | `pi2_xw` | snap the plane to exactly 90°: history laid out flat in front of you |
| `I` | `T_glob_reinit` | rewind the camera's present to `w = 0`, i.e. travel back in time |

The in-game `Label3D` hint only advertises `I` / `WASD` / `Space` / `O`. Every binding is
remappable in the **Input Map** tab of the project settings.

---

## The demo level — `levels/level0.tscn`

A torch-lit hall opening onto a vault, all of it procedural. Five objects are `Object4D`
instances and each one stretches a different part of the `w` axis:

| Node | `w` range | Slices | Role |
| --- | --- | --- | --- |
| `GateSealed` | 1.8 → 240 | 2000 | the slab that seals the vault (`chrono_slab` shader); it only exists *after* the seal closes |
| `GateRising` | 0.8 → 1.8 | 24 | the same door mid-motion: 24 frozen poses of a door-lift `AnimationPlayer` |
| `SealBroken` | 0 → 2 | 8 | the three broken sealing bands, only in the past |
| `PastMonolith` | 0 → 2 | 8 | a lit orange crystal, placed via `position_3d_origin = (-5.2, 0, -3.6)` |
| `PastLabel` | 0 → 2 | 8 | a billboard `Label3D`: *« PASSÉ • LE SCEAU EST ROMPU »* |

Around them: `wall_stone` / `floor_stone` shaders, torch and brazier `OmniLight3D`s with
random-phased flicker, GPU dust particles, an altar with a floating relic, a bench, a crate.

`levels/level1.tscn` (a temple interior with windows and the neural sky) and
`levels/level2.tscn` (platforms driven by walk-on buttons) are further scenes still being
built — see [Roadmap](#roadmap--known-limits).

<!-- ============================================================================
     GIF 04 — À FOURNIR  ·  la porte traversée par l'axe w
     fichier : docs/media/04_gate_slices.gif
     montrer : caméra dans le hall, avancer vers la porte pendant que le w
               avance : la porte « monte » tranche par tranche devant vous
               (faire varier l'angle XW en même temps est encore mieux)
     format  : 800x450 · 8-12 s · boucle
============================================================================ -->
![The gate rising: the door's animation spread along w, crossed slice by slice](docs/media/04_gate_slices.gif)

<!-- ============================================================================
     GIF 05 — À FOURNIR  ·  la collision qui suit la visibilité
     fichier : docs/media/05_slice_collision.gif
     montrer : marcher sur une tranche de sol et tomber dans le « trou » quand
               le w la fait disparaître (ou passer à travers le sceau scellé
               en le regardant à un autre w)
     format  : 800x450 · 6-10 s · boucle
============================================================================ -->
![Falling through the hole in time when the floor's slice disappears](docs/media/05_slice_collision.gif)

---

## How it works

### `World4D` — the 4D → 3D renderer

`4DScripts/World4D.gd` runs once per frame (`_process`) and loops over every slice of
every `Object4D` child. The whole renderer is this:

```gdscript
var relative_w = ghost_w - global_T            # w relative to "now"
var x_prime = origin.x * c + relative_w * s    # rotation of the XW plane
var w_prime = -origin.x * s + relative_w * c   # c = cos(angle_XW), s = sin(angle_XW)

if abs(relative_w) < thickness:                # still cutting through w = 0 …
    ghost.set_ghost_visible(clone, true)
if abs(w_prime) < thickness:                   # … or through the rotated plane
    ghost.global_position = Vector3(x_prime, origin.y, origin.z)
    ghost.set_ghost_visible(clone, true)
else:
    ghost.set_ghost_visible(clone, false)
```

* `global_T` is the camera's present. It advances with real time (`delta`), or with an
  overridable speed used for rewind/fast-forward experiments.
* `thickness` is `time_slice_thickness * 0.505`, kept slightly above half a slice step
  so neighbouring slabs always overlap and the fan never flickers between frames.
* Rotating (`X` / `Z`) advances `angle_XW` at `5 rad/s` **scaled by `cos(angle_XW)`**:
  the plane eases as it approaches 90° instead of spinning forever, which is what makes
  the 90° view a stable "place" rather than a passing frame.

### `Object4D` — one object, many moments

`4DScripts/Object4D.gd` is the authoring side. Drop a `Template` child under it, set
`w_start`, `w_end` and `time_slices`, and at `_ready()` it:

* **Duplicates the template** `time_slices` times and hides + de-solidifies the original.
* **Gives every clone its own materials.** Without `duplicate()` on each surface override
  material, the per-slice shader parameters below would be shared by the whole stack.
* **Freezes the `AnimationPlayer` at the slice's own time.** Each clone switches to
  `ANIMATION_PROCESS_MANUAL` with `speed_scale = 0.0` and seeks to
  `fposmod(ghost_w - w_start, anim.length)`, so a hand-authored animation becomes geometry
  *along the `w` axis* instead of playtime. This is what turns a 2-second door lift into a
  ramp of static poses you can look at side by side.
* **Offsets each clone's shader in time** — `u_time_offset = i * shader_time_step`
  (0.08 s by default), consumed by every shader in `shaders/` — so the glow of the stack
  stays coherent when the slices separate.
* **Keeps collision in sync with visibility** (`ghost_collision_follows_visibility`), which
  is the rule that makes *"the floor has not been built yet"* a physical fact.

`SimpleObject4D` wraps any `PackedScene` into a 4D object with a synthetic one-second
"static" animation and a ±`temporal_extent` span, so a normal 3D prop becomes 4D with no
authoring work. `Player4D` goes further: it is itself an `Object4D` whose ghosts follow it
along `w`, so the avatar slices like everything else (inputs `move_w_forward` /
`move_w_back`). Both are written and working, but **not yet wired into the shipped levels** —
see [Roadmap](#roadmap--known-limits).

### `shaders/` — everything you see is code

| Shader | Type | Job |
| --- | --- | --- |
| `lib_noise.gdshaderinc` | include | hash/value noise, 5-octave FBM, and a triplanar-style world-space projection shared by all the others |
| `wall_stone`, `floor_stone` | spatial | procedural stone: courses of blocks, grout, chipped edges, dirt blotches, optional cyan glow seeping out of the joints |
| `chrono_slab` | spatial | the dark metal slab of the sealed gate with pulsing engraved glyph bands |
| `chrono_glow` | spatial, additive | unshaded energy bands and noise veins: torch flames, the past seal's cyan bands, the orange crystal, the floor rune ring |
| `neural_sky` | sky | procedural neural tissue: an approximated 3D *Voronoi* pass gives cell bodies and axons, with smooth "firing" pulses |

No textures are imported: every material is generated in the fragment shader from the world
position and normal, and the 4D time offset is applied there too.

<!-- ============================================================================
     GIF 06 — À FOURNIR  ·  les niveaux en cours (optionnel mais utile)
     fichier : docs/media/06_levels_wip.gif
     montrer : level1 (temple + ciel neuronal + boutons) et/ou level2
               (plateformes qui montent quand on marche sur les boutons)
     format  : 800x450 · 10-15 s · boucle
     (si les niveaux ne sont pas présentables, supprime ce bloc et le
      paragraphe qui le précède plutôt que de montrer quelque chose de cassé)
============================================================================ -->
![Level 1 and level 2, work in progress](docs/media/06_levels_wip.gif)

---

## Repository layout

```
4DScripts/            the 4D core
  World4D.gd            global_T + angle_XW: the 4D -> 3D slice renderer
  Object4D.gd           time-slice cloning, animation freezing, slice collision
  SimpleObject4D.gd     turns any PackedScene into a 4D object
  Player4D.gd           an Object4D avatar that can also move along w
player/
  Player3D.gd           CharacterBody3D + mouse look (used by the levels)
  player.tscn
levels/
  level0.tscn           the demo level filmed above (main scene)
  level1.tscn           temple interior, neural sky, walk-on buttons
  level2.tscn           platforms and lift driven by buttons
shaders/
  lib_noise.gdshaderinc shared noise + world-space projection
  wall_stone / floor_stone / chrono_slab / chrono_glow / neural_sky
assets/Torch.gd         light flicker (sine stack + random phase)
Scripts/Button3D.gd     a plate that sinks when something walks on it
SkyBox.tres             environment material built on neural_sky
node.tscn               scratch scene used while prototyping Object4D
docs/media/             the GIFs this README points at
godot-mcp-main/         a third-party Godot MCP server, kept here as a local
                        editor helper — it is not part of the game
```

## Running it

Nothing to build, no add-ons, no external assets: it is plain GDScript and `.tscn` files.

1. Install **Godot 4.7** (the project was made on `4.7.2-stable`, Forward+ renderer).
2. Open `project.godot` (or `godot --path .`) and press **F5** — the main scene is
   `levels/level0.tscn`.
3. `Esc` releases the captured mouse.

Two engine choices are pinned in `project.godot`: **Jolt Physics** for 3D and, on Windows,
the **D3D12** rendering device. If your machine has no D3D12 driver, delete the
`rendering_device/driver.windows` line and Godot will fall back to Vulkan.

## Roadmap / known limits

This is a prototype, and the parts that are not finished are the parts I find most
interesting to talk about:

* **Slice budgets.** `GateSealed` spends **2000 slices** on the range `w ∈ [1.8, 240]` even
  though barely two of them are ever on screen, so `level0` instantiates **2048 clones**
  (2000 of them on that one gate) — each with its own duplicated materials — at load time.
  Distance- and angle-based slice allocation, plus a clone pool, are the obvious wins.
* **Cost of the 90° view.** The fan view is the most readable one and also the most
  expensive, since every slice crossing the plane has to be drawn and shaded.
* **Authored `w`.** The next puzzles should require moving along `w` yourself — which is
  exactly what `Player4D` was written for — instead of only looking across it.
* **Wire up `SimpleObject4D` and `Player4D`** into the actual levels; today the levels use
  plain `Object4D` instances and `Player3D`.
* **Finish `level1` / `level2`,** and add **Windows and Web exports** so the prototype can be
  tried without the editor (and so this README can link a playable build).
* **No automated tests.** The renderer is verified visually; a headless test that asserts
  which slices are visible for a given `(global_T, angle_XW)` would be worth having.

## About

**Marcel Sartor** — engineering student at **École Polytechnique** (Palaiseau, France),
studying computer science and applied mathematics, looking for **game programming /
gameplay & engine internships**.

This prototype is the "4D puzzle game" entry of my CV, and it is where I work on the parts
of game programming I care about most: rendering maths, procedural content, and turning an
odd idea into something you can actually walk around in. It is a solo project — the 4D
system, the shaders, the level and its look are all mine.

* Contact: `marcel.sartor@polytechnique.edu`
* GitHub: [github.com/Luciferui](https://github.com/Luciferui) — this repository:
  [github.com/Luciferui/4D-Game](https://github.com/Luciferui/4D-Game)

No `LICENSE` file yet: the code is public so it can be read alongside a job application,
but please ask before reusing it.

---

## Media

Every animation above is recorded from the game running in the editor, and `docs/media/` is
the only place it should live — the shot list is:

| # | File | Shows | Suggested capture |
| --- | --- | --- | --- |
| 01 | `docs/media/01_hero.gif` | walk the hall, `X` to open the `XW` plane, `I` to rewind | 960x540, 10-15 s |
| 02 | `docs/media/02_xw_rotation.gif` | static camera, `X` held: the sealed gate unfolding | 800x450, 8-12 s |
| 03 | `docs/media/03_rewind_past.gif` | `I`: the seal gone, crystal + *« PASSÉ »* label appear | 800x450, 6-10 s |
| 04 | `docs/media/04_gate_slices.gif` | the gate rising slice by slice along `w` | 800x450, 8-12 s |
| 05 | `docs/media/05_slice_collision.gif` | walking, then falling through the hole in time | 800x450, 6-10 s |
| 06 | `docs/media/06_levels_wip.gif` | `level1` / `level2` preview | 800x450, 10-15 s |

Until a file is added, its alt text stands in for it. Keep each one under ~8 MB so GitHub
renders it inline, and don't cut mid-rotation — a loop that restarts before the plane starts
moving reads much better than one that snaps back at the most interesting frame.
