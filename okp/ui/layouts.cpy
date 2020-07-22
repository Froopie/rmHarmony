#include <algorithm>

#include "base.h"
#include "scene.h"
#include "../input/events.h"

#define DEBUG_LAYOUT
#define RANGE(x) x.begin(), x.end()
namespace ui:
  class Layout: public Widget:
    public:
    Scene scene
    vector<shared_ptr<Widget>> children
    int padding = 0

    static unordered_map<Scene, vector<Layout*>> scene_to_layouts;

    Layout(int x, y, w, h, Scene s): Widget(x,y,w,h), scene(s):
      if scene_to_layouts.find(s) == scene_to_layouts.end():
        scene_to_layouts[s] = {}

      scene_to_layouts[s].push_back(self)

    ~Layout():
      if scene_to_layouts.find(scene) != scene_to_layouts.end():
        it = find(RANGE(scene_to_layouts[scene]), self)
        if it == scene_to_layouts[scene].end():
          return

        scene_to_layouts[scene].erase(it)

    shared_ptr<Widget> add(Widget *w):
      sp = shared_ptr<Widget>(w)
      children.push_back(sp)
      scene->add(sp)
      return sp

    void hide():
      for auto w: children:
        w->hide()
      self.visible = false

    void show():
      for auto w: children:
        w->show()
      self.visible = true

    virtual void reflow():
      pass

    // Layouts generally don't receive events
    bool ignore_event(input::SynMouseEvent &ev):
      return true
  unordered_map<Scene, vector<Layout*>> Layout::scene_to_layouts = {};

  class AbsLayout: public Layout:
    public:
    AbsLayout(int x, y, w, h, Scene s): Layout(x,y,w,h,s):
      pass

  class AutoLayout: public Layout:
    public:
    class PackedWidget:
      public:
      shared_ptr<Widget> sp
      int padding

      PackedWidget(shared_ptr<Widget> sp, int padding=0): sp(sp), padding(padding):
        pass
        

    vector<PackedWidget> start
    vector<PackedWidget> end
    vector<PackedWidget> center

    AutoLayout(int x, y, w, h, Scene s): Layout(x,y,w,h,s):
      pass

    void pack_start(Widget *w, int padding=0):
      sp = self.add(w)
      self.start.push_back({sp, padding})

    void pack_end(Widget *w, int padding=0):
      sp = self.add(w)
      self.end.push_back({sp, padding})

    void pack_center(Widget *w, int padding=0):
      sp = self.add(w)
      self.center.push_back({sp})

    virtual void reflow():
      pass

  class VerticalLayout: public AutoLayout:
    public:
    VerticalLayout(int x, y, w, h, Scene s): AutoLayout(x,y,w,h,s):
      pass

    void reflow():
      offset = 0
      shared_ptr<Widget> w
      for auto pw : self.start:
        w = pw.sp
        padding = pw.padding

        w->y += offset + self.y + padding
        w->x += self.x
        offset += w->h + padding

      offset = self.h
      for auto pw : self.end:
        w = pw.sp
        padding = pw.padding

        w->y = self.y + offset - w->h - padding
        w->x += self.x
        offset -= w->h + padding
     
      for auto pw : self.center:
        w = pw.sp
        leftover = self.h - w->h
        padding_y = 0
        if leftover > 0:
          padding_y = leftover / 2
        w->y = self.y + padding_y
        w->x += self.x

  class HorizontalLayout: public AutoLayout:
    public:
    HorizontalLayout(int x, y, w, h, Scene s): AutoLayout(x,y,w,h,s):
      pass

    void reflow():  
      offset = 0
      shared_ptr<Widget> w
      for auto pw : self.start:
        w = pw.sp
        padding = pw.padding
        w->x += offset + self.x + padding
        w->y += self.y
        offset += w->w + padding

      offset = self.w
      for auto pw : self.end:
        w = pw.sp
        padding = pw.padding
        w->x = self.x + offset - w->w - padding
        w->y += self.y
        offset -= w->w + padding

      for auto pw : self.center:
        w = pw.sp
        padding = pw.padding
        leftover = self.w - w->w
        padding_x = 0
        if leftover > 0:
          padding_x = leftover / 2
        w->x = self.x + padding_x
        w->y += self.y

