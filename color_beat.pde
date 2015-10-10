 //<>//


/* Color Beat: Detect colors of colors on video and play audio corresponding to color*/

import processing.video.*;
import gab.opencv.*;
import java.awt.Rectangle;
import java.util.Arrays;
import java.util.Collections;
import ddf.minim.*;


// Initialize video
Capture cam;
OpenCV opencv;

// Initialize audio
int maxColors = 3; //The maximum number of colors that can be detected by this application
Minim minim;
AudioPlayer[][] sounds;
String[][] sound_files;
int sound_file_option=2;//set to 0,1,2 
int loop_sound=1; //set to 1 to loop sounds and 0 to play once
int maxSoundsPerColor; //any color can trigger upto 5 sounds
int sWidth = 640;
int sHeight = 480;

// <1> Set the range of Hue values for our filter
//ArrayList<Integer> colors;
int[] hues; //hue of the selected pixel
int[] colors; 
int[] ranked_colors; //rank index of color in descending order of area, sets correspondance to audio files
float[] color_areas;
float[] color_areas_ranked; //sorted areas of colors in descending order
int rangeWidth = 5; //tolerance on color selection
float minColorArea=200; //Minimum color area required to display bounding box and trigger sound

PImage[] outputs;
PImage src;
ArrayList<Contour> contours;

int colorToChange = -1;
float track_volume; 
int track_idx; 
int sound_idx;
int skip_amount; 

void setup() {
  
  String[] cameras = Capture.list(); //Get a list of all the cameras pluged in 
   
   
  // Specify file names for all the sound files 
  // Make sure there are as many audio tracks(first dimension of array) as there are colors 


  if(sound_file_option==0){


   // Initilize a list of audio files


     maxSoundsPerColor=1;
     sound_files= new String[maxColors][maxSoundsPerColor]; 

     sound_files[0][0]="sound_0.wav";
     sound_files[1][0]="sound_1.mp3";
     sound_files[2][0]="sound_2.wav";

}    
  else if(sound_file_option==1){
     
     maxSoundsPerColor=5;
     sound_files= new String[maxColors][maxSoundsPerColor]; 
     
     sound_files[0][0]="conga/conga-lick.wav";
     sound_files[0][1]="conga/conga-muffled-2.wav";
     sound_files[0][2]="conga/conga-open-1.wav";
     sound_files[0][3]="conga/conga-open-2.wav";
     sound_files[0][4]="conga/conga-slap-1.wav";

     sound_files[1][0]="cymbal/belltree.wav";
     sound_files[1][1]="cymbal/cymbal-ride-roll-long.wav";
     sound_files[1][2]="cymbal/cymbal-sizzle-stick.wav";
     sound_files[1][3]="cymbal/cymbal-splash-stick.wav";
     sound_files[1][4]="cymbal/sleighbells.wav";
     
     sound_files[2][0]="flute/flute-alto-C-vib.wav";
     sound_files[2][1]="flute/flute-alto-lick.wav";
     sound_files[2][2]="flute/flute-C-octave0-vib.wav";
     sound_files[2][3]="flute/flute-C-octave1-vib.wav";
     sound_files[2][4]="flute/flute-C-octave2-vib.wav";  
  }
  else if(sound_file_option==2){ 
     maxSoundsPerColor=1;
     sound_files= new String[maxColors][maxSoundsPerColor]; 
     sound_files[0][0]="comic/flexatone.wav"; 
     sound_files[1][0]="comic/whistle-owl.wav"; 
     sound_files[2][0]="comic/whistle-slide.wav";
     
  }  
  
  

  cam = new Capture(this, sWidth, sHeight);
  opencv = new OpenCV(this, cam.width, cam.height);
  contours = new ArrayList<Contour>();
  
  size(640, 480);  
  
  if (cameras.length == 0) {
    println("There are no cameras available...");
    size(400, 400);
    exit();
  }
  else {
    println("Available cameras:");
    for (int i = 0; i < cameras.length; i++) {
      println(cameras[i]);
    }
    cam = new Capture(this, sWidth, sHeight);
   
   // Array for detection colors
    colors = new int[maxColors];
    ranked_colors=new int[maxColors];
    color_areas=new float[maxColors];
    hues = new int[maxColors];
    outputs = new PImage[maxColors];
   
    //Sound setup
    minim = new Minim(this);
    sounds = new AudioPlayer[maxColors][maxSoundsPerColor];

    for (int i=0; i<maxColors; i++){
      for(int j=0; j<maxSoundsPerColor; j++){
         sounds[i][j] = minim.loadFile(sound_files[i][j]);
      }
    }

    cam.start();
    cam.loadPixels();
    
  }
 }


void draw() {
  if (cam.available() == true) {
    cam.read();
  } 
  set(0, 0, cam);
  
   // <2> Load the new frame of our movie in to OpenCV
  opencv.loadImage(cam);
  
  // Tell OpenCV to use color information
  opencv.useColor();
  src = opencv.getSnapshot();
  
  // <3> Tell OpenCV to work in HSV color space.
  opencv.useColor(HSB);

  detectColors();
  
  displayImages(); 

  rankColorAreas(); 
  
  playColorSound();
 
  // Print text if new color expected
  textSize(20);
  stroke(255);
  fill(255);
  
  if (colorToChange > -1) {
    text("click to change color " + colorToChange, 10, 25);
  } else {
    text("press key [1-3] to select color", 10, 25);
  }
  
 }

//////////////////////
// Detect Functions
//////////////////////

void detectColors() {
    
  for (int i=0; i<hues.length; i++) {
    
    if (hues[i] <= 0) continue;
    
    opencv.loadImage(src);
    opencv.useColor(HSB);
    
    // <4> Copy the Hue channel of our image into 
    //     the gray channel, which we process.
    opencv.setGray(opencv.getH().clone());
    
    int hueToDetect = hues[i];
    //println("index " + i + " - hue to detect: " + hueToDetect);
    
    // <5> Filter the image based on the range of 
    //     hue values that match the object we want to track.
    opencv.inRange(hueToDetect-rangeWidth/2, hueToDetect+rangeWidth/2);
    
    // Add here some image filtering to detect blobs better       
    opencv.erode();
    opencv.dilate();
 
    // <6> Save the processed image for reference.
    outputs[i] = opencv.getSnapshot();
 
  }
  

}

//////////////////////
// Display Functions
//////////////////////

void displayImages(){
  // Show images
  image(src, 0, 0);

  for (int i=0; i<outputs.length; i++) {

    if (outputs[i] != null) {
      image(outputs[i], width-src.width/4, i*src.height/4, src.width/4, src.height/4);
      opencv.loadImage(outputs[i]);
      contours = opencv.findContours(true,true);
      if(contours.size()>0){
        displayContoursBoundingBoxes(i);
      }
    }
      noStroke();
      fill(colors[i]);
      rect(src.width, i*src.height/4, 30, src.height/4);
    }
    
}

void displayContoursBoundingBoxes(int i) {
  
  if(i<maxColors){
  //get the biggest contours for in color image i
    Contour contour = contours.get(0); 
    color_areas[i]=contour.area();

    if(color_areas[i]>minColorArea){

      Rectangle rect = contour.getBoundingBox();
          
      int r=(int)red(colors[i]);
      int g=(int)green(colors[i]);
      int b=(int)blue(colors[i]);
      stroke(r,g,b);
      fill(r,g,b,150);
      strokeWeight(2);
      rect(rect.x, rect.y, rect.width, rect.height);
    }
  }

}


//////////////////////
// Sort Colors by Area
//////////////////////
void rankColorAreas(){
  
  // Rank colors by area 
  color_areas_ranked=color_areas.clone();
  for (int i=0; i<maxColors; i++){
      ranked_colors[i]=i;
  }

  boolean swap_made= true;
  while (swap_made==true){
  for (int i=0; i<maxColors-1; i++){
      if(color_areas_ranked[i]<color_areas_ranked[i+1]){
         
         float temp_float=color_areas_ranked[i];
         color_areas_ranked[i]=color_areas_ranked[i+1];
         color_areas_ranked[i+1]=temp_float; 
         
         int temp_int=ranked_colors[i];
         ranked_colors[i]=ranked_colors[i+1];
         ranked_colors[i+1]=temp_int;
         
         swap_made=true;
         
      }else{
         swap_made=false;
      }
  } 
 }  
}


//////////////////////
// Audio Functions
//////////////////////
 /*void playColorSoundMultiple(){
 for (int i=0; i<maxColors; i++){
   
   track_idx=ranked_colors[i];
   track_volume=10*log(color_areas_ranked[i]/color_areas_ranked[0]); 
   
   if(track_idx==0 &&
      sounds[track_idx].isPlaying()==false &&
      color_areas_ranked[track_idx]>0.1*color_areas_ranked[0]){
        
          sounds[track_idx].loop();
          sounds[track_idx].setGain(track_volume);
          
   }else if(track_idx>0 &&
            sounds[track_idx].isPlaying()==false &&
            color_areas_ranked[track_idx]>0.1*color_areas_ranked[0]){
        
      // start a new track in sync with the previous track
          skip_amount=sounds[track_idx-1].position();
          sounds[track_idx].skip(skip_amount);      
          sounds[track_idx].loop();
          sounds[track_idx].setGain(track_volume);
      
   }else if(color_areas_ranked[track_idx]>0.1*color_areas_ranked[0] &&
            sounds[track_idx].isPlaying()==true){
      sounds[track_idx].setGain(track_volume);
   }
 }
 }
 */
 
 void playColorSound(){
 for (int i=0; i<maxColors; i++){
   
   sound_idx=ranked_colors[i];
   track_idx=0;
   
   if(i==0 && 
      color_areas[sound_idx]>minColorArea){
 
     track_volume=0.0; //gain in decibels
     if(sounds[sound_idx][track_idx].isPlaying()==false){
          
            sounds[sound_idx][track_idx].loop();
            sounds[sound_idx][track_idx].setGain(track_volume);
            
     }else if(sounds[sound_idx][track_idx].isPlaying()==true){
                
        sounds[sound_idx][track_idx].setGain(track_volume);
     }
     
   }
   else{
     track_volume=-60.0;//gain in decibels
     if(sounds[sound_idx][track_idx].isPlaying()==true){                
        sounds[sound_idx][track_idx].setGain(track_volume);
     }
   }
   
   
   
 }
 }

//////////////////////
// Keyboard / Mouse
//////////////////////

void mousePressed() {
    
  if (colorToChange > -1) {
    
    color c = get(mouseX, mouseY);
    println("r: " + red(c) + " g: " + green(c) + " b: " + blue(c));
   
    int hue = int(map(hue(c), 0, 255, 0, 180));
    
    colors[colorToChange-1] = c;
    hues[colorToChange-1] = hue;
    
    
    println("color index " + (colorToChange-1) + ", value: " + hue);
  }
}

void keyPressed() {
  
  if (key == '1') {
    colorToChange = 1;
    
  } else if (key == '2') {
    colorToChange = 2;
    
  } else if (key == '3') {
    colorToChange = 3;
    
  } else if (key == '4') {
    colorToChange = 4;
  }
}

void keyReleased() {
  colorToChange = -1; 
}