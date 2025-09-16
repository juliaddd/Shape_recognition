# Shape Recognition in MATLAB

A MATLAB-based application for automatic recognition of geometric shapes in images using multiple machine learning models. The system classifies shapes into four categories: squares, rectangles, triangles, and bridges (concave structures).
# Features

- Multi-Model Approach: Implements four machine learning algorithms:

  - k-Nearest Neighbors (KNN)
  - Decision Trees
  - Random Forest
  - Neural Networks
- Rotation & Scale Invariant: Uses sophisticated feature extraction that works regardless of shape orientation or size
- Robust Preprocessing: Handles noisy images with advanced morphological operations
- Multi-Object Processing: Capable of detecting and classifying multiple shapes in a single image
- Color Recognition: Additional functionality for color classification of detected shapes

# Technical Approach
# Step 1: Feature Extraction

The system extracts rotation-invariant features using MATLAB's regionprops and custom algorithms:
- Solidity: Measures how dense/convex an object is, helping distinguish shapes with indentations (Bridge)
    
- Aspect Ratio: Compares width to height, separating squares (≈1) from rectangles (≠1) or elongated shapes
    
- Extent: Ratio of object area to its bounding box area, identifying "fullness" (e.g., triangles have lower values than squares)
    
- Eccentricity: Quantifies elongation
    
- Oriented Bounding Box: Custom implementation for computing minimum-area oriented bounding boxes (Author: David Legland)

Example Feature Output:
  ```
  Object 2: eccentricity=0.8182, obb_aspect_ratio=1.0007, solidity=0.9561, obb_extent=0.5176
  Object 3: eccentricity=0.4840, obb_aspect_ratio=1.2098, solidity=0.9739, obb_extent=0.5456
  Object 4: eccentricity=0.2919, obb_aspect_ratio=1.0396, solidity=0.9840, obb_extent=0.9727
  ```

# Step 2: Training Models

## Data Preprocessing:
- **`zscore` standardization**: Transforms each value to show how many standard deviations it lies from the mean
- Balances feature influence and improves classifier performance

## Machine Learning Methods:

### Statistics and Machine Learning Toolbox:
- **Random Forest** (100 trees)
- **Decision Tree**
- **k-NN** with parameter optimization
- **Cross-validation** (KFold)
- **Data normalization** (`zscore`)

### Deep Learning Toolbox:
- **Neural network architecture**: Input layer → Fully connected layers → Softmax → Classification
- **Adam optimizer**
- **Batch Normalization**, **ReLU**, **L2 regularization**

## Model Evaluation:
- **Confusion Matrix**
- **Accuracy metrics**

---

# Step 3: GUIDE Application

## Image Processing Pipeline:
1. **Image Acquisition**: Getting an image
2. **Morphological Processing**:
   - Adaptive binarization (sensitivity=0.65)
   - Inversion flips black/white pixels (`imcomplement`)
   - Morphological opening removes small noise
   - Hole filling closes dark regions within white objects
   - Morphological closing smoothes edges and fills small gaps

## Classification Workflow:
1. Loading pre-trained models
2. Extracting features for each detected figure in loop
3. Comparing model predictions via results table
4. Color recognition for each shape

## Color Recognition System:
- Averages the RGB Color across image region
- Converts RGB to HSV for easier color classification
- Classifies color based on HSV values
