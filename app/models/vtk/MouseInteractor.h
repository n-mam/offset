#include <vtkInteractorStyleTrackballCamera.h>
#include <vtkPointPicker.h>
#include <vtkRenderWindowInteractor.h>
#include <vtkRenderer.h>
#include <vtkNew.h>
#include <vtkSmartPointer.h>
#include <vtkProperty.h>
#include <vtkSphereSource.h>
#include <vtkPolyDataMapper.h>
#include <vtkActor.h>
#include <vector>
#include <cmath>
#include <iostream>

// ============================================================
// Point picking + distance measurement
// ============================================================
struct PointPickerDistanceStyle : public vtkInteractorStyleTrackballCamera
{
public:
    static PointPickerDistanceStyle* New();
    vtkTypeMacro(PointPickerDistanceStyle, vtkInteractorStyleTrackballCamera);

    PointPickerDistanceStyle()
    {
        Picker = vtkSmartPointer<vtkPointPicker>::New();
        LastPickedPointId = -1;
    }

    void OnLeftButtonDown() override
    {
        int* clickPos = this->GetInteractor()->GetEventPosition();

        Picker->Pick(clickPos[0],
                     clickPos[1],
                     0,
                     this->GetDefaultRenderer());

        vtkIdType pid = Picker->GetPointId();

        if (pid >= 0)
        {
            double p[3];
            Picker->GetPickPosition(p);

            std::cout << "Picked point ID: " << pid
                      << "  Position: ("
                      << p[0] << ", "
                      << p[1] << ", "
                      << p[2] << ")\n";

            PickedPoints.push_back({pid, {p[0], p[1], p[2]}});

            // If we have 2 points → compute distance
            if (PickedPoints.size() >= 2)
            {
                auto& A = PickedPoints[PickedPoints.size() - 2].pos;
                auto& B = PickedPoints[PickedPoints.size() - 1].pos;

                double dist =
                    std::sqrt(
                        std::pow(A[0] - B[0], 2) +
                        std::pow(A[1] - B[1], 2) +
                        std::pow(A[2] - B[2], 2));

                std::cout << "Distance: " << dist << std::endl;

                // Optional: keep only last 2 points
                // PickedPoints.clear();
                // PickedPoints.push_back(...);
            }

            // Optional: visualize picked point as a sphere
            AddMarker(p);
        }
        vtkInteractorStyleTrackballCamera::OnLeftButtonDown();
    }

    private:
    
    struct PointInfo{
        vtkIdType id;
        std::array<double, 3> pos;
    };

    vtkIdType LastPickedPointId;
    std::vector<PointInfo> PickedPoints;
    vtkSmartPointer<vtkPointPicker> Picker;

    void AddMarker(double p[3]) {
        vtkNew<vtkSphereSource> sphere;
        sphere->SetCenter(p);
        sphere->SetRadius(0.01); // adjust for your scale

        vtkNew<vtkPolyDataMapper> mapper;
        mapper->SetInputConnection(sphere->GetOutputPort());

        vtkNew<vtkActor> actor;
        actor->SetMapper(mapper);
        actor->GetProperty()->SetColor(1.0, 0.0, 0.0);

        this->GetDefaultRenderer()->AddActor(actor);
        this->GetInteractor()->Render();
    }
};

vtkStandardNewMacro(PointPickerDistanceStyle);