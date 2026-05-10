#ifndef MYVTKITEM_H
#define MYVTKITEM_H

#include "QQuickVTKItem.h"

class MyVtkItem : public QQuickVTKItem
{
public:
    vtkUserData initializeVTK(vtkRenderWindow *renderWindow) override;
};

#endif // MYVTKITEM_H
