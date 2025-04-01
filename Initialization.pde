void initializeDataLogging() {
  if (log_data) {
    SimpleDateFormat ft = new SimpleDateFormat("hh_mm_ss_dd_MM_yyyy");
    String filename = ".\\output\\WAR_SIMULATION_" + ft.format(new Date()) + ".txt";
    out = createWriter(filename);
    out.println("SIMULATION PARAMETERS:");
    out.print("n = " + n + "\nm = " + m + "\nk = " + k + "\np = " + p + "\nrecruit_likeliness = " + recruit_likeliness + "\ndefeat_likeliness = " + defeat_likeliness +
      "\nstarting_control = " + starting_control + "\nresource_noise_scale = ");
    out.println(resource_noise_scales[0]);
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

float[][][] generateResources() {
  float[][][] resources = new float[n][m][k];

  noiseSeed(0);

  for (int z = 0; z < k; z++) {
    for (int i = 0; i < n; i++) {
      for (int j = 0; j < m; j++) {
        resources[i][j][z] = pow(noise(i*resource_noise_scales[z], j*resource_noise_scales[z]), resource_noise_power);
      }
    }
  }

  return resources;
}

void initializeCapitols() {
  capitols = new int[p][2];
  for (int i = 0; i < p; i++) {
    capitols[i][0] = -1;
    capitols[i][1] = -1;
  }
  int[][] cap = {{0, 0}, {0, m - 1}, {n - 1, 0}, {n - 1, m - 1}};
  //capitols = copy2DArray(cap);
  for (int i = 0; i < p; i++) {
    int[] try_cap = {(int)(Math.random()*(float)n), (int)(Math.random()*(float)m)};

    if (i > 0) {
      while (checkCapitols(capitols, try_cap)) {
        try_cap[0] = (int)(Math.random()*(float)n);
        try_cap[1] = (int)(Math.random()*(float)m);
      }
    }
    capitols[i][0] = try_cap[0];
    capitols[i][1] = try_cap[1];
    resources[capitols[i][0]][capitols[i][1]][0] = 1.0;
  }
}

boolean checkCapitols(int[][] caps, int[] c) {
  for (int i = 0; i < caps.length; i++) {
    if ((c[0] == caps[i][0]) && (c[1] == caps[i][1])) return true;
  }
  return false;
}

void initializeNationalities() {
  nationalities = new int[n][m];
  new_nationalities = new int[n][m];
  control = new int[n][m];
  new_control = new int[n][m];
  nation_resources = new float[p + 1][k];
  new_nation_resources = new float[p + 1][k];
  nation_sizes = new float[p + 1];
  new_nation_sizes = new float[p + 1];
  for (int i = 0; i < n; i++) {
    for (int j = 0; j < m; j++) {
      nationalities[i][j] = -1;
      new_nationalities[i][j] = -1;
      control[i][j] = 0;
      new_control[i][j] = 0;
    }
  }

  for (int i = 0; i < p; i++) {
    for (int j = 0; j < k; j++) {
      nation_resources[i][j] = 0;
      new_nation_resources[i][j] = 0;
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

class Contender implements Comparable {
  int nationality;
  float score;

  Contender(int nat, float sc) {
    this.nationality = nat;
    this.score = sc;
  }

  int compareTo(Object c) {
    return int((100.0*(this.score - ((Contender) c).score)));
  }
}
