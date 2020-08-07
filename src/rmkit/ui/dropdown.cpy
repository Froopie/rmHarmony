#include "button.h"
#include "layouts.h"
#include "../input/events.h"

namespace ui:
  class OptionSection: public ui::Button:
    public:
    string text

    OptionSection(int x, y, w, h, string t): ui::Button(x,y,w,h,t):
      self.mouse_inside = true
      self.textWidget->justify = ui::Text::JUSTIFY::CENTER

    bool ignore_event(input::SynMouseEvent &ev):
      return true

  template<typename T>
  class OptionButton: public ui::Button:
    public:
    T* tb
    string text
    int idx

    OptionButton(int x, y, w, h, T* tb, string text, int idx): \
                 tb(tb), text(text), idx(idx), ui::Button(x,y,w,h,text):
      self.x_padding = 10
      self.set_justification(ui::Text::JUSTIFY::LEFT)

    void on_mouse_click(input::SynMouseEvent &ev):
      self.tb->select(self.idx)
      self.dirty = 1

  class TextOption:
    public:
    string name
    icons::Icon icon = {NULL, 0}
    TextOption(string n, icons::Icon i): name(n), icon(i) {}
    TextOption(string n): name(n) {}

  template<class T>
  class DropdownSection:
    public:
    string name
    vector<shared_ptr<T>> options
    DropdownSection(string n): name(n):
      pass

    void add_options(vector<string> opts):
      for auto opt: opts:
        self.options.push_back(make_shared<T>(opt))

    void add_options(vector<pair<string, icons::Icon>> pairs):
      for auto pair: pairs:
        opt := pair.first
        icon := pair.second
        textopt := make_shared<T>(opt, icon)
        self.options.push_back(textopt)

  template<class O>
  class DropdownButton: public ui::Button:
    public:
    int selected
    int option_width, option_height, option_x, option_y
    enum DIRECTION { UP }
    DIRECTION dir = DIRECTION::UP
    vector<O> options
    vector<shared_ptr<DropdownSection<O>>> sections;
    ui::Scene scene = NULL

    DropdownButton(int x, y, w, h, vector<O> options, string name):\
                   options(options), ui::Button(x,y,w,h,name):
      self.select(0)

      self.set_option_offset(0, 0)
      self.set_option_size(w, h)

    void on_mouse_click(input::SynMouseEvent&):
      self.show_options()

    void set_option_offset(int x, y):
      self.option_x = x
      self.option_y = y

    void set_option_size(int width, height):
      self.option_width = width
      self.option_height = height

    void show_options():
      if self.scene == NULL:
        width, height = self.fb->get_display_size()
        ow := self.option_width
        oh := self.option_height
        self.options.clear()

        self.scene = ui::make_scene()
        layout := VerticalLayout(x + self.option_x, self.option_y, ow, height, self.scene)

        i := 0
        for auto section: self.sections:
          OptionSection *os
          if section->name != "":
            os = new OptionSection(0, 0, ow, oh, section->name)

          opts := section->options

          for auto option: opts:
            option_btn := new OptionButton<DropdownButton>(0, 0, ow, oh, self, option->name, i)
            if option->icon.data != NULL:
              option_btn->icon = option->icon
            layout.pack_end(option_btn)
            self.options.push_back(*option)
            i++

          if section->name != "":
            layout.pack_end(os)


      ui::MainLoop::show_overlay(self.scene)

    void select(int idx):
      self.selected = idx
      ui::MainLoop::hide_overlay()
      if idx < self.options.size():
        option := self.options[idx]
        self.icon = option.icon
        self.text = option.name

        self.on_select(idx)

    virtual void on_select(int idx):
      pass

  // class: ui::TextDropdown
  // --- Prototype ---
  // class ui::TextDropdown: public ui::DropdownButton:
  // ----------------
  // The TextDropdown is the most likely dropdown to use - 
  // you supply a list of options and the on_select function
  // will be called when one is selected.
  // 
  // ---
  //   dropdown := new TextDropdown(0, 0, 200, 50, "options");
  //   ds := dropdown->add_section("options");
  //   ds->add_options({ "foo", "bar", "baz });
  // ---
  class TextDropdown: public ui::DropdownButton<ui::TextOption>:
    public:
    // function: TextDropdown
    // x - 
    // y -
    // w - 
    // h - 
    // t - the name of the TextDropdown (used for debugging only)
    TextDropdown(int x, y, w, h, string t): \
      ui::DropdownButton<ui::TextOption>(x,y,w,h,{},t)
      self.text = t

    shared_ptr<DropdownSection<TextOption>> add_section(string t):
        ds := make_shared<DropdownSection<TextOption>>(t)
        self.sections.push_back(ds)
        return ds
