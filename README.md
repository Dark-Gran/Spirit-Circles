# SMC
  
**WORK IN PROGRESS**  
  
Game based on a [previous prototype](https://github.com/Dark-Gran/SaveMeCircles).  
  
To address performance issues of the prototype, Box2D engine (and LibGDX in consequence) has been replaced with Godot, as its "bodies" offer better support for the desired "non-newtonian" behaviour of objects (and therefore gameplay).  
  
Godot 3.x does not support simulating the world in the extent in which Box2D does, however such simulation has been deemed unnecessary as its only purpose was to "help with aim", which can also be done using raytracing (which is a _much_ more lightweight solution).  
Simulating the "future state of physics" constantly and in real-time (as was possible in the prototype) also goes against the original "chilled chaos" idea both visually and gameplay-wise.  
  
_(to be expanded)_  
