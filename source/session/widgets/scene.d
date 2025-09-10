module session.widgets.scene;
import inui.widgets;
import inui.app;
import inochi2d;

import std.stdio : writeln;
import std.file : exists;
import inui.core.msgbox;

/**
    The Inochi2D Scene
*/
class Scene : View {
private:
    Puppet[] puppets;

protected:

    override
    void onDocked(View to) { }

public:

    /**
        Whether the view is "open" and being rendered.
    */
    override @property bool isOpen() => true;

    this() { 
        super("in_scene", "Scene");
        this.styleClass = "scene";
    }
}
