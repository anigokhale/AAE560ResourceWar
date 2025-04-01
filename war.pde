import java.util.*;
import java.io.*;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import bridges.connect.Bridges;
import bridges.connect.DataSource;
import bridges.data_src_dependent.City;

int n = 9*30; //NUMBER OF GRID ROWS
int m = 16*30; //NUMBER OF GRID COLUMNS
int k = 1; //NUMBER OF RESOURCES
int p = 10; // NUMBER OF CAPITOLS

float recruit_likeliness = 5e-4;
float defeat_likeliness = 5e-2;

int starting_control = 100;

int[][] capitols;
color[] capitol_colors;
color[] nation_colors;

float[] resource_noise_scales = {sqrt(10000.0/((float)n*m))};
float resource_noise_power = 2;
float total_resources = 0;

String resource_mode = "MAP";
float[][][] resources;
int[][] nationalities, new_nationalities;
int[][] control, new_control;
float[][] nation_resources, new_nation_resources;
float[] nation_sizes, new_nation_sizes;

float grid_weight = 0.05;
boolean draw_gridlines = false;
boolean draw_nations = true;
boolean draw_controls = false;
boolean run = false;
boolean log_data = false;
PrintWriter out;
File out_file;

void setup() {
  fullScreen();
  initializeDataLogging();
  resources = generateResources();
  initializeCapitols();
  initializeNationalities();
  initializeColors();
  drawGrid();
}

void draw() {
  if (run) {
    background(200);
    drawGrid();
    //delay(1000);
  }
}
