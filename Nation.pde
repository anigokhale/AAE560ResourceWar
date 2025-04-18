class Nation {
  int nationality;
  float R;
  int[] capitol;
  ArrayList<int[]> territory;
  float A_bar = 1;
  float total_allied_neighbors = 1;
  float k_S;
  float k_R;
  float k_A_bar;

  Nation(int nat, float k_S, float k_R, float k_A) {
    this.nationality = nat;
    this.capitol = capitols[nationality];
    this.R = resources[this.capitol[0]][this.capitol[1]];
    this.territory = new ArrayList<int[]>(0);
    this.territory.add(this.capitol);
    this.k_S = k_S;
    this.k_R = k_R;
    this.k_A_bar = k_A;
  }

  void iterate() {
    this.R = max(0, this.R);
    float atn = 0;
    ArrayList<Action> action_options = new ArrayList<Action>(0);

    //For each cell in this nation's territory
    for (int[] c : this.territory) {
      //Find cell's neighbors and get their nationalities and resources
      ArrayList<int[]> neighbors = getNeighbors(c);
      int[] neighbor_nats = getNeighborNationalities(c);
      float[] neighbor_res = getNeighborResources(c);
      int num_neighbors = neighbor_nats.length;
      int richest_neighbor = -1;
      float richest = -1;

      //Calculate how many of each nationality are present in neighbor set, also calculate the richest one that is not of own nationality
      int[] nationality_nums = new int[p + 1];
      for (int l = 0; l < num_neighbors; l++) {
        nationality_nums[neighbor_nats[l] + 1]++;
        if ((neighbor_nats[l] != this.nationality) && (neighbor_res[l] > richest)) {
          richest_neighbor = l;
          richest = neighbor_res[l];
        }
      }
      atn += nationality_nums[this.nationality + 1];

      //Option found: ABANDON
      if (this.territory.size() > 1) action_options.add(new Abandon(this, c, nationality_nums[this.nationality + 1]));

      //If no unallied neighbor was found, do nothing
      if (richest_neighbor != -1) {
        //Get nationalities of richest neighbor's neighbors
        int[] richest_neighbor_neighbor_nats = getNeighborNationalities(neighbors.get(richest_neighbor));
        int richest_neighbor_num_neighbors = richest_neighbor_neighbor_nats.length;
        int[] richest_neighbor_neighbor_nationality_nums = new int[p + 1];
        for (int l = 0; l < richest_neighbor_num_neighbors; l++) {
          richest_neighbor_neighbor_nationality_nums[richest_neighbor_neighbor_nats[l] + 1]++;
        }

        if (nationality_nums[0] + nationality_nums[this.nationality + 1] == num_neighbors) { //If all neighbors are either allied or uncontrolled

          if (richest_neighbor_neighbor_nationality_nums[0] + richest_neighbor_neighbor_nationality_nums[this.nationality + 1] ==
            richest_neighbor_num_neighbors) { //If richest neighbor is uncontrolled AND uncontested (it has no unallied neighbors). Option found: COLONIZE
            action_options.add(new Colonize(this, neighbors.get(richest_neighbor), nationality_nums[this.nationality + 1]));
          } else { //Else, richest neighbor has at least 1 other nation as a neighbor and is therefore a no-man's land. Option found: CONTEST
            float[] contestants = new float[p];
            float total_score = 0;
            for (int l = 0; l < p; l++) {
              contestants[l] = richest_neighbor_neighbor_nationality_nums[l + 1]*max(0, pow(8 - nations.get(l).A_bar, -1)*nations.get(l).getDisposableResources());
              total_score += contestants[l];
            }
            if (this.getDisposableResources() > 0) {
              action_options.add(new Contest(this, neighbors.get(richest_neighbor), nationality_nums[this.nationality + 1], contestants[this.nationality]/total_score));
            }
          }
        } else { //Cell has at least one unallied neighbor
          //Only 2 options left. If richest neighbor is uncontrolled, this nation may contest it.
          //If it is controlled, this nation may contest and attack the other nation, but the probability is lower.
          float[] contestants = new float[p];
          float total_score = 0;
          for (int l = 0; l < p; l++) {
            contestants[l] = richest_neighbor_neighbor_nationality_nums[l + 1]*max(0, pow(8 - nations.get(l).A_bar, -1)*nations.get(l).getDisposableResources());
            total_score += contestants[l];
          }
          if (total_score > 0) {
            if (neighbor_nats[richest_neighbor] == -1) { //Cell has at least one unallied controlled neighbor BUT richest neighbor is uncontrolled. Option found: CONTEST
              action_options.add(new Contest(this, neighbors.get(richest_neighbor), nationality_nums[this.nationality + 1], contestants[this.nationality]/total_score));
            } else { //Cell has at least one allied neighbor AND richest neighbor is controlled. Option found: ATTACK
              action_options.add(new Contest(this, neighbors.get(richest_neighbor), nationality_nums[this.nationality + 1], (1.0 - homefield_advantage)*contestants[this.nationality]/total_score));
            }
          }
        }
      }
    }
    this.total_allied_neighbors = atn;
    this.A_bar = this.total_allied_neighbors / (float)this.territory.size();
    action_options.add(new Null(this, null));
    if (action_options.size() > 0) {
      Collections.sort(action_options);
      Action best_action = action_options.get(0);
        if (t > 1e3) println(this.nationality, best_action.getClass().getName());

      if (best_action instanceof Colonize) {
        this.addToTerritory(best_action.cell);
      } else if (best_action instanceof Contest) {
        if (!contains(contested_list, best_action.cell)) contested_list.add(best_action.cell);
        contested_cells[best_action.cell[0]][best_action.cell[1]].add(this);
        this.R -= fighting_effort;
      } else if (best_action instanceof Abandon) {
        //println(action_options.get(1).delta_F, resources[best_action.cell[0]][best_action.cell[1]], best_action.delta_F);
        this.removeFromTerritory(best_action.cell);
        //println("Nation " + this.nationality + " abandoned cell at (" + best_action.cell[0] + ", " + best_action.cell[1] + ")");
      } else {
        null_actions++;
        //println("Nation " + this.nationality + " chose to do nothing!");
      }
      last_actions[this.nationality].add(best_action);
      if (last_actions[this.nationality].size() > num_last_actions_to_record) {
        last_actions[this.nationality].remove(0);
      }
    }
  }

  void addToTerritory(int[] c) {
    new_nationalities[c[0]][c[1]] = this.nationality;
    this.territory.add(c);
    this.R += resources[c[0]][c[1]];
  }

  void removeFromTerritory(int[] c) {
    new_nationalities[c[0]][c[1]] = -1;
    int[] to_remove = null;
    for (int[] cell : this.territory) {
      if ((c[0] == cell[0]) && (c[1] == cell[1])) to_remove = cell;
    }
    this.territory.remove(to_remove);
    this.R -= resources[c[0]][c[1]];
  }

  float getDisposableResources() {
    return this.R - q*this.territory.size();
  }

  float getNationFitness() {
    return k_S*((float)this.territory.size())/((float)n*m) + k_R*this.R/total_resources + k_A_bar*this.A_bar/8.0;
  }
}

class Null extends Action {
  Null(Nation N_i, int[] c) {
    super(N_i, c);
    this.delta_F = 0;
  }
}

class Contest extends Action {
  Contest(Nation N_i, int[] c, int A_C_j, float P_i) {
    super(N_i, c);
    this.delta_F = N_i.k_S*P_i/((float)n*m) + N_i.k_R*(resources[this.cell[0]][this.cell[1]]*P_i - fighting_effort)/total_resources +
      N_i.k_A_bar*P_i*(-N_i.total_allied_neighbors + 2.0*A_C_j*N_i.territory.size())/(8.0*N_i.territory.size()*(N_i.territory.size() + P_i));
  }
}

class Abandon extends Action {
  Abandon(Nation N_i, int[] c, int A_C_j) {
    super(N_i, c);
    this.delta_F = -N_i.k_S/((float)n*m) - N_i.k_R*resources[this.cell[0]][this.cell[1]]/total_resources +
      N_i.k_A_bar*(N_i.total_allied_neighbors - 2.0*A_C_j*N_i.territory.size())/(8.0*N_i.territory.size()*(N_i.territory.size() - 1.0));
  }
}

class Colonize extends Action {
  Colonize(Nation N_i, int[] c, int A_C_j) {
    super(N_i, c);
    this.delta_F = N_i.k_S/((float)n*m) + N_i.k_R*resources[this.cell[0]][this.cell[1]]/total_resources +
      N_i.k_A_bar*(-N_i.total_allied_neighbors + 2.0*A_C_j*N_i.territory.size())/(8.0*N_i.territory.size()*(N_i.territory.size() + 1.0));
  }
}

class Action implements Comparable {
  int[] cell;
  float delta_F;
  Nation N_i;
  Action(Nation N_i, int[] c) {
    this.cell = c;
    this.N_i = N_i;
  }

  int compareTo(Object o) {
    if (Float.isNaN(this.delta_F)) println("NaN found in " + this.getClass().getName() + " made by Nation " + this.N_i.nationality);
    Action a = (Action)o;
    if (this.delta_F > a.delta_F) return -1;
    else if (this.delta_F < a.delta_F) return 1;
    else return 0;
  }

  boolean equals(Action a) {
    return (this.cell[0] == a.cell[0]) && (this.cell[1] == a.cell[1]);
  }
}
