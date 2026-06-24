#include <vtkActor.h>
#include <vtkPoints.h>
#include <vtkRenderer.h>
#include <vtkPolyData.h>
#include <vtkProperty.h>
#include <vtkPointData.h>
#include <vtkNamedColors.h>
#include <vtkPolyDataMapper.h>
#include <vtkUnsignedCharArray.h>

#include <stream.voxel.filter.h>

#include <vector>
#include <memory>
#include <fstream>
#include <sstream>

struct PointCloudPipeline {
    enum type {
        none,
        base,
        ground, //pmf
        elevation, // z-heatmap
    };
    stream_voxel_filter svf;
    vtkSmartPointer<vtkPoints> points;
    vtkSmartPointer<vtkCellArray> verts;
    vtkSmartPointer<vtkPolyData> polyData;
    vtkSmartPointer<vtkPolyDataMapper> mapper;
    vtkSmartPointer<vtkUnsignedCharArray> colors;
    std::vector<vtkSmartPointer<vtkActor>> actors;

    PointCloudPipeline() {
        // points and geometry
        points = vtkSmartPointer<vtkPoints>::New();
        points->SetDataTypeToFloat();
        verts = vtkSmartPointer<vtkCellArray>::New();
        polyData = vtkSmartPointer<vtkPolyData>::New();
        polyData->SetPoints(points);
        polyData->SetVerts(verts);
        // initialize colors array
        colors = vtkSmartPointer<vtkUnsignedCharArray>::New();
        colors->SetNumberOfComponents(3);  // R, G, B
        colors->SetName("original");
        polyData->GetPointData()->AddArray(colors);
        polyData->GetPointData()->SetActiveScalars("original");        
        // mapper
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

    void addActorsToRenderer(vtkRenderer* renderer) {
        if (renderer) {
            for (auto& actor : actors) {
                renderer->AddActor(actor);
            }
        }
    }

    void removeActorsFromRenderer(vtkRenderer* renderer) {
        if (renderer) {
            for (auto& actor : actors) {
                if (actor) {
                    renderer->RemoveActor(actor);
                }
            }
        }
    }

    bool is_empty() {
        return (points->GetNumberOfPoints() == 0);
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

using sppl = std::shared_ptr<PointCloudPipeline>;