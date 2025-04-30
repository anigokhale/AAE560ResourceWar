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

  CellType getCellType(int num_neighbors, int[] neighbor_nationality_nums) {
    if (neighbor_nationality_nums[this.nationality + 1] == num_neighbors) return CellType.INTERIOR;
    else return CellType.BORDER;
  }

  int[] getNationalityNums(int[] neighbor_nats) {
    int[] nationality_nums = new int[p + 1];
    for (int l = 0; l < neighbor_nats.length; l++) {
      nationality_nums[neighbor_nats[l] + 1]++;
    }
    return nationality_nums;
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
      int num_neighbors = neighbor_nats.length;
      //Calculate how many of each nationality are present in neighbor set, also calculate the richest one that is not of own nationality

      int[] nationality_nums = getNationalityNums(neighbor_nats);

      atn += nationality_nums[this.nationality + 1];

      CellType type = getCellType(num_neighbors, nationality_nums);

      switch (type) {
      case BORDER:
        float[] contestants = new float[p];
        float total_score = 0;
        for (int l = 0; l < p; l++) {
          contestants[l] = nationality_nums[l + 1]*max(0, pow(8 - nations.get(l).A_bar, -1.0)*nations.get(l).getDisposableResources());
          total_score += contestants[l];
        }
        if (!reinforced[c[0]][c[1]] && total_score > 0) {
          if (this.R >= q*reinforcement_factor)
            action_options.add(new Reinforce(this, c, nationality_nums[this.nationality + 1], contestants[this.nationality]/total_score));
          action_options.add(new Null(this, c, nationality_nums[this.nationality + 1], contestants[this.nationality]/total_score));
        }
        for (int i = 0; i < num_neighbors; i++) {
          int[] border_cell_neighbor_nats = getNeighborNationalities(neighbors.get(i));
          int[] border_cell_neighbor_nationality_nums = getNationalityNums(border_cell_neighbor_nats);
          if (neighbor_nats[i] == -1) {
            //THIS BORDER CELL's NEIGHBOR IS UNCONTROLLED
            if (border_cell_neighbor_nationality_nums[0] + border_cell_neighbor_nationality_nums[this.nationality + 1] == border_cell_neighbor_nats.length) {
              //THIS NEIGHBOR IS UNCONTROLLED and UNCONTESTED - OPTION TO COLONIZE THIS NEIGHBOR
              action_options.add(new Colonize(this, neighbors.get(i), border_cell_neighbor_nationality_nums[this.nationality + 1]));
            } else if (this.getDisposableResources() > 0) {
              //THIS NEIGHBOR IS UNCONTROLLED AND CONTESTED
              contestants = new float[p];
              total_score = 0;
              for (int l = 0; l < p; l++) {
                contestants[l] = border_cell_neighbor_nationality_nums[l + 1]*max(0, pow(8 - nations.get(l).A_bar, -1.0)*nations.get(l).getDisposableResources());
                total_score += contestants[l];
              }
              if (total_score > 0 && this.R >= contest_effort) {
                //OPTION TO CONTEST NEIGHBOR
                action_options.add(new Contest(this, neighbors.get(i), border_cell_neighbor_nationality_nums[this.nationality + 1], contestants[this.nationality]/total_score));
              }
            }
          } else if (neighbor_nats[i] != this.nationality) {
            //THIS NEIGHBOR IS CONTROLLED
            contestants = new float[p];
            total_score = 0;
            for (int l = 0; l < p; l++) {
              contestants[l] = border_cell_neighbor_nationality_nums[l + 1]*max(0, pow(8 - nations.get(l).A_bar, -1.0)*nations.get(l).getDisposableResources());
              total_score += contestants[l];
            }
            if (total_score > 0 && this.R >= contest_effort) {
              float P;
              if (reinforced[neighbors.get(i)[0]][neighbors.get(i)[1]]) P = (1 - reinforcement_advantage)*contestants[this.nationality]/total_score;
              else P = contestants[this.nationality]/total_score;
              action_options.add(new Contest(this, neighbors.get(i), border_cell_neighbor_nationality_nums[this.nationality + 1], P));
            }
          }
        }
        break;

      default:
        break;
      }

      if (this.territory.size() > 1) action_options.add(new Abandon(this, c, nationality_nums[this.nationality + 1]));
    }

    this.total_allied_neighbors = atn;
    this.A_bar = this.total_allied_neighbors / (float)this.territory.size();

    if (action_options.size() > 0) {
      Collections.sort(action_options);

      for (int i = 0; i < min(num_actions, action_options.size()); i++) {
        Action best_action = action_options.get(i);
        //print(this.nationality, best_action.getClass().getName().substring(18), "(", best_action.cell[0], ", ", best_action.cell[1], ")", best_action.delta_F, "\t|\t");

        if (best_action instanceof Colonize) {
          this.addToTerritory(best_action.cell);
        } else if (best_action instanceof Contest) {
          if (!contains(contested_list, best_action.cell)) contested_list.add(best_action.cell);
          contested_cells[best_action.cell[0]][best_action.cell[1]].add(this);
          this.R -= contest_effort;
        } else if (best_action instanceof Abandon) {
          this.removeFromTerritory(best_action.cell);
        } else if (best_action instanceof Reinforce) {
          new_reinforced[best_action.cell[0]][best_action.cell[1]] = true;
          this.R -= q*reinforcement_factor;
        } else {
          //println("NULL CHOSEN");
        }
        last_actions[this.nationality].add(best_action);
      }
    } else {
      //println(this.nationality, ": NO OPTIONS");
      last_actions[this.nationality].add(new Null(this, null, 0, 0));
      //print(this.nationality, "Null", "\t|\t");
    }
    if (last_actions[this.nationality].size() > num_last_actions_to_record) {
      last_actions[this.nationality].remove(0);
    }
  }

  void addToTerritory(int[] c) {
    new_nationalities[c[0]][c[1]] = this.nationality;
    new_reinforced[c[0]][c[1]] = false;
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
    new_reinforced[c[0]][c[1]] = false;
  }

  float getDisposableResources() {
    return this.R - q*this.territory.size();
  }

  float getNationFitness() {
    return k_S*((float)this.territory.size())/((float)n*m) + k_R*this.R/total_resources + k_A_bar*this.A_bar/8.0;
  }
}

class Null extends Action {
  Null(Nation N_i, int[] c, int A_C_j, float P_i) {
    super(N_i, c);
    if (c != null) {
      float delta_S = P_i - 1;
      float delta_sum_S_j = 0;
      float delta_R = -resources[c[0]][c[1]]*(1 - P_i);
      float delta_sum_R_j = 0;
      float delta_sum_A = -2*A_C_j*(1 - P_i);

      this.delta_F = N_i.k_S*(delta_S*total_controlled_territory - N_i.territory.size()*delta_sum_S_j)/(total_controlled_territory*(total_controlled_territory + delta_sum_S_j))
        + N_i.k_R*(delta_R*total_controlled_resources - N_i.R*delta_sum_R_j)/(total_controlled_resources*(total_controlled_resources + delta_sum_R_j))
        + N_i.k_A_bar*(N_i.territory.size()*delta_sum_A - delta_S*N_i.total_allied_neighbors)/(8*N_i.territory.size()*(N_i.territory.size() + delta_S));
    }
  }
}

class Contest extends Action {
  Contest(Nation N_i, int[] c, int A_C_j, float P_i) {
    super(N_i, c);
    if (nationalities[c[0]][c[1]] == -1) {
      float delta_S = P_i;
      float delta_sum_S_j = 1;
      float delta_R = resources[c[0]][c[1]]*P_i - contest_effort;
      float delta_sum_R_j = resources[c[0]][c[1]] - contest_effort;
      float delta_sum_A = 2*A_C_j*P_i;

      this.delta_F = N_i.k_S*(delta_S*total_controlled_territory - N_i.territory.size()*delta_sum_S_j)/(total_controlled_territory*(total_controlled_territory + delta_sum_S_j))
        + N_i.k_R*(delta_R*total_controlled_resources - N_i.R*delta_sum_R_j)/(total_controlled_resources*(total_controlled_resources + delta_sum_R_j))
        + N_i.k_A_bar*(N_i.territory.size()*delta_sum_A - delta_S*N_i.total_allied_neighbors)/(8*N_i.territory.size()*(N_i.territory.size() + delta_S));
    } else {
      float delta_S = P_i;
      float delta_sum_S_j = 0;
      float delta_R = resources[c[0]][c[1]]*P_i - contest_effort;
      float delta_sum_R_j = -contest_effort;
      float delta_sum_A = 2*A_C_j*P_i;

      this.delta_F = N_i.k_S*(delta_S*total_controlled_territory - N_i.territory.size()*delta_sum_S_j)/(total_controlled_territory*(total_controlled_territory + delta_sum_S_j))
        + N_i.k_R*(delta_R*total_controlled_resources - N_i.R*delta_sum_R_j)/(total_controlled_resources*(total_controlled_resources + delta_sum_R_j))
        + N_i.k_A_bar*(N_i.territory.size()*delta_sum_A - delta_S*N_i.total_allied_neighbors)/(8*N_i.territory.size()*(N_i.territory.size() + delta_S));
    }
  }
}

class Abandon extends Action {
  Abandon(Nation N_i, int[] c, int A_C_j) {
    super(N_i, c);
    float delta_S = -1;
    float delta_sum_S_j = -1;
    float delta_R = -resources[c[0]][c[1]];
    float delta_sum_R_j = -resources[c[0]][c[1]];
    float delta_sum_A = -2*A_C_j;

    this.delta_F = N_i.k_S*(delta_S*total_controlled_territory - N_i.territory.size()*delta_sum_S_j)/(total_controlled_territory*(total_controlled_territory + delta_sum_S_j))
      + N_i.k_R*(delta_R*total_controlled_resources - N_i.R*delta_sum_R_j)/(total_controlled_resources*(total_controlled_resources + delta_sum_R_j))
      + N_i.k_A_bar*(N_i.territory.size()*delta_sum_A - delta_S*N_i.total_allied_neighbors)/(8*N_i.territory.size()*(N_i.territory.size() + delta_S));
  }
}

class Colonize extends Action {
  Colonize(Nation N_i, int[] c, int A_C_j) {
    super(N_i, c);
    float delta_S = 1;
    float delta_sum_S_j = 1;
    float delta_R = resources[c[0]][c[1]];
    float delta_sum_R_j = resources[c[0]][c[1]];
    float delta_sum_A = 2*A_C_j;

    this.delta_F = N_i.k_S*(delta_S*total_controlled_territory - N_i.territory.size()*delta_sum_S_j)/(total_controlled_territory*(total_controlled_territory + delta_sum_S_j))
      + N_i.k_R*(delta_R*total_controlled_resources - N_i.R*delta_sum_R_j)/(total_controlled_resources*(total_controlled_resources + delta_sum_R_j))
      + N_i.k_A_bar*(N_i.territory.size()*delta_sum_A - delta_S*N_i.total_allied_neighbors)/(8*N_i.territory.size()*(N_i.territory.size() + delta_S));
  }
}

class Reinforce extends Action {
  Reinforce(Nation N_i, int[] c, int A_C_j, float P_i) {
    super(N_i, c);
    float delta_S = -(1 - reinforcement_advantage - (1 - reinforcement_advantage)*P_i);
    float delta_sum_S_j = 0;
    float delta_R = -q*reinforcement_factor - resources[c[0]][c[1]]*(1 - reinforcement_advantage - (1 - reinforcement_advantage)*P_i);
    float delta_sum_R_j = -q*reinforcement_factor;
    float delta_sum_A = -2*A_C_j*(1 - reinforcement_advantage - (1 - reinforcement_advantage)*P_i);

    this.delta_F = N_i.k_S*(delta_S*total_controlled_territory - N_i.territory.size()*delta_sum_S_j)/(total_controlled_territory*(total_controlled_territory + delta_sum_S_j))
      + N_i.k_R*(delta_R*total_controlled_resources - N_i.R*delta_sum_R_j)/(total_controlled_resources*(total_controlled_resources + delta_sum_R_j))
      + N_i.k_A_bar*(N_i.territory.size()*delta_sum_A - delta_S*N_i.total_allied_neighbors)/(8*N_i.territory.size()*(N_i.territory.size() + delta_S));
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
    //if (Float.isNaN(this.delta_F)) println("NaN found in " + this.getClass().getName() + " made by Nation " + this.N_i.nationality);
    Action a = (Action)o;
    if (Float.isNaN(this.delta_F)) this.delta_F = -1e9;
    if (Float.isNaN(a.delta_F)) this.delta_F = -1e9;
    if (this.delta_F > a.delta_F) return -1;
    else if (this.delta_F < a.delta_F) return 1;
    else return 0;
  }

  boolean equals(Action a) {
    return (this.cell[0] == a.cell[0]) && (this.cell[1] == a.cell[1]);
  }
}

enum CellType {
  INTERIOR,
    BORDER
}
