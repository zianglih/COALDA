#include "rgb.cu"
#include "rgb_func.cu"
#include "ppm_utils.h"
#include <cstdio>

#define TILE_WIDTH 32

void test_rgb_array()
{
  const dim3 dimGrid = dim3(1, 1, 1);
  const dim3 dimBlock = dim3(TILE_WIDTH, 1, 1);
  int num_pixels = dimGrid.x * dimBlock.x;
  int host_pixel_src[3 * num_pixels];
  int host_pixel_res[3 * num_pixels];
  int *device_pixel_src;
  int *device_pixel_cpy;
  srand(1);
  for (int i = 0; i < num_pixels; i++)
  {
    host_pixel_src[3 * i + 0] = rand() % 256;
    host_pixel_src[3 * i + 1] = rand() % 256;
    host_pixel_src[3 * i + 2] = rand() % 256;
  }
  printf("Host data initialized:\n");
  for (int i = 0; i < num_pixels; i++)
  {
    printf("%d %d %d %d\n", i, host_pixel_src[3 * i + 0], host_pixel_src[3 * i + 1], host_pixel_src[3 * i + 2]);
  }
  cudaMalloc(&device_pixel_src, 3 * num_pixels * sizeof(int));
  cudaMalloc(&device_pixel_cpy, 3 * num_pixels * sizeof(int));
  cudaMemcpy(device_pixel_src, host_pixel_src, 3 * num_pixels * sizeof(int), cudaMemcpyHostToDevice);

  rgb_copy_array_interleaved<<<dimGrid, dimBlock>>>(device_pixel_cpy, device_pixel_src);
  cudaDeviceSynchronize();

  cudaMemcpy(host_pixel_res, device_pixel_cpy, 3 * num_pixels * sizeof(int), cudaMemcpyDeviceToHost);
  cudaDeviceSynchronize();

  bool success = true;
  printf("Data after device internal copy:\n");
  for (int i = 0; i < num_pixels; i++)
  {
    printf("%d %d %d %d\n", i, host_pixel_res[3 * i + 0], host_pixel_res[3 * i + 1], host_pixel_res[3 * i + 2]);
    if (host_pixel_res[3 * i + 0] != host_pixel_src[3 * i + 0] ||
        host_pixel_res[3 * i + 1] != host_pixel_src[3 * i + 1] ||
        host_pixel_res[3 * i + 2] != host_pixel_src[3 * i + 2])
    {
      success = false;
      printf("Error on pixel %d\n", i);
    }
  }
  if (success)
  {
    printf("All matched!\n");
  }

  cudaFree(device_pixel_src);
  cudaFree(device_pixel_cpy);
}

void test_increase_brightness()
{
  int width, height;
  int *host_pixel_src = read_ppm("images/1.ppm", width, height);
  const dim3 dimGrid = dim3(1, 1, 1);
  const dim3 dimBlock = dim3(TILE_WIDTH, 1, 1);
  int num_pixels = width * height;
  int host_pixel_res[3 * num_pixels];
  int *device_pixel_src;
  int *device_pixel_cpy;
  cudaMalloc(&device_pixel_src, 3 * num_pixels * sizeof(int));
  cudaMalloc(&device_pixel_cpy, 3 * num_pixels * sizeof(int));
  cudaMemcpy(device_pixel_src, host_pixel_src, 3 * num_pixels * sizeof(int), cudaMemcpyHostToDevice);
  rgb_increase_brightness(device_pixel_cpy, device_pixel_src, width * height, 1.2);
  cudaDeviceSynchronize();
  cudaMemcpy(host_pixel_res, device_pixel_cpy, 3 * num_pixels * sizeof(int), cudaMemcpyDeviceToHost);
  cudaDeviceSynchronize();
  write_ppm("images/1_modified.ppm", host_pixel_res, width, height);
}

int main()
{
  test_rgb_array();
  return 0;
}