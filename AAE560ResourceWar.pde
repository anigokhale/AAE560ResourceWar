import java.util.*;
import java.io.*;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import javax.swing.*;
import java.awt.*;

//SETUP PARAMETERS
int n = 9*2; //NUMBER OF GRID ROWS
int m = 16*2; //NUMBER OF GRID COLUMNS
int p = 2; // NUMBER OF CAPITOLS
float capitol_distancing = m/2.; //MINIMUM DISTANCE BETWEEN CAPITOL SPAWNS
float resource_noise_scale = sqrt(100.0/((float)n*m)); //AFFECTS GRANULARITY OF RESOURCE DISTRIBUTION
float resource_noise_power = 2; //AFFECTS RESOURCE DISTRIBUTION
float q_quartile = 0.5; //AFFECTS NATIONS' ABILITY TO TAKE RESOURCE-CONSUMING ACTIONS
float contest_effort_factor = 1; //PROPORTION OF q THAT CONTESTING REQUIRES
float reinforcement_advantage = 0.95; //CONTEST ADVANTAGE GIVEN BY REINFORCEMENT
float reinforcement_factor = 0.25; //PROPORTION OF q THAT REINFORCEMENT REQUIRES
String resource_mode = "RANDOM"; //METHOD OF RESOURCE SPAWNING
int num_last_actions_to_record = 50; //NUMBER OF ACTIONS TO MEASURE TO DETERMINE NASH EQUILIBRIUM
int num_actions = 1; //NUMBER OF ACTIONS A NATION CAN TAKE IN A SINGLE TIMESTEP
float grid_weight = 0.05; //WEIGHT OF GRID LINES
boolean log_data = false; //WHETHER TO LOG SIM DATA TO FILE OR NOT
int log_period = 10; //FREQUENCY AT WHICH TO LOG DATA

int[][] capitols;
color[] capitol_colors;
color[] nation_colors;
float total_resources = 0;
int total_controlled_territory = p;
float total_controlled_resources = 0;

float q;
float contest_effort;
float[][] resources;
float[] all_resources = new float[n*m];
int[][] nationalities, new_nationalities;
boolean[][] reinforced, new_reinforced;
PGraphics img;
ArrayList<Nation> nations = new ArrayList<Nation>(0);
ArrayList<Nation>[][] contested_cells = new ArrayList[n][m];
ArrayList<int[]> contested_list = new ArrayList<int[]>(0);
ArrayList<Action>[] last_actions = new ArrayList[p];

boolean nash = false;
int t = 0;
float img_x, img_y, img_w, img_h;
int aspect_width, aspect_height;

boolean run = false;
boolean drawing_done = false;
PrintWriter out;
File out_file;

void setup() {
  //setupMenu();
  fullScreen();
  img = createGraphics(width, height);
  resources = generateResources();
  resourceCalcs();
  initializeNationalities();
  initializeCapitols();
  initializeColors();
  initializeDataLogging();
  drawGrid();
  //aspect_width = ((int)width)/gcd((int)width, (int)height);
  //aspect_height = ((int)height)/gcd((int)width, (int)height);
  img_x = width/2;
  img_y = height/2;
  img_w = width;
  img_h = height;
}

void draw() {
  if (drawing_done && run) {
    iterate();
  }
  drawGrid();
  //delay(500);
  //println(nations.get(0).A);
}
