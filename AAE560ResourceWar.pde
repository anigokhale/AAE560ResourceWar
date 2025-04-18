import java.util.*;
import java.io.*;
import java.text.ParseException;
import java.text.SimpleDateFormat;

int n = 9*2; //NUMBER OF GRID ROWS
int m = 16*2; //NUMBER OF GRID COLUMNS
int p = 3; // NUMBER OF CAPITOLS

float capitol_distancing = m/5.;

int[][] capitols;
color[] capitol_colors;
color[] nation_colors;

float resource_noise_scale = sqrt(100.0/((float)n*m));
float resource_noise_power = 2;
float total_resources = 0;

float q_quartile = 0.5;
float q;
float fighting_effort_factor = 0.;
float fighting_effort;
float homefield_advantage = 0.5;

String resource_mode = "RANDOM";
float[][] resources;
float[] all_resources = new float[n*m];
int[][] nationalities, new_nationalities;
ArrayList<Nation> nations = new ArrayList<Nation>(0);
ArrayList<Nation>[][] contested_cells = new ArrayList[n][m];
ArrayList<int[]> contested_list = new ArrayList<int[]>(0);
int null_actions = 0;
ArrayList<Action>[] last_actions = new ArrayList[p];
int num_last_actions_to_record = 10;
boolean nash = false;
int t = 0;

float grid_weight = 0.05;
boolean draw_controls = false;
boolean run = false;
boolean log_data = true;
boolean drawing_done = false;
PrintWriter out;
File out_file;

void setup() {
  fullScreen();
  initializeDataLogging();
  resources = generateResources();
  resourceCalcs();
  initializeCapitols();
  initializeNationalities();
  initializeColors();
  drawGrid();
}

void draw() {
  if (drawing_done && run) {
    iterate();
    updateAll();
  }
  drawGrid();
  //delay(1000);
  //println(nations.get(0).A);
}
