import processing.video.*;

String url;
String printerName;

Capture cam;
PImage border;
PImage photo[]       = new PImage[4];
PGraphics strip;
int startTime;
int photosTaken         = -1;
int countdown           = 3000;
int flashLength         = 300;
float flashAlpha        = 0;
String countString      = "";
int effect              = 0;
int widthDif;
int state               = 0;
PFont font;
int count = 0;
String lastCount;
String imgDir;
int rgb[] = {227,25,55};
boolean wifiStatus = true;
boolean printStrip = true;
String tagId ="";
String lastTag = "";
String eventId;
String locationId;

import ddf.minim.*;

Minim minim;
AudioSample bloop, shutter;



void setup() {
  size(1920, 1080);
  imageMode(CENTER);
  rectMode(CENTER);
  ellipseMode(CENTER);
  smooth();
  noStroke();

  border = loadImage("photo-strip.png");
  String config[] = loadStrings("config.txt");
  url = split(config[0],"=")[1];
  printerName = split(config[1],"=")[1];
  eventId = split(config[2],"=")[1];
  locationId = split(config[3],"=")[1];

  ////////         FONTS       /////////
  //////////////////////////////////////
  minim = new Minim(this);
  bloop = minim.loadSample("sound/bloop.mp3", 2048);
  shutter = minim.loadSample("sound/shutter.wav", 2048);
  
  ///////// Directory ////////////////
  imgDir = dataPath("images");
  println(dataPath("images"));
  println(timestamp());

  ////////         FONTS       /////////
  //////////////////////////////////////

  font = createFont("Swis721 Blk BT", 1200);
  textFont(font);
  textAlign(CENTER);
  textLeading(140);


  ////////        CAMERA       /////////
  //////////////////////////////////////
  String[] cameras = Capture.list();
  if (cameras.length == 0) {
    println("There are no cameras available for capture.");
    exit();
  } 
  else {
    println("Available cameras:");
    for (int i = 0; i < cameras.length; i++) {
      println(cameras[i]);
    }
  }

  cam = new Capture(this, 1920, 1080, cameras[0]);
  cam.start();
  
  for(int i =0; i<photo.length; i++){
     photo[i] = createImage(1440, 1080, RGB);
  }


  ////////  PHOTOS + PRINT /////////
  //////////////////////////////////

  widthDif = (cam.width - photo[0].width);
  strip = createGraphics(1200, 1800, P2D);
  

  ////////     UPLOADER    /////////
  //////////////////////////////////
  setupPost();
}

void draw() {

  if (cam.available() == true && state<2) {
    background(0);
    cam.read();
    cameraMirror();
  }

  switch(state) {
  case 0:
  
    fill(rgb[0],rgb[1],rgb[2], floor((sin(frameCount)+1)*255.0/2.0));
    textFont(font, 360);
    text("TOUCH", width/2, height*.4);
    textFont(font, 480);
    text("HERE", width/2, height*.8);

    break;
  case 1:
    shootPhoto();
    fill(255, flashAlpha);
    rect(width/2, height/2, width, height);
    break;
  case 2:
    if(millis() - startTime > 10000) stateChange();

    break;
  }
  // CREATE LETTERBOX FOR CAMERA RATIO
  fill(0);
  rect(0+widthDif/4, height/2, widthDif/2, height);
  rect(width-widthDif/4, height/2, widthDif/2, height);
  
  fill(255,0,0);
  textFont(font, 24);
  if(wifiStatus){
     // text("wifi active", 50, height-50); 
  }
  else text("photo upload\n not available", 100, 50);
}

void cameraMirror() {
  pushMatrix();
  scale(-1, 1);
  image(cam, -width/2, height/2, width, height);
  popMatrix();

}


void mouseReleased() {
  switch(state) {
  case 0: // begin
  tagId = "NA";
    stateChange();
    break;
  }
  println(state);
}

void stateChange() {

  println("Switch state from " + state);

  switch(state) {
  case 0: // begin
    startTime = millis();
    println("begin countdown");
    break;

  case 1: // printing
    
    startTime = millis();
    
    for (int i=0;i<photo.length;i++) {
      image(photo[i], (i%2+.5)*photo[i].width/2+widthDif/2, (floor(i/2)+.5)*photo[i].height/2, photo[i].width/2, photo[i].height/2 );
    }
    stroke(0);
    strokeWeight(4);
    line(0, height/2, width, height/2);
    line(width/2, 0, width/2, height);
    noStroke();

    fill(rgb[0],rgb[1],rgb[2],150);
    textFont(font, 200);
    text("Printing...", width/2, height*.6);

    strip.beginDraw();
    strip.imageMode(CENTER);
    strip.background(255);
    for (int i=0; i<2; i++) {
      for (int j=0; j<photo.length; j++) {
        strip.image(photo[j], 300+600*i, 213+j*400, 510, 382);
      }
    }
    strip.image(border, strip.width/2, strip.height/2);
    strip.endDraw();
    
    // upload images
    uploadImage(photo, tagId);
    tagId = "";
    
    // Save images to hard drive with timestamp (strip + 4 full res photos)
    String savePath = imgDir + "\\" +timestamp() + "-";
    for(int i=0; i < photo.length; i++) photo[i].save(savePath + i + ".jpg");
    strip.save(savePath + "s.jpg");
    
    //savePath = savePath.replace("\\", "\\\\");
    String cmd = "rundll32 shimgvw.dll ImageView_PrintTo /pt \"" + savePath + "s.jpg\" \"" + printerName + "\""; 
    if(printStrip) open(cmd);

    break;
  case 2: // printing
    state = -1;
    photosTaken=-1;

    break;
  }

  state++;
}

String timestamp(){
  return year() + nf(month(),2) + nf(day(),2) +nf(hour(),2) +nf(minute(),2)+nf(second(),2);
  
}

boolean shootPhoto() {
  int elapsed = millis() - startTime;

  if (elapsed < countdown) {
    countString = String.valueOf(ceil((countdown-elapsed)/1000)+1);
    if (!countString.equals(lastCount)) {
      bloop.trigger();
      println("countdown" + countString);
    }
    lastCount = countString;
    countDisplay();
    return true;
  }
  else if (elapsed < countdown+flashLength) {
    if (!countString.equals("")) shutter.trigger();
    countString = "";
    // if (flashAlpha == 0) shutter.trigger();
    flashAlpha = sin(norm(elapsed, countdown, countdown+flashLength)*PI)*255;
    return false;
  }
  else {
    flashAlpha=0;
    photosTaken ++; 
    println("saving to photo " + photosTaken);
    //photo[photosTaken].background(count*60);
    photo[photosTaken] = cam.get((1920-1440)/2,0,1440,1080);

    startTime = millis();
    if (photosTaken>=3) stateChange();
    return true;
  }


}

void countDisplay(){
  fill(rgb[0],rgb[1],rgb[2], 150);
  textAlign(CENTER);
  textFont(font, 1200);
  text(countString, width/2, height*.9);  
}


void keyPressed() {
  if(state == 0){
  if (key != ENTER) tagId += key;
  else {
      stateChange();
    }
  }
 
}

