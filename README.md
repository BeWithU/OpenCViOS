# OpenCV在iOS端的应用
## 功能
在iOS端接入OpenCV库，引用自[opencv-mobile](https://github.com/nihui/opencv-mobile)。  
主要功能是通过OpenCV提供的方法，寻找图片中的文档，并做投影变换，转换成矩形。  
- Canny 获得图片里的所有边缘
- findContours 寻找轮廓
- approxPolyDP 拟合多边形
- convexHull 计算凸包
- getPerspectiveTransform 获取投影的矩阵
- warpPerspective 投影变换获得图片
## 使用方法
1. 将opencv2.framework拖到你的工程里。  
2. 将OpenCV.h和OpenCV.mm拖到你的工程里。
3. 引入头文件，调用verticesOfImage计算顶点，然后调用transformImage获得截取矫正的图片。  
