void keyReleased() {
  if (key == ' ') {
    if (resource_mode.equals("DRAW")) resourceCalcs();
    if (!drawing_done) drawing_done = true;
    run = !run;
  }
}

void mouseDragged() {
  if (resource_mode.equals("DRAW") && !drawing_done) {
    int j = constrain(floor(map(mouseX, 0, width, 0, m)), 0, m - 1);
    int i = constrain(floor(map(mouseY, 0, height, 0, n)), 0, n - 1);
    
    float approach = 0.1;
    resources[i][j] = (1. - approach)*resources[i][j] + approach;
  }
}

void logData() {
  out.print(frameCount + "\t");
  for (int l = 0; l < p; l++) {
    out.print(nations.get(l).territory.size() + "\t");
  }
  out.println();
  out.flush();
}

void updateAll() {
  for (int[] c : contested_list) {
    ArrayList<Nation> contenders = new ArrayList<Nation>(0);
    for (Nation nat : contested_cells[c[0]][c[1]]) contenders.add(nat);
    contested_cells[c[0]][c[1]].clear();

    float[] scores = new float[p];
    float total_score = 0;

    for (int i = 0; i < contenders.size(); i++) {
      scores[contenders.get(i).nationality] += max(0, pow(8 - contenders.get(i).A_bar, -1)*contenders.get(i).getDisposableResources());
      total_score += scores[contenders.get(i).nationality];
    }
    //println(contenders);
    //println(total_score);

    if (total_score > 0) {
      float[] lb = new float[p];
      float[] ub = new float[p];
      lb[0] = 0;
      for (int i = 0; i < p - 1; i++) {
        ub[i] = lb[i] + scores[i]/total_score;
        lb[i + 1] = ub[i];
        //println("Nation " + i + " bounds are " + lb[i] + " and " + ub[i]);
      }
      ub[p - 1] = 1.0;
      //println("Nation " + (p - 1) + " bounds are " + lb[p - 1] + " and " + ub[p - 1]);
      float choose_winner = (float)(Math.random());
      int winner = -1;
      for (int i = 0; i < p; i++) {
        if ((choose_winner > lb[i]) && (choose_winner <= ub[i])) {
          winner = i;
          break;
        }
      }
      if (nationalities[c[0]][c[1]] == -1) { // Contested cell is uncontrolled
        nations.get(winner).addToTerritory(c);
      } else {
        int defender = nationalities[c[0]][c[1]];
        nations.get(defender).R -= fighting_effort;
        float guerilla_prob = (float)(Math.random());
        if ((winner != defender) && (guerilla_prob >= homefield_advantage)) {
          nations.get(defender).removeFromTerritory(c);
          nations.get(winner).addToTerritory(c);
        }
      }
    }
  }

  contested_list.clear();

  nationalities = copy2DArray(new_nationalities);
}

void drawGrid() {
  float cell_length = height/(float)n;
  float left = width/2 - m*cell_length/2;
  float right = width/2 + m*cell_length/2;

  background(200);
  stroke(0);
  strokeWeight(grid_weight);
  for (int j = 0; j < m + 1; j++) {
    line(left + j*cell_length, 0, left + j*cell_length, height);
  }
  for (int i = 0; i < n + 1; i++) {
    line(left, i*cell_length, right, i*cell_length);
  }
  for (int i = 0; i < n; i++) {
    for (int j = 0; j < m; j++) {
      fill(lerpColor(nation_colors[nationalities[i][j] + 1], color(0), resources[i][j]));
      rect(left + j*cell_length + grid_weight, i*cell_length + grid_weight, cell_length - 2*grid_weight, cell_length - 2*grid_weight);
    }
  }
  for (int l = 0; l < p; l++) {
    int i = capitols[l][0];
    int j = capitols[l][1];
    fill(capitol_colors[l]);
    rect(left + j*cell_length + grid_weight, i*cell_length + grid_weight, cell_length - 2*grid_weight, cell_length - 2*grid_weight);
    fill(0);
    textSize(cell_length);
    textAlign(LEFT, BOTTOM);
    text(max(0, nations.get(l).getNationFitness()), left + j*cell_length + grid_weight, i*cell_length + grid_weight);
    textAlign(RIGHT, TOP);
    text(l, left + j*cell_length + grid_weight, i*cell_length + grid_weight);
    textAlign(CENTER, TOP);
    textSize(cell_length );
    text("(" + nations.get(l).k_S + ", " + nations.get(l).k_R + ", " + nations.get(l).k_A_bar + ")", left + j*cell_length + grid_weight, (i + 1)*cell_length + grid_weight);
  }
}

void iterate() {
  for (Nation nat : nations) {
    if (nat.territory.size() > 0) nat.iterate();
  }
}

ArrayList<int[]> getNeighbors(int[] c) {
  ArrayList<int[]> neighbors = new ArrayList<int[]>(0);
  int i = c[0];
  int j = c[1];

  if (i == 0) {
    if (j == 0) {
      neighbors.add(new int[] {0, 1});
      neighbors.add(new int[] {1, 0});
      neighbors.add(new int[] {1, 1});
    } else if (j == m - 1) {
      neighbors.add(new int[] {0, m - 2});
      neighbors.add(new int[] {1, m - 2});
      neighbors.add(new int[] {1, m - 1});
    } else {
      neighbors.add(new int[] {0, j + 1});
      neighbors.add(new int[] {0, j - 1});
      neighbors.add(new int[] {1, j - 1});
      neighbors.add(new int[] {1, j});
      neighbors.add(new int[] {1, j + 1});
    }
  } else if (i == n - 1) {
    if (j == 0) {
      neighbors.add(new int[] {n - 1, 1});
      neighbors.add(new int[] {n - 2, 1});
      neighbors.add(new int[] {n - 2, 0});
    } else if (j == m - 1) {
      neighbors.add(new int[] {n - 2, m - 1});
      neighbors.add(new int[] {n - 2, m - 2});
      neighbors.add(new int[] {n - 1, m - 2});
    } else {
      neighbors.add(new int[] {n - 1, j + 1});
      neighbors.add(new int[] {n - 2, j + 1});
      neighbors.add(new int[] {n - 2, j});
      neighbors.add(new int[] {n - 2, j - 1});
      neighbors.add(new int[] {n - 1, j - 1});
    }
  } else {
    if (j == 0) {
      neighbors.add(new int[] {i, 1});
      neighbors.add(new int[] {i - 1, 1});
      neighbors.add(new int[] {i - 1, 0});
      neighbors.add(new int[] {i + 1, 0});
      neighbors.add(new int[] {i + 1, 1});
    } else if (j == m - 1) {
      neighbors.add(new int[] {i - 1, m - 1});
      neighbors.add(new int[] {i - 1, m - 2});
      neighbors.add(new int[] {i, m - 2});
      neighbors.add(new int[] {i + 1, m - 2});
      neighbors.add(new int[] {i + 1, m - 1});
    } else {
      neighbors.add(new int[] {i, j + 1});
      neighbors.add(new int[] {i - 1, j + 1});
      neighbors.add(new int[] {i - 1, j});
      neighbors.add(new int[] {i - 1, j - 1});
      neighbors.add(new int[] {i, j - 1});
      neighbors.add(new int[] {i + 1, j - 1});
      neighbors.add(new int[] {i + 1, j});
      neighbors.add(new int[] {i + 1, j + 1});
    }
  }

  return neighbors;
}

int[] getNeighborNationalities(int[] c) {
  int[] neighbors;
  int i = c[0];
  int j = c[1];

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

float[] getNeighborResources(int[] c) {
  float[] neighbors;
  int i = c[0];
  int j = c[1];

  if (i == 0) {
    if (j == 0) {
      neighbors = new float[3];
      neighbors[0] = resources[0][1];
      neighbors[1] = resources[1][0];
      neighbors[2] = resources[1][1];
    } else if (j == m - 1) {
      neighbors = new float[3];
      neighbors[0] = resources[0][m - 2];
      neighbors[1] = resources[1][m - 2];
      neighbors[2] = resources[1][m - 1];
    } else {
      neighbors = new float[5];
      neighbors[0] = resources[0][j + 1];
      neighbors[1] = resources[0][j - 1];
      neighbors[2] = resources[1][j - 1];
      neighbors[3] = resources[1][j];
      neighbors[4] = resources[1][j + 1];
    }
  } else if (i == n - 1) {
    if (j == 0) {
      neighbors = new float[3];
      neighbors[0] = resources[n - 1][1];
      neighbors[1] = resources[n - 2][1];
      neighbors[2] = resources[n - 2][0];
    } else if (j == m - 1) {
      neighbors = new float[3];
      neighbors[0] = resources[n - 2][m - 1];
      neighbors[1] = resources[n - 2][m - 2];
      neighbors[2] = resources[n - 1][m - 2];
    } else {
      neighbors = new float[5];
      neighbors[0] = resources[n - 1][j + 1];
      neighbors[1] = resources[n - 2][j + 1];
      neighbors[2] = resources[n - 2][j];
      neighbors[3] = resources[n - 2][j - 1];
      neighbors[4] = resources[n - 1][j - 1];
    }
  } else {
    if (j == 0) {
      neighbors = new float[5];
      neighbors[0] = resources[i][1];
      neighbors[1] = resources[i - 1][1];
      neighbors[2] = resources[i - 1][0];
      neighbors[3] = resources[i + 1][0];
      neighbors[4] = resources[i + 1][1];
    } else if (j == m - 1) {
      neighbors = new float[5];
      neighbors[0] = resources[i - 1][m - 1];
      neighbors[1] = resources[i - 1][m - 2];
      neighbors[2] = resources[i][m - 2];
      neighbors[3] = resources[i + 1][m - 2];
      neighbors[4] = resources[i + 1][m - 1];
    } else {
      neighbors = new float[8];
      neighbors[0] = resources[i][j + 1];
      neighbors[1] = resources[i - 1][j + 1];
      neighbors[2] = resources[i - 1][j];
      neighbors[3] = resources[i - 1][j - 1];
      neighbors[4] = resources[i][j - 1];
      neighbors[5] = resources[i + 1][j - 1];
      neighbors[6] = resources[i + 1][j];
      neighbors[7] = resources[i + 1][j + 1];
    }
  }

  return neighbors;
}
