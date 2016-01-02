import controlP5.*;

ControlP5 cp5;
ControlWindow controlWindow;
ControlWindow viewWindow;
Textlabel readmeText;

boolean redraw = true;

DropdownList mode_l, interpolation_l;

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
int cont_w = 300;

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
  size(940, 600);

  cp5 = new ControlP5(this);

  cp5.addButton("Load Source Image")
    .setPosition(40, 40)
    .setSize(130, 39)
    ;

  cp5.addSlider("gamma_s")
    .setRange(0, 2)
    .setPosition(40, 100)
    .setSize(100, 25)
    ;

  cp5.addSlider("gain_s")
    .setRange(0, 4)
    .setPosition(40, 140)
    .setSize(100, 25)
    ;

  cp5.addSlider("rad_fish_val")
    .setRange(0, 2)
    .setPosition(40, 200)
    .setSize(100, 25)
    ;

  cp5.addSlider("dist_fish_val")
    .setRange(0, 2)
    .setPosition(40, 240)
    .setSize(100, 25)
    ;

  mode_l = cp5.addDropdownList("modeList")
    .setPosition(40, 340)
    ;

  customize(mode_l);
  mode_l.addItem("Inverted Fisheye Conv", 0);
  mode_l.addItem("Normal Fisheye Conv", 1);

  cp5.addButton("Save Image")
    .setPosition(40, 500)
    .setSize(100, 39)
    ;

  cp5.addButton("Exit")
    .setPosition(160, 500)
    .setSize(100, 39)
    ;

  base = createImage(size_x, size_y, RGB);
}

void fileSelected_load(File selection) {
  if (selection == null) {
    println("Window was closed or the user hit cancel.");
  } else {
    println("User selected " + selection.getAbsolutePath());
    base = loadImage(selection.getAbsolutePath());
  }
  redraw = true;
}

void customize(DropdownList ddl) {
  // a convenience function to customize a DropdownList
  ddl.setBackgroundColor(color(190));
  ddl.setItemHeight(20);
  ddl.setBarHeight(15);
  ddl.getCaptionLabel().set("dropdown");
  ddl.setColorBackground(color(60));
  ddl.setColorActive(color(255, 128));
}


void fileSelected_save(File selection) {
  if (selection == null) {
    println("Window was closed or the user hit cancel.");
  } else {
    println("User selected " + selection.getAbsolutePath());
    converted.save(selection.getAbsolutePath());
  }
}


public void controlEvent(ControlEvent theEvent) {
  if (theEvent.isFrom("Load Source Image")) {
    selectInput("Select a file to process:", "fileSelected_load");
  }

  if (theEvent.isFrom("Save Image")) {
    selectOutput("Select a file to write to:", "fileSelected_save");
  }

  if (theEvent.isGroup()) {
    // check if the Event was triggered from a ControlGroup
    println("event from group : "+theEvent.getGroup().getValue()+" from "+theEvent.getGroup());
  } else if (theEvent.isController()) {
    if(theEvent.getController().getName() == "modeList"){
      conv_mode = (int)theEvent.getController().getValue();
    }
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
  draw_image(tuned, cont_w, 0, thumb_w, thumb_h);
  draw_image(converted, cont_w, thumb_h, size_x, size_y);
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
