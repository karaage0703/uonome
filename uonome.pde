import controlP5.*;

ControlP5 cp5;
ControlWindow controlWindow;
ControlWindow viewWindow;
Textlabel readmeText;

boolean redraw = true;

ListBox l;

int conv_mode = 0; // 0: Inverted Convert 1: Convert
//int interpolation = 1; // 0: Nearest neighbor 1: Bilinear 2: Bicubic

PImage base; // source image(base)
PImage tuned; // tuned image
PImage converted; // fisheye converted image

float gamma_s = 1.0; // gamma value for source image
float gain_s = 1;  // gain for source image

float rad_fish_val = 1;  // radius of fish eye
float dist_fish_val = 1;  // distance of fish eye

int size_x = 640;
int size_y = 480;
int thumb_w = 160;
int thumb_h = 120;

PImage TuneImage(PImage src) {
  float[] lut_s = new float[256];
  for (int i = 0; i < 256; i++) {
    lut_s[i] = 255*pow(((float)i/255), (1/gamma_s));
  }

  PImage res = createImage(src.width, src.height, RGB);

  src.loadPixels();

  for (int i = 0; i < src.width*src.height; i++) {
    color tmp_color = src.pixels[i];
    res.pixels[i] = color(
    (int)(lut_s[(int)red(tmp_color)]*gain_s), 
    (int)(lut_s[(int)green(tmp_color)]*gain_s), 
    (int)(lut_s[(int)blue(tmp_color)]*gain_s)
      );
  }
  return res;
}

PImage ImageFisheyeConverted(PImage src) {
  PImage res = createImage(src.width, src.height, RGB);
  src.loadPixels();

  for (int y = 0; y < src.height; y++) {
    for (int x = 0; x < src.width; x++) {
      int dx = x - src.width/2;
      int dy = y - src.height/2;
      // normal fisheye convert
      float rate = sqrt(sq(dist_fish_val * src.width) + sq(dx) + sq(dy)) 
        / (rad_fish_val * src.width);
      if (conv_mode == 0) { // inverted fisheye convert
        rate = 1 / rate;
      }
      int tmp_x = (int)(dx * rate + src.width/2);
      int tmp_y = (int)(dy * rate + src.height/2);

      int pos = x + y*src.width;
      if (tmp_x >= 0 && tmp_x < src.width && tmp_y >=0 && tmp_y < src.height) {
        res.pixels[pos] = src.pixels[tmp_x + tmp_y*src.width];
      }
      else {
        res.pixels[pos] = color(0, 0, 0);
      }
    }
  }

  res.updatePixels();
  return res;
}

void setup() {
  size(size_x, size_y+thumb_h);

  cp5 = new ControlP5(this);


  controlWindow = cp5.addControlWindow("Tunewindow", 100, 100, 300, 600)
    .hideCoordinates()
      .setBackground(color(40))
        ;

  cp5.addButton("Load Source Image")
    .setPosition(40, 40)
      .setSize(130, 39)
        .moveTo(controlWindow)
          ;

  cp5.addSlider("gamma_s")
    .setRange(0, 2)
      .setPosition(40, 100)
        .setSize(100, 25)
          .moveTo(controlWindow)
            ;

  cp5.addSlider("gain_s")
    .setRange(0, 4)
      .setPosition(40, 140)
        .setSize(100, 25)
          .moveTo(controlWindow)
            ;

  cp5.addSlider("rad_fish_val")
    .setRange(0, 2)
      .setPosition(40, 200)
        .setSize(100, 25)
          .moveTo(controlWindow)
            ;

  cp5.addSlider("dist_fish_val")
    .setRange(0, 2)
      .setPosition(40, 240)
        .setSize(100, 25)
          .moveTo(controlWindow)
            ;

  l = cp5.addListBox("myList")
    .setPosition(40, 340)
      .setSize(120, 180)
        .setItemHeight(39)
          .setBarHeight(20)
            .setColorBackground(color(40, 128))
              .setColorActive(color(255, 128))
                .moveTo(controlWindow)
                  ;

  l.captionLabel().toUpperCase(true);
  l.captionLabel().set("Convert Mode");
  l.captionLabel().setColor(0xffff0000);
  l.captionLabel().style().marginTop = 3;
  l.valueLabel().style().marginTop = 3;

  ListBoxItem lbi;
  lbi = l.addItem("Inverted FishEyeConv", 0);
  lbi.setColorBackground(0xffff0000);
  lbi = l.addItem("Normal FishEyeConv", 1);
  lbi.setColorBackground(0xffff0000);

  cp5.addButton("Save Image")
    .setPosition(40, 500)
      .setSize(100, 39)
        .moveTo(controlWindow)
          ;

  cp5.addButton("Exit")
    .setPosition(160, 500)
      .setSize(100, 39)
        .moveTo(controlWindow)
          ;

  base = createImage(size_x, size_y, RGB);
}

public void controlEvent(ControlEvent theEvent) {
  if (theEvent.isFrom("Load Source Image")) {
    base = loadImage(selectInput());
  }

  if (theEvent.isGroup()) {
    // an event from a group e.g. scrollList
    conv_mode = (int)theEvent.group().value();
  }

  if (theEvent.isFrom("Save Image")) {
    converted.save(selectOutput());
  }

  if (theEvent.isFrom("Exit")) {
    exit();
  }
  redraw = true;
}

void draw() {
  background(0);
  if (redraw) {
    redraw = false;
    tuned = TuneImage(base);
    converted = ImageFisheyeConverted(tuned);
  }
  draw_image(tuned, 0, 0, thumb_w, thumb_h);
  draw_image(converted, 0, thumb_h, size_x, size_y);
}

void draw_image(PImage img, int x, int y, int lim_w, int lim_h) {
  int vw = img.width; //vw: view width
  int vh = img.height; //vh: view height
  if (vw > lim_w || vh > lim_h) {
    //rr: reduce rate
    float rr = min((float)lim_w / (float)vw, (float)lim_h / (float)vh);
    vw = (int)(vw * rr);
    vh = (int)(vh * rr);
  }
  image(img, x, y, vw, vh);
}

