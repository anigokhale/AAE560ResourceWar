void setupMenu() {
  JFrame setup_frame;
  JLabel header_label;
  setup_frame = new JFrame("SIMULATION SETUP");
  setup_frame.setSize(640, 480);
  setup_frame.setLayout(new GridLayout(1, 3));


  setup_frame.setVisible(true);
}

void initializeDataLogging() {
  if (log_data) {
    SimpleDateFormat ft = new SimpleDateFormat("hh_mm_ss_dd_MM_yyyy");
    String filename = ".\\output\\WAR_SIMULATION_" + ft.format(new Date()) + ".txt";
    out = createWriter(filename);
    out.println("SIMULATION PARAMETERS:");
    out.println("n = " + n + "\nm = " + m + "\np = " + p + "\nresource_noise_scale = " + resource_noise_scale + "\nq = " + q +
      "\nE_C = " + contest_effort + "\nE_R = " + q*reinforcement_factor + "\nP_HF = " + reinforcement_advantage + "\nR_t = " + total_resources);
    out.println("NATION PARAMETERS:");
    for (int i = 0; i < p; i++) {
      out.println("NATION " + i + ":" + "\tk_S = " + nations.get(i).k_S + "\tk_R = " + nations.get(i).k_R + "\tk_A_bar = " + nations.get(i).k_A_bar);
    }
    out.println("SIMULATION DATA:");
    String[] data_labels = new String[4*p + 1];
    data_labels[0] = "t";
    int ind = 1;
    for (int l = 1; l < p + 1; l++) {
      data_labels[ind] = "NATION " + (l - 1) + " S";
      ind++;
      data_labels[ind] = "NATION " + (l - 1) + " R";
      ind++;
      data_labels[ind] = "NATION " + (l - 1) + " A_BAR";
      ind++;
      data_labels[ind] = "NATION " + (l - 1) + " ACTION";
      ind++;
    }
    for (int l = 0; l < data_labels.length; l++) {
      out.print(data_labels[l] + "\t");
    }
    out.println();
    out.flush();
  }
}

float[][] generateResources() {
  float[][] resources = new float[n][m];

  if (resource_mode.equals("RANDOM")) {
    drawing_done = true;
    noiseSeed(0);

    for (int i = 0; i < n; i++) {
      for (int j = 0; j < m; j++) {
        resources[i][j] = pow(noise(i*resource_noise_scale, j*resource_noise_scale), resource_noise_power);
        all_resources[m*i + j] = resources[i][j];
        total_resources += resources[i][j];
      }
    }
  }

  return resources;
}

void resourceCalcs() {
  for (int i = 0; i < n; i++) {
    for (int j = 0; j < m; j++) {
      all_resources[m*i + j] = resources[i][j];
      total_resources += resources[i][j];
    }
  }
  Arrays.sort(all_resources);
  if ((n*m)%2 == 0) q = 0.5*(all_resources[(int)(q_quartile*(float)n*m) - 1] + all_resources[(int)(q_quartile*(float)n*m)]);
  else q = all_resources[(int)(q_quartile*(float)n*m)];

  contest_effort = q*contest_effort_factor;
}

void initializeCapitols() {
  capitols = new int[p][2];

  for (int i = 0; i < p; i++) {
    int[] try_cap = {(int)(Math.random()*(float)n), (int)(Math.random()*(float)m)};
    try_cap[0] = (int)(Math.random()*(float)n);
    try_cap[1] = (int)(Math.random()*(float)m);

    if (i > 0) {
      while (checkCapitols(capitols, try_cap)) {
        try_cap[0] = (int)(Math.random()*(float)n);
        try_cap[1] = (int)(Math.random()*(float)m);
      }
    }
    capitols[i][0] = try_cap[0];
    capitols[i][1] = try_cap[1];
    total_controlled_resources += resources[capitols[i][0]][capitols[i][1]];
    new_nationalities[capitols[i][0]][capitols[i][1]] = i;
    nationalities[capitols[i][0]][capitols[i][1]] = i;

    //float[] genome = new float[3];
    //float total = 0;
    //for (int j = 0; j < 3; j++) {
    //  genome[j] = (float)Math.random();
    //  total += genome[j];
    //}

    //nations.add(new Nation(i, genome[0]/total, genome[1]/total, genome[2]/total));
    nations.add(new Nation(i, 1.0/3., 1.0/3., 1.0/3.));
    last_actions[i] = new ArrayList<Action>(0);
  }
  nations.get(0).k_R = 0.1;
  nations.get(0).k_S = 0.8;
  nations.get(0).k_A_bar = 0.1;
}

boolean checkCapitols(int[][] caps, int[] c) {
  for (int i = 0; i < caps.length; i++) {
    if ((abs(c[0] - caps[i][0]) + abs(c[1] - caps[i][1])) < capitol_distancing) return true;
  }
  return false;
}

void initializeNationalities() {
  nationalities = new int[n][m];
  new_nationalities = new int[n][m];
  reinforced = new boolean[n][m];
  new_reinforced = new boolean[n][m];
  for (int i = 0; i < n; i++) {
    for (int j = 0; j < m; j++) {
      nationalities[i][j] = -1;
      new_nationalities[i][j] = -1;
      reinforced[i][j] = false;
      new_reinforced[i][j] = false;
      contested_cells[i][j] = new ArrayList<Nation>(0);
    }
  }
}

void initializeColors() {
  colorMode(HSB, 255);
  capitol_colors = new color[p];
  for (int i = 0; i < p; i++) capitol_colors[i] = color((255.0/(float)p)*i, 255, 255);
  nation_colors = new color[p + 1];
  nation_colors[0] = color(200);
  colorMode(RGB, 255);
  for (int i = 1; i < p + 1; i++) nation_colors[i] = lerpColor(capitol_colors[i - 1], color(200), 0.75);
}
