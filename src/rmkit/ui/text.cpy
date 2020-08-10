#include "widget.h"
#include "../defines.h"
#include "../fb/stb_text.h"

namespace ui:
  // class: ui::Text
  // --- Prototype ---
  // class ui::Text: public ui::Widget:
  // -----------------
  // the ui::Text class is a Widget that can render a single line of text.
  class Text: public Widget:
    public:
    // function: Text Dropdown
    enum JUSTIFY { LEFT, CENTER, RIGHT }
    static int DEFAULT_FS
    int font_size
    string text
    JUSTIFY justify = JUSTIFY::CENTER

    // function: Constructor
    // parameters:
    //
    // x - x coord
    // y - y coord
    // w - width
    // h - height
    // t - the text to render in the widget
    Text(int x, y, w, h, string t): Widget(x, y, w, h):
      self.text = t
      self.font_size = DEFAULT_FS


    tuple<int, int> get_render_size():
      image := stbtext::get_text_size(self.text.c_str(), self.font_size)
      return image.w, image.h

    // TODO: cache the image buffer
    void redraw():
      image := stbtext::get_text_size(self.text.c_str(), self.font_size)

      image.buffer = (uint32_t*) malloc(sizeof(uint32_t) * image.w * image.h)
      memset(image.buffer, WHITE, sizeof(uint32_t) * image.w * image.h)

      leftover_x := self.w - image.w
      padding_x := 0

      switch self.justify:
        case JUSTIFY::LEFT:
          break
        case JUSTIFY::CENTER:
          if leftover_x > 0:
            padding_x = leftover_x / 2
          break
        case JUSTIFY::RIGHT:
          if leftover_x > 0:
            padding_x = leftover_x
          break

      fb->draw_text(self.text, self.x + padding_x, self.y, image, self.font_size)

      free(image.buffer)

  // class: ui::MultiText
  // --- Prototype ---
  // class ui::MultiText: public ui::Text:
  // -----------------
  // the MultiText class is for writing multiple lines of text, as it
  // automatically inserts line breaks where appropriate when rendering
  //
  // currently, MultiText does not support justification
  class MultiText: public Text:
    public:
    MultiText(int x, y, w, h, string t): Text(x, y, w, h, t):
      pass

    void redraw():
      cur_x := 0
      cur_y := 0
      lines := split(self.text, '\n')
      for auto line: lines:
        cur_x = 0
        tokens := split(line, ' ')
        int max_h = 0
        for auto w: tokens:
          w += " "
          image := stbtext::get_text_size(w.c_str(), self.font_size)
          image.buffer = (uint32_t*) malloc(sizeof(uint32_t) * image.w * image.h)
          max_h = max(image.h, max_h)
          memset(image.buffer, WHITE, sizeof(uint32_t) * image.w * image.h)
          if cur_x + image.w + 10 >= self.w:
            cur_x = 0
            cur_y += max_h
          self.fb->draw_text(w, self.x + cur_x, self.y + cur_y, image, self.font_size)
          free(image.buffer)
          cur_x += image.w
        cur_y += max_h

  int Text::DEFAULT_FS = 24
