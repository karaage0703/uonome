import controlP5.*;

ControlP5 cp5;
ControlWindow controlWindow;
ControlWindow viewWindow;
Textlabel readmeText;

ListBox l;

int conv_mode = 0; // 0: Inverted Convert 1: Convert
//int interpolation = 1; // 0: Nearest neighbor 1: Bilinear 2: Bicubic

String imgPath;

PImage img0; // source image(base)
PImage tuned_img0; // source image(base)
PImage writeimg; // fisheye converted image

float gamma_s = 1.0; // gamma value for source image

float gain_s = 1;  // gain for source image

float rad_fish_val = 1;  // radius of fish eye
float dist_fish_val = 1;  // distance of fish eye
float rad_fish;
float dist_fish;

float[] lut_s = new float[256];
float[] lut_m = new float[256];

//Window Size
int view_width=1024, view_height=768;
int view_swidth0, view_sheight0;

int size_sx = 160;
int size_sy = 120;

int size_x = 640;
int size_y = 480;

void TuneImage(){
  for (int i = 0; i < 256; i++){
    lut_s[i] = 255*pow(((float)i/255),(1/gamma_s));
  }

  tuned_img0 = createImage(img0.width, img0.height, RGB);

  img0.loadPixels();

  for(int i = 0; i < img0.width*img0.height; i++){
    color tmp_color = img0.pixels[i];

    int tmp_r = (int)(lut_s[(int)red(tmp_color)]*gain_s);
    int tmp_g = (int)(lut_s[(int)green(tmp_color)]*gain_s);
    int tmp_b = (int)(lut_s[(int)blue(tmp_color)]*gain_s);
     
    tuned_img0.pixels[i] = color(tmp_r, tmp_g, tmp_b);
  }
}

void ImageFisheyeConverted(){
  writeimg = createImage(img0.width, img0.height, RGB);
  rad_fish = rad_fish_val * img0.width;
  dist_fish = dist_fish_val * img0.width;

  if(writeimg.width > size_x || writeimg.height > size_y){
    float k_width = (float)writeimg.width / (float)size_x;
    float k_height = (float)writeimg.height / (float)size_y;
    float k_max;

    if(k_width > k_height){
      k_max = k_width;
    }else{
      k_max = k_height;
    }

    view_width = (int)(writeimg.width/k_max);
    view_height = (int)(writeimg.height/k_max);
  }else{
    view_width = writeimg.width;
    view_height = writeimg.height;
  }

  tuned_img0.loadPixels();
  
  if(conv_mode == 0){ // inverted fisheye convert
    for(int y = 0; y < tuned_img0.height; y++){
      for(int x = 0; x < tuned_img0.width; x++){
        int pos = x + y*tuned_img0.width;
      
        int tmp_x = (int)(rad_fish * (x - tuned_img0.width/2) / sqrt(dist_fish * dist_fish
                          + (x - tuned_img0.width/2) * (x - tuned_img0.width/2)
                          + (y - tuned_img0.height/2) * (y - tuned_img0.height/2)) + tuned_img0.width/2);
                        
        int tmp_y = (int)(rad_fish * (y - tuned_img0.height/2) / sqrt(dist_fish * dist_fish
                          + (x - tuned_img0.width/2) * (x - tuned_img0.width/2)
                          + (y - tuned_img0.height/2) * (y - tuned_img0.height/2)) + tuned_img0.height/2);

        int tmp_pos = tmp_x + tmp_y*tuned_img0.width;

        if(tmp_x >= 0 && tmp_x < tuned_img0.width && tmp_y >=0 && tmp_y < tuned_img0.height){
          writeimg.pixels[pos] = tuned_img0.pixels[tmp_pos];
        }else{
          writeimg.pixels[pos] = color(0,0,0);
        }
      }
    }
  }else{ // normal fisheye convert
    for(int y = 0; y < tuned_img0.height; y++){
      for(int x = 0; x < tuned_img0.width; x++){
        int pos = x + y*tuned_img0.width;
      
        int tmp_x = (int)((x - tuned_img0.width/2) / rad_fish * sqrt(dist_fish * dist_fish
                          + (x - tuned_img0.width/2) * (x - tuned_img0.width/2)
                          + (y - tuned_img0.height/2) * (y - tuned_img0.height/2)) + tuned_img0.width/2);
                        
        int tmp_y = (int)((y - tuned_img0.height/2) / rad_fish * sqrt(dist_fish * dist_fish
                          + (x - tuned_img0.width/2) * (x - tuned_img0.width/2)
                          + (y - tuned_img0.height/2) * (y - tuned_img0.height/2)) + tuned_img0.height/2);

        int tmp_pos = tmp_x + tmp_y*tuned_img0.width;

        if(tmp_x >= 0 && tmp_x < tuned_img0.width && tmp_y >=0 && tmp_y < tuned_img0.height){
          writeimg.pixels[pos] = tuned_img0.pixels[tmp_pos];
        }else{
          writeimg.pixels[pos] = color(0,0,0);
        }
      }
    }    
  }

  writeimg.updatePixels();
}

void setup(){
  size(size_x, size_y+size_sy);

  cp5 = new ControlP5(this);

  controlWindow = cp5.addControlWindow("Tunewindow", 100, 100, 300, 600)
    .hideCoordinates()
    .setBackground(color(40))
    ;

  cp5.addButton("Load Source Image")
     .setPosition(40,40)
     .setSize(130,39)
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
     .setPosition(40,500)
     .setSize(100,39)
     .moveTo(controlWindow)
     ;

  cp5.addButton("Exit")
     .setPosition(160,500)
     .setSize(100,39)
     .moveTo(controlWindow)
     ;

  img0 = createImage(size_x, size_y, RGB);
  writeimg = createImage(size_x, size_y, RGB);
}

public void controlEvent(ControlEvent theEvent) {
  if(theEvent.isFrom("Load Source Image")) {
    imgPath = selectInput();
    img0 = loadImage(imgPath);

    if(img0.width > size_sx || img0.height > size_sy){
      float k_width = (float)img0.width / (float)size_sx;
      float k_height = (float)img0.height / (float)size_sy;
      float k_max;

      if(k_width > k_height){
        k_max = k_width;
      }else{
        k_max = k_height;
      }
      view_swidth0 = (int)(img0.width/k_max);
      view_sheight0 = (int)(img0.height/k_max);
    }else{
      view_swidth0 = img0.width;
      view_sheight0 = img0.height;
    }
  }

  if (theEvent.isGroup()) {
    // an event from a group e.g. scrollList
    conv_mode = (int)theEvent.group().value();
  }

  if(theEvent.isFrom("Save Image")) {
    String imgPath = selectOutput();
    writeimg.save(imgPath);
  }

  if(theEvent.isFrom("Exit")) {
    exit();
  }
}

void draw(){
  background(0);
  tuned_img0 = img0;

  TuneImage();
  ImageFisheyeConverted();

  image(tuned_img0, 0, 0, view_swidth0, view_sheight0);
  image(writeimg, 0, size_sy, view_width, view_height);
}
