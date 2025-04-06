public static int[][] copy2DArray(int[][] arr1) {

  // Create a new 2D array with the same
  // number of rows as the original
  int[][] arr2 = new int[arr1.length][];

  // Copy each row using Arrays.copyOf() method
  for (int i = 0; i < arr1.length; i++) {
    arr2[i] = Arrays.copyOf(arr1[i], arr1[i].length);
  }

  return arr2;
}

public static float[][] copy2DArray(float[][] arr1) {

  // Create a new 2D array with the same
  // number of rows as the original
  float[][] arr2 = new float[arr1.length][];

  // Copy each row using Arrays.copyOf() method
  for (int i = 0; i < arr1.length; i++) {
    arr2[i] = Arrays.copyOf(arr1[i], arr1[i].length);
  }

  return arr2;
}

boolean contains(ArrayList<int[]> a, int[] c) {
  for (int[] b: a) {
    if ((b[0] == c[0]) && (b[1] == c[1])) return true;
  }
  return false;
}
