<h1 align="center">
<img src="images/logo_vector.svg" width=300px href="https://makeml.app?from=github_potato_weigher" alt="Object Detection and Segmentation MakeML">
</h1>

[MakeML](https://makeml.app?from=github_live_capture_object_detection) is a Developer Tool for Creating Object Detection and Segmentation Neural Networks without a Line of Code. It's built to make the training process easy to setup. It is designed to handle data sets, training configurations, markup and training processes — all in one place.

## MakeML Candle with CoreML and ARKit

This iOS application detects a candlewick, then using ARKit hittest it catches a 3D position of the object in ARKit scene, and apply SKParticleEmitters of fire at this position. That's what we'll show you how to do in this tutorial.

Our example app was made using a couple of short videos of a candle, ARKit, and SpriteKit Particle.

[Full tutorial.](https://makeml.app/docs/candle_fire_editorial?from=github_candle_project)

<div align="center">
<img src="images/CandleFire.gif">
</div>

## Train Custom Object Detection CoreML model
[![MakeML object detection and segmentation ML models](https://img.shields.io/static/v1?label=platform&message=macOS&color=blue)](https://makeml.app)

With MakeML you can prepare dataset and train CoreML model with Tensorflow or Turi Create frameworks in one application.

See the [Tutorial](https://makeml.app/docs/doc1?from=github_candle_project) for the training object detection model without a line of code with macOS desktop application.

<div align="center">
<img src="images/dog_detector_markup.gif">
</div>

<div align="center">
<img src="images/doc_detector_result.gif">
</div>

## Using another .mlmodel in iOS application
[![MakeML object detection and segmentation ML models](https://img.shields.io/static/v1?label=platform&message=iOS&color=blue)](https://makeml.app)    [![MakeML object detection and segmentation ML models](https://img.shields.io/static/v1?label=language&message=swift&color=green)](https://makeml.app)

For using this project with another .mlmodel file, add it to the project and change this line with your name of the model intead of CandleDetector.
```
let model = try VNCoreMLModel(for: CandleDetector().model)
```

## Links

[More Tutorials](https://makeml.app/tutorials?from=github_candle_project) | [MakeML in App Store](https://apps.apple.com/us/app/makeml/id1469520792?mt=12) | [Full Documentation](https://makeml.app/docs/doc1?from=github_candle_project) | [MakeML Chat](https://discordapp.com/invite/vgcG3Su) | [Support page](https://makeml.app/support?from=github_candle_project)

