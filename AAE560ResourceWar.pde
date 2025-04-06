import java.util.*;
import java.io.*;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import bridges.connect.Bridges;
import bridges.connect.DataSource;
import bridges.data_src_dependent.City;

int n = 9*5; //NUMBER OF GRID ROWS
int m = 16*5; //NUMBER OF GRID COLUMNS
int p = 4; // NUMBER OF CAPITOLS

float capitol_distancing = m/6.;

int[][] capitols;
color[] capitol_colors;
color[] nation_colors;

float resource_noise_scale = sqrt(15.0/((float)n*m));
float resource_noise_power = 1;
float total_resources = 0;

float q_quartile = 0.5;
float q;
float fighting_effort_factor = 0.01;
float fighting_effort;
float homefield_advantage = 0.5;

String resource_mode = "RANDOM";
float[][] resources;
float[] all_resources = new float[n*m];
int[][] nationalities, new_nationalities;
ArrayList<Nation> nations = new ArrayList<Nation>(0);
ArrayList<Nation>[][] contested_cells = new ArrayList[n][m];
ArrayList<int[]> contested_list = new ArrayList<int[]>(0);

float grid_weight = 0.05;
boolean draw_controls = false;
boolean run = false;
boolean log_data = false;
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
