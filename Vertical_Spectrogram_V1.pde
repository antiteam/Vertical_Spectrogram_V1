//  --------------------------------------------------------------------------------------------------------------------  //
//  VERTICAL SPECTOGRAM ALGORITHM - Image Interpreter and Gcode Generator                                                 //
//  --------------------------------------------------------------------------------------------------------------------  //
//  Created by Doug Biehl (doug.biehl@gmail.com) - August 2014                                                            //
//  --------------------------------------------------------------------------------------------------------------------  //
//  Follows vertical paths at intervals down a picture                                                                    //
//  At each step, assesses how dark the average darkness is neighbors adjacent to the vertical path                       //
//  Draws a horizontal line whose thickness correlates to the average darnkess of neighbors                               //
//  Encodes path in gcode and renders/saves results as a .jpg                                                             //
//                                                                                                                        //
//  NOTES:                                                                                                                //
//  Images are not scaled and are intepreted at original size!  1 pixel of original image = 1 drawbot step                //
//  I recommend scaling your image to have it's maximum dimention fit the corresponding maximum travel of your drawbot    //
//  My drawbot uses custom defined gcodes;  You should edit the gcodes below to match yours                               //
//  --------------------------------------------------------------------------------------------------------------------  //


final String  photo_path = "pics\\mar.jpg";  // Picture path
final int half_width = 15;                   // Half the distance from one vertical path to the next
final int vert_steps_jump = 1;               // Number of pixels to move vertically each cycle;  Increasing may make marker last longer

int h_offset = 0;                            // Horizontal offset for centering
int v_offset = 0;                            // Vertical offset for centering
PImage img_orig;
PrintWriter output_file;
int hjump = half_width * 2 + 1;              // Distance from one vertical to next (includes width of vertical itself)
int pen_state_up = 1;                        // Keeps track of whether the pen is up or down
int step_width;

void setup() {

  // Load source image
  img_orig = loadImage(sketchPath("") + photo_path); 
  img_orig.loadPixels();

  // Setup rendering space  
  size(img_orig.width, img_orig.height, P2D);   // Depending on image size this is likely not entirely viewable on-screen, which is why it's saved as a .jpg
  noSmooth();
  colorMode(HSB, 360, 100, 100, 100);
  background(0, 0, 100);  
  frameRate(120);
  
  // Prepare gcode output file
  output_file = createWriter("gcode.txt");

  // Calculates horizontal and vertial offset to center the image;  Can be adjsuted to move image up/down as needed
  h_offset = -1 * round(img_orig.width) / 2;
  v_offset = -1 * round(img_orig.height) / 2; 
}

void draw() {

  int x_loc, y_loc;
  
  // For each vertical path travelled to process the image...
  for (int jump_step = hjump; jump_step < img_orig.width - hjump/2; jump_step = jump_step + hjump) {
    pen_up(1);
    move_to(jump_step + h_offset, 0 + v_offset);
    
    // For each pixel along a vertical path travelled...
    for (int vert_steps = 1; vert_steps < img_orig.height; vert_steps = vert_steps + vert_steps_jump) {
      x_loc = jump_step;
      y_loc = vert_steps;

      // Assesses how dark the pixes horizontally adjacent to the current location are;  Correlates the width of the markign here with the darkness
      step_width = assess_darkness(x_loc, y_loc);

      // If there is some amount of darkess measured, steps forward, then moves the pen back and forth the appropriate amount
      if (step_width > 0) {
        move_to(x_loc + h_offset, y_loc + v_offset);

        if (pen_state_up == 1) { pen_up(0); }
        
        move_to(x_loc + h_offset + step_width , y_loc + v_offset);
        move_to(x_loc + h_offset              , y_loc + v_offset);
        move_to(x_loc + h_offset - step_width , y_loc + v_offset);
        move_to(x_loc + h_offset              , y_loc + v_offset);
        
        // This bit renders the horizontal line segment on the rendering space
        line(x_loc + step_width, y_loc, x_loc - step_width, y_loc);
      }

      // If there is no darkess measured, ensures the pen is up then steps forward
      if (step_width <= 0) {
        if (pen_state_up == 0) { pen_up(1); }          // Raising and lowering the gondola repeatedly may not be healthy for the servo
        //pen_up(0);                                   // Comment out line above and in this one and the one below to have each line be pen-down only;  Results in parallel vertical lines with horizontal offsets
        
        //move_to(x_loc + h_offset, y_loc + v_offset); // This one comes in if you want pen-down all the time (results in parallel vertical lines)
        
       // line(x_loc, y_loc, x_loc + 1, y_loc);        // If you choose to keep the pen down per the comments above, uncommenting this will render the vertical lines
      }
      
    }
  }
  
  pen_up(1);
  
  // Prepares and closes the gcode file;  Saves the rendered image
  output_file.flush();
  output_file.close();
  saveFrame("img_out.jpg");
  println("Done");
  noLoop();

}

int assess_darkness(int x_in, int y_in) {
  // Looks left and right at half_with's worth of pixels each direction and evaluates the average darkness 
  
  int oneD_loc;
  float redness = 0;
    
  for (int j = -1 * half_width; j <= half_width; j++) {
    oneD_loc = x_in + y_in*img_orig.width + j;
    redness += red (img_orig.pixels[oneD_loc]);
  }
  
  redness = 256 - (redness / hjump);

  return round( (redness / 256) * half_width );
  
}

void pen_up(int toggle) {
  // Lifts/lowers the pen in the gcode;  I've defined non-standard gcodes in my interpreter - you'll need to replace with yours (usually starts with "G1")

  if (toggle == 1) {
    output_file.println("G98");
    pen_state_up = 1;
  }

  if (toggle == 0) {
    output_file.println("G99");
    pen_state_up = 0;
  }
}

void move_to(int x_spot, int y_spot) {
  // Codes a movement in the gcode;  I've defined non-standard gcodes in my interpreter - you'll need to replace with yours (usually starts with "G1")

  String next_step = "G9 X" + nf(x_spot,0) + " Y" + nf(y_spot,0);
  output_file.println(next_step);  
}
