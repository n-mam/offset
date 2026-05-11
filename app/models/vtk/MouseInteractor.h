#include <vtkInteractorStyleTrackballCamera.h>

// ============================================================
// Mouse interaction
// ============================================================
struct MouseInteractorHighLightActor : public vtkInteractorStyleTrackballCamera {
    public:
    static MouseInteractorHighLightActor* New();
    vtkTypeMacro(MouseInteractorHighLightActor,
                     vtkInteractorStyleTrackballCamera);
    MouseInteractorHighLightActor(){
        LastPickedActor = nullptr;
        LastPickedProperty = vtkProperty::New();
    }
    ~MouseInteractorHighLightActor() override {
        LastPickedProperty->Delete();
    }
    void OnLeftButtonDown() override {
        vtkNew<vtkNamedColors> colors;
        int* clickPos = this->GetInteractor()->GetEventPosition();
        vtkNew<vtkPropPicker> picker;
        picker->Pick(
            clickPos[0],
            clickPos[1],
            0,
            this->GetDefaultRenderer());
        // restore previous actor
        if (LastPickedActor) {
            LastPickedActor->GetProperty()->DeepCopy(
                LastPickedProperty);
        }
        LastPickedActor = picker->GetActor();
        // highlight picked actor
        if (LastPickedActor) {
            LastPickedProperty->DeepCopy(
                LastPickedActor->GetProperty());
            LastPickedActor->GetProperty()->SetColor(
                colors->GetColor3d("Red").GetData());
            LastPickedActor->GetProperty()->SetDiffuse(1.0);
            LastPickedActor->GetProperty()->SetSpecular(0.0);
            LastPickedActor->GetProperty()->EdgeVisibilityOn();
        }
        vtkInteractorStyleTrackballCamera::OnLeftButtonDown();
    }
    private:
    vtkActor* LastPickedActor;
    vtkProperty* LastPickedProperty;
};

vtkStandardNewMacro(MouseInteractorHighLightActor);