#include <vector>

#include <vtkActor.h>
#include <vtkPoints.h>
#include <vtkRenderer.h>
#include <vtkPolyData.h>
#include <vtkProperty.h>
#include <vtkPropPicker.h>
#include <vtkNamedColors.h>
#include <vtkSphereSource.h>
#include <vtkObjectFactory.h>
#include <vtkPolyDataMapper.h>
#include <vtkVertexGlyphFilter.h>
#include <vtkPointGaussianMapper.h>
#include <vtkMinimalStandardRandomSequence.h>

#include <pcl/point_cloud.h>
#include <pcl/point_types.h>

#include <fstream>
#include <sstream>
#include <vector>
#include <memory>

// Base pipeline
struct VtkPipeline {
    public:
    virtual ~VtkPipeline() = default;
    virtual void addToRenderer(vtkRenderer* renderer) {
        for (auto& actor : actors) {
            renderer->AddActor(actor);
        }
    }
    std::vector<vtkSmartPointer<vtkActor>> actors;
};

// Point cloud pipeline
struct PointCloudPipeline : public VtkPipeline {
    public:
    // Canonical point cloud state (PCL)
    pcl::PointCloud<pcl::PointXYZ>::Ptr cloud;
    // Rendering state (VTK)
    vtkSmartPointer<vtkPoints> points;
    vtkSmartPointer<vtkPolyData> polyData;
    vtkSmartPointer<vtkVertexGlyphFilter> glyphFilter;
    vtkSmartPointer<vtkPointGaussianMapper> mapper;
    // Construction
    PointCloudPipeline() {
        // PCL state
        cloud =
            pcl::PointCloud<pcl::PointXYZ>::Ptr(
                new pcl::PointCloud<pcl::PointXYZ>);
        // VTK geometry
        points = vtkSmartPointer<vtkPoints>::New();
        points->SetDataTypeToFloat();
        polyData = vtkSmartPointer<vtkPolyData>::New();
        polyData->SetPoints(points);
        // Vertex generation for point rendering
        glyphFilter =
            vtkSmartPointer<vtkVertexGlyphFilter>::New();
        glyphFilter->SetInputData(polyData);
        // Mapper
        mapper = vtkSmartPointer<vtkPointGaussianMapper>::New();
        mapper->SetInputConnection(
            glyphFilter->GetOutputPort());
        mapper->SetScaleFactor(0.03);
        mapper->SetSplatShaderCode(
            "//VTK::Color::Impl\n"
            "float d = dot(offsetVCVSOutput.xy, "
            "offsetVCVSOutput.xy);\n"
            "if (d > 1.0) discard;\n"
        );
        // Actor
        auto actor = vtkSmartPointer<vtkActor>::New();
        actor->SetMapper(mapper);
        actor->GetProperty()->SetColor(
            1.0, 1.0, 1.0);
        actor->GetProperty()->SetOpacity(1.0);
        actors.push_back(actor);
    }
    // Load XYZ into canonical PCL cloud
    bool loadXYZ(const std::string& filePath) {
        cloud->clear();
        std::ifstream file(filePath);
        if (!file.is_open()) {
            std::cerr
                << "Failed to open file: "
                << filePath
                << std::endl;
            return false;
        }
        std::string line;
        while (std::getline(file, line)) {
            if (line.empty() || line[0] == '#')
                continue;
            std::stringstream ss(line);
            pcl::PointXYZ pt;
            if (ss >> pt.x >> pt.y >> pt.z) {
                cloud->points.push_back(pt);
            }
        }
        cloud->width =
            static_cast<uint32_t>(cloud->points.size());
        cloud->height = 1;
        cloud->is_dense = true;
        return true;
    }
    // Synchronize PCL -> VTK
    void syncToVTK() {
        // Reset old VTK state
        points->Reset();
        polyData->Reset();
        // Reattach points after reset
        polyData->SetPoints(points);
        // Copy PCL points into VTK
        points->SetNumberOfPoints(
            static_cast<vtkIdType>(
                cloud->points.size()));
        for (vtkIdType i = 0;
             i < static_cast<vtkIdType>(
                    cloud->points.size());
             ++i) {
            const auto& p = cloud->points[i];
            points->SetPoint(i, p.x, p.y, p.z);
        }
        // Notify VTK pipeline 
        points->Modified();
        polyData->Modified();
        glyphFilter->Update();
        polyData->ComputeBounds();
    }
};

// Random sphere pipeline
class SpherePipeline : public VtkPipeline {
    public:
    SpherePipeline(int numberOfSpheres = 10) {
        vtkNew<vtkNamedColors> colors;
        vtkNew<vtkMinimalStandardRandomSequence> randomSequence;
        randomSequence->SetSeed(8775070);
        for (int i = 0; i < numberOfSpheres; ++i) {
            vtkNew<vtkSphereSource> source;
            double x =
                randomSequence->GetRangeValue(-5.0, 5.0);
            randomSequence->Next();
            double y =
                randomSequence->GetRangeValue(-5.0, 5.0);
            randomSequence->Next();
            double z =
                randomSequence->GetRangeValue(-5.0, 5.0);
            randomSequence->Next();
            double radius =
                randomSequence->GetRangeValue(0.5, 1.0);
            randomSequence->Next();
            source->SetCenter(x, y, z);
            source->SetRadius(radius);
            source->SetPhiResolution(11);
            source->SetThetaResolution(21);
            vtkNew<vtkPolyDataMapper> mapper;
            mapper->SetInputConnection(
                source->GetOutputPort());
            vtkNew<vtkActor> actor;
            actor->SetMapper(mapper);
            double r =
                randomSequence->GetRangeValue(0.4, 1.0);
            randomSequence->Next();
            double g =
                randomSequence->GetRangeValue(0.4, 1.0);
            randomSequence->Next();
            double b =
                randomSequence->GetRangeValue(0.4, 1.0);
            randomSequence->Next();
            actor->GetProperty()->SetDiffuseColor(r, g, b);
            actor->GetProperty()->SetDiffuse(0.8);
            actor->GetProperty()->SetSpecular(0.5);
            actor->GetProperty()->SetSpecularColor(
                colors->GetColor3d("White").GetData());
            actor->GetProperty()->SetSpecularPower(30.0);
            actors.push_back(actor);
        }
    }
};