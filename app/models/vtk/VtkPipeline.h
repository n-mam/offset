#include <vtkActor.h>
#include <vtkPoints.h>
#include <vtkRenderer.h>
#include <vtkPolyData.h>
#include <vtkProperty.h>
#include <vtkPointData.h>
#include <vtkPropPicker.h>
#include <vtkNamedColors.h>
#include <vtkSphereSource.h>
#include <vtkObjectFactory.h>
#include <vtkPolyDataMapper.h>
#include <vtkUnsignedCharArray.h>
#include <vtkMinimalStandardRandomSequence.h>

#include <stream.voxel.filter.h>

#include <vector>
#include <memory>
#include <fstream>
#include <sstream>

// Base pipeline
struct VtkPipeline {
    std::vector<vtkSmartPointer<vtkActor>> actors;
    virtual ~VtkPipeline() = default;
    void addToRenderer(vtkRenderer* renderer) {
        for (auto& actor : actors) {
            renderer->AddActor(actor);
        }
    }
};

// Point cloud pipeline
struct PointCloudPipeline : public VtkPipeline {

    pcl_stream_voxel_filter pcl_svf;
    vtkSmartPointer<vtkActor> actor;
    vtkSmartPointer<vtkPoints> points;
    vtkSmartPointer<vtkCellArray> verts;
    vtkSmartPointer<vtkPolyData> polyData;
    vtkSmartPointer<vtkPolyDataMapper> mapper;
    vtkSmartPointer<vtkUnsignedCharArray> colors;

    PointCloudPipeline() {
        // Points and geometry
        points = vtkSmartPointer<vtkPoints>::New();
        points->SetDataTypeToFloat();
        verts = vtkSmartPointer<vtkCellArray>::New();
        polyData = vtkSmartPointer<vtkPolyData>::New();
        polyData->SetPoints(points);
        polyData->SetVerts(verts);
        // Initialize colors array
        colors = vtkSmartPointer<vtkUnsignedCharArray>::New();
        colors->SetNumberOfComponents(3);  // R, G, B
        colors->SetName("original");
        polyData->GetPointData()->AddArray(colors);
        polyData->GetPointData()->SetActiveScalars("original");        
        // Mapper
        mapper = vtkSmartPointer<vtkPolyDataMapper>::New();
        mapper->SetInputData(polyData);
        mapper->SetScalarModeToUsePointData();
        mapper->SetColorModeToDefault();
        mapper->ScalarVisibilityOn();
        // Actor
        actor = vtkSmartPointer<vtkActor>::New();
        actor->SetMapper(mapper);
        actor->GetProperty()->SetRepresentationToPoints();
        actor->GetProperty()->SetPointSize(2);
        // Add to actor list
        actors.push_back(actor);
    }
    void reset() {
        // CPU state
        pcl_svf.voxel_map.clear();
        pcl_svf.pcl_cloud->points.clear();
        // VTK state
        points->SetNumberOfPoints(0);
        colors->SetNumberOfTuples(0);
        verts->Initialize();
        // Mark dirty once
        polyData->Modified();
    }
};

// Random sphere pipeline
struct SpherePipeline : public VtkPipeline {

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