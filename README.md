# Framework Graph
A simple tool for generated the dependency graph between frameworks and libraries. 

Dependency type:
- Black solid lines stand for strong dependency (LC_LOAD_DYLIB);
- Black dash lines stand for weak dependency (LC_LOAD_WEAK_DYLIB);
- Blue solid lines stand for reexport dependency (LC_REEXPORT_DYLIB);
- Red solid lines stand for circular dependency;

Only work in Simulator.

## Example
### Graph for "render" related frameworks
![image](Example/render.png)

### Graph for "audio" related frameworks
![image](Example/audio.png)

### Graph for "video" related frameworks
![image](Example/video.png)

### Graph for "AVFoundation" related frameworks
![image](Example/avfoundation.png)
