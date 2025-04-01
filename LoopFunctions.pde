void keyReleased() {
  if (key == ' ') run = !run;
}

void logData() {
  out.print(frameCount + "\t");
  for (int l = 0; l < p + 1; l++) {
    out.print(nation_sizes[l] + "\t");
    out.print(nation_resources[l][0] + "\t");
  }
  out.println();
  out.flush();
}

void drawGrid() {
  float cell_length = height/(float)n;
  float left = width/2 - m*cell_length/2;
  float right = width/2 + m*cell_length/2;

  if (draw_nations) {
    float total_aligned_resources = 0;
    new_nation_sizes[0] = 0;
    new_nation_resources[0][0] = 0;
    for (int l = 0; l < p; l++) {
      nationalities[capitols[l][0]][capitols[l][1]] = l;
      new_nation_resources[l + 1][0] = 0;
      new_nation_sizes[l + 1] = 0;
      total_aligned_resources += nation_resources[l + 1][0];
    }

    if (run) {
      for (int i = 0; i < n; i++) {
        for (int j = 0; j < m; j++) {

          int current_nationality = nationalities[i][j];
          new_nation_sizes[current_nationality + 1]++;

          new_nation_resources[current_nationality + 1][0] += resources[i][j][0];

          int[] neighbor_nationalities = getNeighborNationalities(i, j);
          int num_neighbors = neighbor_nationalities.length;
          int[] neighbor_controls = getNeighborControl(i, j);
          float[] neighbor_resources = getNeighborResources(i, j, 0);

          int[] nationality_nums = new int[p + 1];
          int[] control_nums = new int[p + 1];
          float total_neighbor_resources = 0;
          for (int l = 0; l < num_neighbors; l++) {
            nationality_nums[neighbor_nationalities[l] + 1]++;
            control_nums[neighbor_nationalities[l] + 1] += neighbor_controls[l];
            total_neighbor_resources += neighbor_resources[l];
          }
          total_neighbor_resources /= num_neighbors;

          if ((current_nationality == -1) && (nationality_nums[0] != num_neighbors)) {
            noStroke();
            ArrayList<Contender> contenders = new ArrayList<Contender>(0);
            
            for (int l = 1; l < p + 1; l++) {
              float control_scaling = starting_control*num_neighbors;
              float control_score = control_nums[l]/control_scaling;
              float resource_scaling = total_aligned_resources;
              float resource_score = nation_resources[l][0]/resource_scaling;
              //println(l - 1, resource_score);
              if (nationality_nums[l] > 0) contenders.add(new Contender(l - 1, (control_score + resource_score)));
            }

            Collections.sort(contenders);
            switch ((int)(resources[i][j][0]/total_neighbor_resources)) {
              case (1):
              {
                if (Math.random() <= (1.0 + recruit_likeliness)/2.0) {
                  new_nationalities[i][j] = contenders.get(contenders.size() - 1).nationality;
                  new_control[i][j] = starting_control;
                }
              }
            default:
              {
                if (Math.random() <= recruit_likeliness) {
                  new_nationalities[i][j] = contenders.get(contenders.size() - 1).nationality;
                  new_control[i][j] = starting_control;
                }
              }
            }
          } else if (nationality_nums[0] == num_neighbors) {
            noStroke();
          } else if (nationality_nums[0] + nationality_nums[current_nationality + 1] == num_neighbors) {
            noStroke();
            new_control[i][j] = starting_control;
          } else if (nationality_nums[current_nationality + 1] == 0) {
            new_control[i][j] = ceil((float)control[i][j]/2.0);
          } else {
            ArrayList<Contender> aggressors = new ArrayList<Contender>(0);
            for (int l = 1; l < p + 1; l++) {
              float control_scaling = starting_control*num_neighbors;
              float control_score = control_nums[l]/control_scaling;
              float resource_scaling = total_aligned_resources;
              float resource_score = nation_resources[l][0]/resource_scaling;
              if (nationality_nums[l] > 0) aggressors.add(new Contender(l - 1, control_score*resource_score));
            }

            Collections.sort(aggressors);
            if (Math.random() <= defeat_likeliness) {
              new_nationalities[i][j] = aggressors.get(aggressors.size() - 1).nationality;
              new_control[i][j] = starting_control;
            }
          }

          new_control[i][j] = max(0, new_control[i][j] - 1);
          if ((control[i][j] == 0) && (new_control[i][j] == 0)) new_nationalities[i][j] = -1;

          fill(lerpColor(nation_colors[nationalities[i][j] + 1], color(0), resources[i][j][0]));
          rect(left + j*cell_length + grid_weight, i*cell_length + grid_weight, cell_length - 2*grid_weight, cell_length - 2*grid_weight);
          if (draw_controls) {
            textSize(max(cell_length/10, 1));
            textAlign(LEFT, TOP);
            fill(0);
            text("  " + control[i][j], left + j*cell_length + grid_weight, i*cell_length + grid_weight);
          }
        }
      }
    }
    nationalities = copy2DArray(new_nationalities);
    nation_resources = copy2DArray(new_nation_resources);
    nation_sizes = new_nation_sizes.clone();
    control = copy2DArray(new_control);

    for (int l = 0; l < p; l++) {
      int i = capitols[l][0];
      int j = capitols[l][1];
      fill(capitol_colors[l]);
      rect(left + j*cell_length + grid_weight, i*cell_length + grid_weight, cell_length - 2*grid_weight, cell_length - 2*grid_weight);
    }
  }

  if (draw_gridlines) {
    stroke(0);
    strokeWeight(grid_weight);
    for (int j = 0; j < m + 1; j++) {
      line(left + j*cell_length, 0, left + j*cell_length, height);
    }
    for (int i = 0; i < n + 1; i++) {
      line(left, i*cell_length, right, i*cell_length);
    }
  }
  
  if (log_data) logData();
}



int[] getNeighborNationalities(int i, int j) {
  int[] neighbors;

  if (i == 0) {
    if (j == 0) {
      neighbors = new int[3];
      neighbors[0] = nationalities[0][1];
      neighbors[1] = nationalities[1][0];
      neighbors[2] = nationalities[1][1];
    } else if (j == m - 1) {
      neighbors = new int[3];
      neighbors[0] = nationalities[0][m - 2];
      neighbors[1] = nationalities[1][m - 2];
      neighbors[2] = nationalities[1][m - 1];
    } else {
      neighbors = new int[5];
      neighbors[0] = nationalities[0][j + 1];
      neighbors[1] = nationalities[0][j - 1];
      neighbors[2] = nationalities[1][j - 1];
      neighbors[3] = nationalities[1][j];
      neighbors[4] = nationalities[1][j + 1];
    }
  } else if (i == n - 1) {
    if (j == 0) {
      neighbors = new int[3];
      neighbors[0] = nationalities[n - 1][1];
      neighbors[1] = nationalities[n - 2][1];
      neighbors[2] = nationalities[n - 2][0];
    } else if (j == m - 1) {
      neighbors = new int[3];
      neighbors[0] = nationalities[n - 2][m - 1];
      neighbors[1] = nationalities[n - 2][m - 2];
      neighbors[2] = nationalities[n - 1][m - 2];
    } else {
      neighbors = new int[5];
      neighbors[0] = nationalities[n - 1][j + 1];
      neighbors[1] = nationalities[n - 2][j + 1];
      neighbors[2] = nationalities[n - 2][j];
      neighbors[3] = nationalities[n - 2][j - 1];
      neighbors[4] = nationalities[n - 1][j - 1];
    }
  } else {
    if (j == 0) {
      neighbors = new int[5];
      neighbors[0] = nationalities[i][1];
      neighbors[1] = nationalities[i - 1][1];
      neighbors[2] = nationalities[i - 1][0];
      neighbors[3] = nationalities[i + 1][0];
      neighbors[4] = nationalities[i + 1][1];
    } else if (j == m - 1) {
      neighbors = new int[5];
      neighbors[0] = nationalities[i - 1][m - 1];
      neighbors[1] = nationalities[i - 1][m - 2];
      neighbors[2] = nationalities[i][m - 2];
      neighbors[3] = nationalities[i + 1][m - 2];
      neighbors[4] = nationalities[i + 1][m - 1];
    } else {
      neighbors = new int[8];
      neighbors[0] = nationalities[i][j + 1];
      neighbors[1] = nationalities[i - 1][j + 1];
      neighbors[2] = nationalities[i - 1][j];
      neighbors[3] = nationalities[i - 1][j - 1];
      neighbors[4] = nationalities[i][j - 1];
      neighbors[5] = nationalities[i + 1][j - 1];
      neighbors[6] = nationalities[i + 1][j];
      neighbors[7] = nationalities[i + 1][j + 1];
    }
  }

  return neighbors;
}

int[] getNeighborControl(int i, int j) {
  int[] neighbors;

  if (i == 0) {
    if (j == 0) {
      neighbors = new int[3];
      neighbors[0] = control[0][1];
      neighbors[1] = control[1][0];
      neighbors[2] = control[1][1];
    } else if (j == m - 1) {
      neighbors = new int[3];
      neighbors[0] = control[0][m - 2];
      neighbors[1] = control[1][m - 2];
      neighbors[2] = control[1][m - 1];
    } else {
      neighbors = new int[5];
      neighbors[0] = control[0][j + 1];
      neighbors[1] = control[0][j - 1];
      neighbors[2] = control[1][j - 1];
      neighbors[3] = control[1][j];
      neighbors[4] = control[1][j + 1];
    }
  } else if (i == n - 1) {
    if (j == 0) {
      neighbors = new int[3];
      neighbors[0] = control[n - 1][1];
      neighbors[1] = control[n - 2][1];
      neighbors[2] = control[n - 2][0];
    } else if (j == m - 1) {
      neighbors = new int[3];
      neighbors[0] = control[n - 2][m - 1];
      neighbors[1] = control[n - 2][m - 2];
      neighbors[2] = control[n - 1][m - 2];
    } else {
      neighbors = new int[5];
      neighbors[0] = control[n - 1][j + 1];
      neighbors[1] = control[n - 2][j + 1];
      neighbors[2] = control[n - 2][j];
      neighbors[3] = control[n - 2][j - 1];
      neighbors[4] = control[n - 1][j - 1];
    }
  } else {
    if (j == 0) {
      neighbors = new int[5];
      neighbors[0] = control[i][1];
      neighbors[1] = control[i - 1][1];
      neighbors[2] = control[i - 1][0];
      neighbors[3] = control[i + 1][0];
      neighbors[4] = control[i + 1][1];
    } else if (j == m - 1) {
      neighbors = new int[5];
      neighbors[0] = control[i - 1][m - 1];
      neighbors[1] = control[i - 1][m - 2];
      neighbors[2] = control[i][m - 2];
      neighbors[3] = control[i + 1][m - 2];
      neighbors[4] = control[i + 1][m - 1];
    } else {
      neighbors = new int[8];
      neighbors[0] = control[i][j + 1];
      neighbors[1] = control[i - 1][j + 1];
      neighbors[2] = control[i - 1][j];
      neighbors[3] = control[i - 1][j - 1];
      neighbors[4] = control[i][j - 1];
      neighbors[5] = control[i + 1][j - 1];
      neighbors[6] = control[i + 1][j];
      neighbors[7] = control[i + 1][j + 1];
    }
  }

  return neighbors;
}

float[] getNeighborResources(int i, int j, int l) {
  float[] neighbors;

  if (i == 0) {
    if (j == 0) {
      neighbors = new float[3];
      neighbors[0] = resources[0][1][l];
      neighbors[1] = resources[1][0][l];
      neighbors[2] = resources[1][1][l];
    } else if (j == m - 1) {
      neighbors = new float[3];
      neighbors[0] = resources[0][m - 2][l];
      neighbors[1] = resources[1][m - 2][l];
      neighbors[2] = resources[1][m - 1][l];
    } else {
      neighbors = new float[5];
      neighbors[0] = resources[0][j + 1][l];
      neighbors[1] = resources[0][j - 1][l];
      neighbors[2] = resources[1][j - 1][l];
      neighbors[3] = resources[1][j][l];
      neighbors[4] = resources[1][j + 1][l];
    }
  } else if (i == n - 1) {
    if (j == 0) {
      neighbors = new float[3];
      neighbors[0] = resources[n - 1][1][l];
      neighbors[1] = resources[n - 2][1][l];
      neighbors[2] = resources[n - 2][0][l];
    } else if (j == m - 1) {
      neighbors = new float[3];
      neighbors[0] = resources[n - 2][m - 1][l];
      neighbors[1] = resources[n - 2][m - 2][l];
      neighbors[2] = resources[n - 1][m - 2][l];
    } else {
      neighbors = new float[5];
      neighbors[0] = resources[n - 1][j + 1][l];
      neighbors[1] = resources[n - 2][j + 1][l];
      neighbors[2] = resources[n - 2][j][l];
      neighbors[3] = resources[n - 2][j - 1][l];
      neighbors[4] = resources[n - 1][j - 1][l];
    }
  } else {
    if (j == 0) {
      neighbors = new float[5];
      neighbors[0] = resources[i][1][l];
      neighbors[1] = resources[i - 1][1][l];
      neighbors[2] = resources[i - 1][0][l];
      neighbors[3] = resources[i + 1][0][l];
      neighbors[4] = resources[i + 1][1][l];
    } else if (j == m - 1) {
      neighbors = new float[5];
      neighbors[0] = resources[i - 1][m - 1][l];
      neighbors[1] = resources[i - 1][m - 2][l];
      neighbors[2] = resources[i][m - 2][l];
      neighbors[3] = resources[i + 1][m - 2][l];
      neighbors[4] = resources[i + 1][m - 1][l];
    } else {
      neighbors = new float[8];
      neighbors[0] = resources[i][j + 1][l];
      neighbors[1] = resources[i - 1][j + 1][l];
      neighbors[2] = resources[i - 1][j][l];
      neighbors[3] = resources[i - 1][j - 1][l];
      neighbors[4] = resources[i][j - 1][l];
      neighbors[5] = resources[i + 1][j - 1][l];
      neighbors[6] = resources[i + 1][j][l];
      neighbors[7] = resources[i + 1][j + 1][l];
    }
  }

  return neighbors;
}
