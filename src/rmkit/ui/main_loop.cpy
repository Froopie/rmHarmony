// file: main_loop.cpy
//
// Every app usually has a main loop. rMkit's main loop is managed with the
// ui::MainLoop class. In general, an app should look like the following:
//
// --- Code
// // build widgets and place them in scenes
// my_scene = build_scene()
// ui::MainLoop::set_scene(my_scene)
//
// while true:
//   // perform app work, like dispatching events
//   ui::MainLoop::main()
//   // redraw any widgets that marked themselves dirty
//   ui::MainLoop::redraw()
//   // read input (blocking read)
//   ui::MainLoop::read_input()
// ---
//

#include "../defines.h"

#include "../util/signals.h"
#include "../input/input.h"
#include "../fb/fb.h"
#include "scene.h"
#include "widget.h"
#include "task_queue.h"

#include <unistd.h>

namespace ui:
  PLS_DEFINE_SIGNAL(KEY_EVENT, input::SynKeyEvent)
  PLS_DEFINE_SIGNAL(MOUSE_EVENT, input::SynMouseEvent)

  // class: ui::MainLoop
  // The MainLoop is responsible for redrawing widgets, dispatching events, and
  // other core work that happens on each iteration of the app.
  class MainLoop:
    public:
    static shared_ptr<framebuffer::FB> fb

    static Scene scene
    static Scene overlay
    static bool overlay_is_visible

    static input::Input in

    // variable: motion_event
    // motion_event is used for subscribing to motion_events
    //
    //
    // ---Code
    // // d is of type input::SynMouseEvent
    // MainLoop::motion_event += [=](auto &d) { };
    // ---
    static MOUSE_EVENT motion_event

    // variable: key_event
    // key_event is used for subscribing to key_events
    //
    //
    // ---Code
    // // d is of type input::SynKeyEvent
    // MainLoop::key_event += [=](auto &d) { };
    // ---
    static KEY_EVENT key_event

    // returns whether the supplied widget is visible
    static bool is_visible(Widget *w):
      if overlay_is_visible:
        for auto widget : overlay->widgets:
          if widget.get() == w:
            return true
      for auto widget : scene->widgets:
        if widget.get() == w:
          return true

      return false

    // function: redraw
    //   sync the framebuffer to the screen, required in order to update
    //   what the screen is showing after any draw calls
    static void redraw():
      fb->redraw_screen()

    // dispatch input events to their widgets / if event.stop_propagation()
    // was called in the event handler, / then the event will not be handled
    // here.
    static void handle_events():
      for auto ev : in.all_motion_events:
        MainLoop::motion_event(ev)
        if ev._stop_propagation:
          continue
        handle_motion_event(ev)
        fb->last_mouse_ev = ev


      for auto ev : in.all_key_events:
        MainLoop::key_event(ev)
        if ev._stop_propagation:
          continue
        handle_key_event(ev)


    // function: main
    //
    // this function does several thinsg:
    // 
    // - dispatches input events to widgets
    // - runs tasks in the task queue
    // - redraws the current scene and overlay's dirty widgets
    static void main():
      handle_events()

      TaskQueue::run_task()
      scene->redraw()
      if overlay_is_visible:
        overlay->redraw()

    /// blocking read for input
    static void read_input():
      in.listen_all()

    /// queue a redraw for all the widgets on the visible scenes
    static void refresh():
      scene->refresh()
      if overlay_is_visible:
        overlay->refresh()

    // function: set_scene
    // set the main scene for the app to display when drawing
    static void set_scene(Scene s):
      scene = s

    static void toggle_overlay(Scene s):
      if !overlay_is_visible || s != overlay:
        show_overlay(s)
      else:
        hide_overlay()

    // function: show_overlay
    // set the main scene for the app to display when drawing
    static void show_overlay(Scene s):
      overlay = s
      overlay_is_visible = true
      Widget::fb->clear_screen()
      MainLoop::refresh()

    // function: hide_overlay
    // hide the overlay
    static void hide_overlay():
      if overlay_is_visible:
        overlay_is_visible = false
        Widget::fb->clear_screen()
        MainLoop::refresh()

    // clear and refresh the widgets on screen
    // useful if changing scenes or otherwise
    // expecting the whole screen to change
    static void full_refresh():
      Widget::fb->clear_screen()
      MainLoop::refresh()

    // dispatch button presses to their widgets
    static void handle_key_event(input::SynKeyEvent &ev):
      display_scene := scene
      if overlay_is_visible:
        display_scene = overlay

      for auto widget: display_scene->widgets:
        widget->on_key_pressed(ev)

    // TODO: refactor this into cleaner code
    // dispatch mouse / touch events to their widgets
    static bool handle_motion_event(input::SynMouseEvent &ev):
      display_scene := scene
      if overlay_is_visible:
        display_scene = overlay

      bool is_hit = false
      bool hit_widget = false
      if ev.x == -1 || ev.y == -1:
        return false

      mouse_down := ev.left || ev.right || ev.middle

      widgets := display_scene->widgets;
      for auto it = widgets.rbegin(); it != widgets.rend(); it++:
        widget := *it
        if widget->ignore_event(ev) || !widget->visible:
          continue

        if ev._stop_propagation:
          break

        is_hit = widget->is_hit(ev.x, ev.y)

        prev_mouse_down := widget->mouse_down
        prev_mouse_inside := widget->mouse_inside
        prev_mouse_x := widget->mouse_x
        prev_mouse_y := widget->mouse_y

        widget->mouse_down = mouse_down && is_hit
        widget->mouse_inside = is_hit

        if is_hit:
          if widget->mouse_down:
            widget->mouse_x = ev.x
            widget->mouse_y = ev.y
            // mouse move issued on is_hit
            widget->on_mouse_move(ev)
          else:
            // we have mouse_move and mouse_hover
            // hover is for stylus
            widget->on_mouse_hover(ev)


          // mouse down event
          if !prev_mouse_down && mouse_down:
            widget->on_mouse_down(ev)

          // mouse up / click events
          if prev_mouse_down && !mouse_down:
            widget->on_mouse_up(ev)
            widget->on_mouse_click(ev)

          // mouse enter event
          if !prev_mouse_inside:
            widget->on_mouse_enter(ev)

          hit_widget = true
        else:
          // mouse leave event
          if prev_mouse_inside:
            widget->on_mouse_leave(ev)

      if overlay_is_visible && mouse_down && !hit_widget:
        MainLoop::hide_overlay()

      return hit_widget
  ;

  Scene MainLoop::scene = make_scene()
  Scene MainLoop::overlay = make_scene()
  bool MainLoop::overlay_is_visible = false
  input::Input MainLoop::in = {}

  MOUSE_EVENT MainLoop::motion_event
  KEY_EVENT MainLoop::key_event

  shared_ptr<framebuffer::FB> MainLoop::fb = framebuffer::get()

  std::mutex TaskQueue::task_m = {}
  deque<std::function<void()>> TaskQueue::tasks = {}
