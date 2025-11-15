# COCO Object Detection in R - Quick Start Guide

## Overview

This package provides a complete workflow for:
1. Downloading and setting up the COCO dataset
2. Loading and exploring COCO annotations
3. Running pre-trained object detection models
4. Visualizing and analyzing results

## Prerequisites

- **R** version 4.0 or higher
- **Python** version 3.7 or higher
- At least **10 GB** of free disk space
- Stable internet connection for downloads

## Installation & Setup

### Step 1: Run the Main Setup Script

```r
source("coco_object_detection.R")
```

This script will:
- Install all required R and Python packages
- Download COCO validation dataset (~1.2 GB total)
- Set up the directory structure
- Load a pre-trained Faster R-CNN model
- Run test detections on sample images

**Note**: The first run will take 15-30 minutes depending on your internet speed.

### Step 2: Load Utility Functions (Optional)

```r
source("coco_utilities.R")
```

This provides additional analysis and batch processing tools.

## Directory Structure

After setup, you'll have:

```
~/coco_dataset/
├── annotations/
│   ├── instances_val2017.json
│   ├── captions_val2017.json
│   └── ...
├── images/
│   └── val2017/
│       ├── 000000000139.jpg
│       ├── 000000000285.jpg
│       └── ... (5000 images)
└── outputs/
    └── (visualizations saved here)
```

## Basic Usage

### 1. View Dataset Information

```r
# Print all available categories
print_categories(coco_data)

# Get category statistics
stats <- get_category_statistics(coco_data)
print(stats)

# Plot category distribution
plot_category_distribution(coco_data, top_n = 20)
```

### 2. Run Object Detection

#### Single Image Detection

```r
# Get a random image
img_path <- coco_data$images$file_path[1]

# Run detection
result <- detect_objects(img_path, confidence_threshold = 0.6)

# View results
print(result$num_detections)
for (det in result$detections) {
  cat(sprintf("%s: %.2f%%\n", det$label_name, det$score * 100))
}

# Visualize
visualize_detections(img_path, result$detections)
```

#### Batch Detection

```r
# Get multiple images
image_paths <- sample_images(coco_data, n = 10)

# Run batch detection
results <- batch_detect(image_paths, confidence_threshold = 0.5)

# Summarize results
summary <- summarize_detections(results)
print(summary)
```

### 3. Find Specific Objects

```r
# Find images containing specific objects
dog_images <- find_images_with_objects(coco_data, c("dog", "cat"))
print(nrow(dog_images))

# Detect only specific object types
result <- detect_specific_object(img_path, "person", confidence_threshold = 0.7)

# Find images with multiple specific objects
combo_images <- find_images_with_combination(
  image_paths = sample_images(coco_data, 50),
  required_objects = c("person", "car"),
  confidence_threshold = 0.6
)
```

### 4. Analyze Results

```r
# Compare with ground truth annotations
comparison <- compare_ground_truth(coco_data, result, image_id = "139")
print(comparison)

# Analyze object sizes
size_analysis <- analyze_object_sizes(coco_data, category = "person")
```

### 5. Export Results

```r
# Export to CSV
export_detections_to_csv(results, "detections.csv")

# Create markdown report
create_detection_report(results, "detection_report.md")
```

## Advanced Examples

### Example 1: Custom Detection Pipeline

```r
# Find all images with people
people_images <- find_images_with_objects(coco_data, "person")

# Run detection with high confidence
people_results <- batch_detect(
  people_images$file_path[1:20],
  confidence_threshold = 0.8
)

# Filter for images with 3+ people
multi_person <- Filter(function(x) {
  x$detections$num_detections >= 3
}, people_results)

# Create visualizations
output_dir <- file.path(coco_data$root, "outputs", "multi_person")
dir.create(output_dir, showWarnings = FALSE)

for (i in 1:length(multi_person)) {
  img_name <- basename(multi_person[[i]]$image_path)
  output_path <- file.path(output_dir, paste0("detected_", img_name))
  
  visualize_detections(
    multi_person[[i]]$image_path,
    multi_person[[i]]$detections$detections,
    output_path
  )
}
```

### Example 2: Confidence Threshold Analysis

```r
# Test different thresholds
thresholds <- seq(0.3, 0.9, by = 0.1)
test_image <- coco_data$images$file_path[1]

threshold_results <- data.frame(
  threshold = numeric(),
  num_detections = numeric()
)

for (thresh in thresholds) {
  result <- detect_objects(test_image, thresh)
  threshold_results <- rbind(threshold_results, data.frame(
    threshold = thresh,
    num_detections = result$num_detections
  ))
}

# Plot results
plot(threshold_results$threshold, threshold_results$num_detections,
     type = "b", pch = 19, col = "blue",
     xlab = "Confidence Threshold",
     ylab = "Number of Detections",
     main = "Detection Count vs Confidence Threshold")
grid()
```

### Example 3: Category-Specific Analysis

```r
# Analyze all vehicle images
vehicle_categories <- c("car", "truck", "bus", "motorcycle")
vehicle_images <- find_images_with_objects(coco_data, vehicle_categories)

# Get size distribution for vehicles
vehicle_anns <- coco_data$annotations[
  coco_data$annotations$category_name %in% vehicle_categories,
]

# Plot area distribution by vehicle type
boxplot(area ~ category_name, data = vehicle_anns,
        main = "Object Size Distribution by Vehicle Type",
        ylab = "Area (pixels²)",
        las = 2,
        col = rainbow(length(vehicle_categories)))
```

## Available Object Categories

The COCO dataset includes 80 object categories:

**People & Animals:**
person, bird, cat, dog, horse, sheep, cow, elephant, bear, zebra, giraffe

**Vehicles:**
bicycle, car, motorcycle, airplane, bus, train, truck, boat

**Outdoor Objects:**
traffic light, fire hydrant, stop sign, parking meter, bench

**Sports:**
sports ball, kite, baseball bat, baseball glove, skateboard, surfboard, tennis racket

**Kitchen:**
bottle, wine glass, cup, fork, knife, spoon, bowl, banana, apple, sandwich, orange, broccoli, carrot, hot dog, pizza, donut, cake

**Furniture:**
chair, couch, potted plant, bed, dining table, toilet

**Electronics:**
tv, laptop, mouse, remote, keyboard, cell phone, microwave, oven, toaster, sink, refrigerator

**Accessories:**
backpack, umbrella, handbag, tie, suitcase, frisbee, skis, snowboard

**Other:**
book, clock, vase, scissors, teddy bear, hair drier, toothbrush

## Performance Tips

1. **Start Small**: Test with a few images before running batch operations
2. **Adjust Confidence**: Use 0.5-0.7 for general detection, 0.8+ for high precision
3. **GPU Acceleration**: If you have a CUDA-capable GPU, PyTorch will automatically use it
4. **Memory Management**: Processing many large images can use significant RAM

## Troubleshooting

### Download Issues

If downloads fail or are interrupted:

```r
# Re-download with force option
download_coco(url, dest_dir, force = TRUE)
```

### Python Package Issues

```r
# Reinstall Python packages
py_install("pycocotools", pip = TRUE)
py_install("torch", pip = TRUE)
py_install("torchvision", pip = TRUE)
```

### Model Loading Errors

```r
# Check if PyTorch is working
py_run_string("
import torch
print(f'PyTorch version: {torch.__version__}')
print(f'CUDA available: {torch.cuda.is_available()}')
")
```

### Image Loading Issues

Ensure images exist:

```r
# Check if image file exists
file.exists(coco_data$images$file_path[1])

# List available images
list.files(file.path(coco_data$root, "images", "val2017"))
```

## Function Reference

### Core Functions

| Function | Description |
|----------|-------------|
| `detect_objects(path, threshold)` | Run object detection on single image |
| `visualize_detections(path, dets, save)` | Create visualization with bounding boxes |
| `batch_detect(paths, threshold)` | Run detection on multiple images |

### Analysis Functions

| Function | Description |
|----------|-------------|
| `get_category_statistics(data)` | Count objects per category |
| `find_images_with_objects(data, cats)` | Find images containing specific objects |
| `analyze_object_sizes(data, cat)` | Analyze object size distributions |
| `compare_ground_truth(data, result, id)` | Compare predictions with annotations |

### Utility Functions

| Function | Description |
|----------|-------------|
| `print_categories(data)` | Display all available categories |
| `sample_images(data, n)` | Get random sample of images |
| `export_detections_to_csv(results, file)` | Export results to CSV |
| `create_detection_report(results, file)` | Generate markdown report |

## Citation

If you use this code or the COCO dataset in your research, please cite:

```
@inproceedings{lin2014microsoft,
  title={Microsoft COCO: Common Objects in Context},
  author={Lin, Tsung-Yi and Maire, Michael and Belongie, Serge and others},
  booktitle={European Conference on Computer Vision},
  pages={740--755},
  year={2014},
  organization={Springer}
}
```

## Resources

- **COCO Dataset**: https://cocodataset.org/
- **PyTorch**: https://pytorch.org/
- **Torchvision Models**: https://pytorch.org/vision/stable/models.html
- **Reticulate Documentation**: https://rstudio.github.io/reticulate/

## License

The COCO dataset is licensed under the Creative Commons Attribution 4.0 License.

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review function documentation: `?function_name`
3. Check COCO dataset documentation: https://cocodataset.org/

## Version History

- **v1.0** (2024): Initial release with Faster R-CNN support
- Includes validation dataset download
- Batch processing capabilities
- Comprehensive visualization tools
