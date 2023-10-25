#ifndef FACEREC_HPP
#define FACEREC_HPP

#include <osl/log>

#include "opencv2/core.hpp"
#include "opencv2/face.hpp"
#include "opencv2/highgui.hpp"

#include <fstream>
#include <sstream>
#include <iostream>
#include <unordered_map>

namespace cvl {

class facerec
{
  public:

  facerec(const std::string& csv)
  {
    _id_frtag_map.reserve(256);

    try {
      read_csv(csv, _images, _labels, _frTags);
    }
    catch (const std::exception& e) {
      std::cerr << e.what() << std::endl;
    }

    _model = cv::face::LBPHFaceRecognizer::create();

    _model->setRadius(1);
    _model->setNeighbors(8);
    _model->setGridX(8);
    _model->setGridY(8);

    _model->train(_images, _labels);
  }

  ~facerec(){}

  auto getTagFromId(int id)
  {
    std::string tag;

    try {
      tag = _id_frtag_map.at(id);
    }
    catch(const std::exception& e) {
      ERR << e.what() << " " << id;
    }

    return tag;
  }

  auto predict(const cv::Mat& roi)
  {
    int label = -1;
    double confidence = 0.0;

    _model->predict(roi, label, confidence);

    std::pair<std::string, double> fRet;

    if (confidence <= 50)
      fRet = std::make_pair(getTagFromId(label), confidence);

    return fRet;
  }

  private:

  std::vector<int> _labels;
  std::vector<cv::Mat> _images;
  std::vector<std::string> _frTags;

  std::unordered_map<int, std::string> _id_frtag_map;

  cv::Ptr<cv::face::LBPHFaceRecognizer> _model;

  void read_csv(const std::string& filename, std::vector<cv::Mat>& images,
    std::vector<int>& labels, std::vector<std::string>& tags, char separator = ';')
  {
    std::ifstream file(filename.c_str(), std::ifstream::in);

    if (!file) {
      ERR << "No valid input file was given, please check the given filename";
    }

    std::string line, path, classlabel, frtag;

    std::string modelRoot = std::getenv("CVL_MODELS_ROOT");

    while (getline(file, line)) {
      std::stringstream liness(line);
      std::getline(liness, path, separator);
      std::getline(liness, classlabel, separator);
      std::getline(liness, frtag);
      if(!path.empty() && !classlabel.empty() && !frtag.empty()) {
        images.push_back(cv::imread(modelRoot + path, 0));
        int id = std::atoi(classlabel.c_str());
        labels.push_back(id);
        tags.push_back(frtag);
        _id_frtag_map.emplace(id, frtag);
      }
    }
  }

};

// int main_x(int argc, const char *argv[]) {
//   // Check for valid command line arguments, print usage
//   // if no arguments were given.
//   if (argc != 2) {
//     cout << "usage: " << argv[0] << " <csv.ext>" << endl;
//     exit(1);
//   }
//   // Get the path to your CSV.
//   string fn_csv = string(argv[1]);
//   // These vectors hold the images and corresponding labels.
//   std::vector<cv::Mat> images;
//   std::vector<int> labels;
//   // Read in the data. This can fail if no valid
//   // input filename is given.
//   try {
//     read_csv(fn_csv, images, labels);
//   }
//   catch (const cv::Exception& e) {
//     cerr << "Error opening file \"" << fn_csv << "\". Reason: " << e.msg << endl;
//     // nothing more we can do
//     exit(1);
//   }
//   // Quit if there are not enough images for this demo.
//   if(images.size() <= 1) {
//     string error_message = "This demo needs at least 2 images to work. Please add more images to your data set!";
//     CV_Error(Error::StsError, error_message);
//   }
//   // The following lines simply get the last images from
//   // your dataset and remove it from the vector. This is
//   // done, so that the training data (which we learn the
//   // cv::LBPHFaceRecognizer on) and the test data we test
//   // the model with, do not overlap.
//   cv::Mat testSample = images[images.size() - 1];
//   int testLabel = labels[labels.size() - 1];
//   images.pop_back();
//   labels.pop_back();
//   // The following lines create an LBPH model for
//   // face recognition and train it with the images and
//   // labels read from the given CSV file.
//   //
//   // The LBPHFaceRecognizer uses Extended Local Binary Patterns
//   // (it's probably configurable with other operators at a later
//   // point), and has the following default values
//   //
//   // radius = 1
//   // neighbors = 8
//   // grid_x = 8
//   // grid_y = 8
//   //
//   // So if you want a LBPH FaceRecognizer using a radius of
//   // 2 and 16 neighbors, call the factory method with:
//   //
//   // cv::face::LBPHFaceRecognizer::create(2, 16);
//   //
//   // And if you want a threshold (e.g. 123.0) call it with its default values:
//   //
//   // cv::face::LBPHFaceRecognizer::create(1,8,8,8,123.0)
//   //
//   cv::Ptr<cv::face::LBPHFaceRecognizer> model = cv::face::LBPHFaceRecognizer::create();
//   model->train(images, labels);
//   // The following line predicts the label of a given
//   // test image:
//   int predictedLabel = model->predict(testSample);
//   //
//   // To get the confidence of a prediction call the model with:
//   //
//   // int predictedLabel = -1;
//   // double confidence = 0.0;
//   // model->predict(testSample, predictedLabel, confidence);
//   //
//   string result_message = format("Predicted class = %d / Actual class = %d.", predictedLabel, testLabel);

//   std::cout << result_message << std::endl;
//   // First we'll use it to set the threshold of the LBPHFaceRecognizer
//   // to 0.0 without retraining the model. This can be useful if
//   // you are evaluating the model:
//   //
//   model->setThreshold(0.0);
//   // Now the threshold of this model is set to 0.0. A prediction
//   // now returns -1, as it's impossible to have a distance below
//   // it
//   predictedLabel = model->predict(testSample);
//   std::cout << "Predicted class = " << predictedLabel << std::endl;
//   // Show some informations about the model, as there's no cool
//   // Model data to display as in Eigenfaces/Fisherfaces.
//   // Due to efficiency reasons the LBP images are not stored
//   // within the model:
//   std::cout << "Model Information:" << std::endl;
//   string model_info = std::format("\tLBPH(radius=%i, neighbors=%i, grid_x=%i, grid_y=%i, threshold=%.2f)",
//   model->getRadius(),
//   model->getNeighbors(),
//   model->getGridX(),
//   model->getGridY(),
//   model->getThreshold());
//   cout << model_info << endl;
//   // We could get the histograms for example:
//   vector<Mat> histograms = model->getHistograms();
//   // But should I really visualize it? Probably the length is interesting:
//   cout << "Size of the histograms: " << histograms[0].total() << endl;
//   return 0;
// }

}

#endif