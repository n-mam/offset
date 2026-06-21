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

// Point cloud pipeline
struct PointCloudPipeline {

    enum filter {
        original = 0,
        ground
    };

    stream_voxel_filter svf;
    vtkSmartPointer<vtkPoints> points;
    vtkSmartPointer<vtkCellArray> verts;
    vtkSmartPointer<vtkPolyData> polyData;
    vtkSmartPointer<vtkPolyDataMapper> mapper;
    vtkSmartPointer<vtkUnsignedCharArray> colors;
    std::vector<vtkSmartPointer<vtkActor>> actors;

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
        auto actor = vtkSmartPointer<vtkActor>::New();
        actor->SetMapper(mapper);
        actor->GetProperty()->SetRepresentationToPoints();
        actor->GetProperty()->SetPointSize(2);
        // Add to actor list
        actors.push_back(actor);
    }

    void addToRenderer(vtkRenderer* renderer) {
        for (auto& actor : actors) {
            renderer->AddActor(actor);
        }
    }

    void reset() {
        // CPU state
        svf.voxel_map.clear();
        svf.cloud->points.clear();
        // VTK state
        points->SetNumberOfPoints(0);
        colors->SetNumberOfTuples(0);
        verts->Initialize();
        // Mark dirty once
        polyData->Modified();
    }
};