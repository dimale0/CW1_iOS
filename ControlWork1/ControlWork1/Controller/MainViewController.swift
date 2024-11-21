//
//  MainViewController.swift
//  ControlWork1
//
//  Created by Дмитрий Леонтьев on 21.11.2024.
//

import UIKit

class MainViewController: UIViewController {
    private var images: [UIImage] = []
    private var isParallelProcessing = true
    private var task: Task<Void, Never>?
    
    private let mainView = MainView()

    override func loadView() {
        view = mainView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        ImageDatabase.shared.loadImages()
        images = ImageDatabase.shared.getImages()

        mainView.collectionView.delegate = self
        mainView.collectionView.dataSource = self

        mainView.collectionView.register(ImageCell.self, forCellWithReuseIdentifier: "ImageCell")

        mainView.collectionView.reloadData()

        mainView.segmentedControl.addTarget(self, action: #selector(modeChanged), for: .valueChanged)
        mainView.startButton.addTarget(self, action: #selector(startCalculations), for: .touchUpInside)
    }

    @objc private func modeChanged() {
        isParallelProcessing = mainView.segmentedControl.selectedSegmentIndex == 0
    }

    @objc private func startCalculations() {
        task?.cancel()
        
        mainView.startButton.isEnabled = false

        task = Task(priority: .userInitiated) {
            defer {
                Task { @MainActor in
                    self.mainView.startButton.isEnabled = true
                }
            }

            await MainActor.run {
                self.mainView.progressView.progress = 0
            }

            let totalImages = self.images.count

            if self.isParallelProcessing {
                await withTaskGroup(of: (Int, UIImage?).self) { group in
                    for (index, originalImage) in self.images.enumerated() {
                        group.addTask {
                            let processedImage = ImageProcessor().applyRandomFilter(to: originalImage)
                            return (index, processedImage)
                        }
                    }

                    var processedCount = 0

                    for await (index, processedImage) in group {
                        if let processedImage = processedImage {
                            self.images[index] = processedImage

                            await MainActor.run {
                                self.mainView.collectionView.reloadItems(at: [IndexPath(item: index, section: 0)])
                            }
                        }

                        processedCount += 1
                        let progress = Float(processedCount) / Float(totalImages)
                        await MainActor.run {
                            self.mainView.progressView.progress = progress
                        }
                    }
                }
            } else {
                for (index, originalImage) in self.images.enumerated() {
                    if Task.isCancelled {
                        break
                    }

                    if let processedImage = ImageProcessor().applyRandomFilter(to: originalImage) {
                        self.images[index] = processedImage

                        await MainActor.run {
                            self.mainView.collectionView.reloadItems(at: [IndexPath(item: index, section: 0)])
                            
                            let progress = Float(index + 1) / Float(totalImages)
                            self.mainView.progressView.progress = progress
                        }
                    }
                }
            }
        }
    }
}

extension MainViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return images.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard images.indices.contains(indexPath.item) else {
            fatalError("Index out of bounds: images.count = \(images.count), indexPath.item = \(indexPath.item)")
        }

        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as? ImageCell else {
            fatalError("Could not dequeue cell of type ImageCell")
        }

        cell.updateImage(images[indexPath.item])
        return cell
    }
}

extension MainViewController: UICollectionViewDelegate {}
