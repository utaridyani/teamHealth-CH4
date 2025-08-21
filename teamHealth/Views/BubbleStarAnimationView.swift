//
//  BubbleStarAnimationRepresentable.swift
//  teamHealth
//
//  Created by Henokh Abhinaya Tjahjadi on 21/08/25.
//

import UIKit

class BubbleStarAnimationView: UIView {

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear

        addFoamEmitter()
        addStarburstEmitter()
        addCirclePulse()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    private func addFoamEmitter() {
        let emitter = CAEmitterLayer()
        emitter.emitterPosition = CGPoint(x: bounds.midX, y: bounds.midY)
        emitter.emitterShape = .point

        let cell = CAEmitterCell()
        cell.contents = UIImage(systemName: "circle.fill")?.withTintColor(.white, renderingMode: .alwaysOriginal).cgImage
        cell.birthRate = 8
        cell.lifetime = 6
        cell.velocity = 40
        cell.velocityRange = 25
        cell.scale = 0.04
        cell.scaleRange = 0.02
        cell.alphaSpeed = -0.1

        emitter.emitterCells = [cell]
        layer.addSublayer(emitter)
    }

    private func addStarburstEmitter() {
        let emitter = CAEmitterLayer()
        emitter.emitterPosition = CGPoint(x: bounds.midX, y: bounds.midY)
        emitter.emitterShape = .circle
        emitter.emitterSize = CGSize(width: 5, height: 5)

        let cell = CAEmitterCell()
        cell.contents = UIImage(systemName: "star.fill")?.withTintColor(.yellow, renderingMode: .alwaysOriginal).cgImage
        cell.birthRate = 30
        cell.lifetime = 1.5
        cell.velocity = 180
        cell.velocityRange = 40
        cell.scale = 0.05
        cell.scaleSpeed = -0.02
        cell.alphaSpeed = -0.5

        emitter.emitterCells = [cell]
        layer.addSublayer(emitter)
    }

    private func addCirclePulse() {
        let circlePath = UIBezierPath(ovalIn: CGRect(x: bounds.midX-100, y: bounds.midY-100, width: 200, height: 200))
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = circlePath.cgPath
        shapeLayer.strokeColor = UIColor.white.cgColor
        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.lineWidth = 2
        layer.addSublayer(shapeLayer)

        let scale = CABasicAnimation(keyPath: "transform.scale")
        scale.fromValue = 0.5
        scale.toValue = 2.0
        scale.duration = 1.5
        scale.repeatCount = .infinity

        let fade = CABasicAnimation(keyPath: "opacity")
        fade.fromValue = 1
        fade.toValue = 0
        fade.duration = 1.5
        fade.repeatCount = .infinity

        let group = CAAnimationGroup()
        group.animations = [scale, fade]
        group.duration = 1.5
        group.repeatCount = .infinity

        shapeLayer.add(group, forKey: "pulse")
    }
}
