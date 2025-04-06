void initializeDataLogging() {
  if (log_data) {
    SimpleDateFormat ft = new SimpleDateFormat("hh_mm_ss_dd_MM_yyyy");
    String filename = ".\\output\\WAR_SIMULATION_" + ft.format(new Date()) + ".txt";
    out = createWriter(filename);
    out.println("SIMULATION PARAMETERS:");
    out.print("n = " + n + "\nm = " + m + "\np = " + p + "\nresource_noise_scale = ");
    out.println(resource_noise_scale);
    out.println();
    out.println("SIMULATION DATA:");
    String[] data_labels = new String[2*(p + 1) + 1];
    data_labels[0] = "t";
    int ind = 1;
    for (int l = 0; l < p + 1; l++) {
      data_labels[ind] = "NATION " + (l - 1) + " SIZE";
      ind++;
      data_labels[ind] = "NATION " + (l - 1) + " RESOURCES";
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

  fighting_effort = q*fighting_effort_factor;
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
    resources[capitols[i][0]][capitols[i][1]] = 1.0;
    float[] genome = new float[3];
    float total = 0;
    for (int j = 0; j < 3; j++) {
      genome[j] = (float)Math.random();
      total += genome[j];
    }
    nations.add(new Nation(i, genome[0]/total, genome[1]/total, genome[2]/total));
  }
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
  for (int i = 0; i < n; i++) {
    for (int j = 0; j < m; j++) {
      nationalities[i][j] = -1;
      new_nationalities[i][j] = -1;
      contested_cells[i][j] = new ArrayList<Nation>(0);
    }
  }
  for (int l = 0; l < p; l++) nationalities[capitols[l][0]][capitols[l][1]] = l;
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
