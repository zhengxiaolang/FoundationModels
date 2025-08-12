//
//  QRCodeGenerator.swift
//  appleAI
//
//  Created by AI Assistant on 2025/8/12.
//

import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

// MARK: - 本地二维码生成器
class QRCodeGenerator {
    
    /// 生成二维码图片
    /// - Parameters:
    ///   - text: 要编码的文本
    ///   - size: 二维码尺寸
    ///   - correctionLevel: 错误纠正级别
    /// - Returns: 生成的二维码图片
    static func generateQRCode(
        from text: String,
        size: CGSize = CGSize(width: 200, height: 200),
        correctionLevel: QRCorrectionLevel = .medium
    ) -> UIImage? {

        guard !text.isEmpty else { return nil }

        // 直接使用最简单的方法
        return generateBasicQRCode(from: text)
    }

    /// 简化的二维码生成方法，用于测试
    static func generateSimpleQRCode(from text: String) -> UIImage? {
        guard !text.isEmpty else {
            print("QRCodeGenerator Simple: Empty text")
            return nil
        }

        print("QRCodeGenerator Simple: Generating QR for: \(text)")

        let data = text.data(using: .utf8)

        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            filter.setValue("M", forKey: "inputCorrectionLevel")

            if let outputImage = filter.outputImage {
                print("QRCodeGenerator Simple: Output image extent: \(outputImage.extent)")

                let context = CIContext()

                // 使用更安全的缩放方式
                let originalSize = outputImage.extent.size
                guard originalSize.width > 0 && originalSize.height > 0 else {
                    print("QRCodeGenerator Simple: Invalid original size")
                    return nil
                }

                // 固定缩放到200x200
                let targetSize: CGFloat = 200
                let scaleX = targetSize / originalSize.width
                let scaleY = targetSize / originalSize.height
                let scale = min(scaleX, scaleY)

                print("QRCodeGenerator Simple: Scale: \(scale)")

                let transform = CGAffineTransform(scaleX: scale, y: scale)
                let scaledImage = outputImage.transformed(by: transform)

                print("QRCodeGenerator Simple: Scaled image extent: \(scaledImage.extent)")

                if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                    print("QRCodeGenerator Simple: Successfully created CGImage")
                    return UIImage(cgImage: cgImage)
                } else {
                    print("QRCodeGenerator Simple: Failed to create CGImage")
                }
            } else {
                print("QRCodeGenerator Simple: Failed to get output image")
            }
        } else {
            print("QRCodeGenerator Simple: Failed to create filter")
        }

        return nil
    }

    /// 最简单的二维码生成方法 - 使用苹果官方API
    static func generateBasicQRCode(from text: String) -> UIImage? {
        guard !text.isEmpty else {
            print("QRCodeGenerator: Text is empty")
            return nil
        }

        print("QRCodeGenerator: Generating QR for: \(text)")

        let data = Data(text.utf8)

        guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
            print("QRCodeGenerator: Failed to create filter")
            return nil
        }

        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")

        guard let qrCodeImage = filter.outputImage else {
            print("QRCodeGenerator: Failed to get output image")
            return nil
        }

        let context = CIContext()
        let transform = CGAffineTransform(scaleX: 10, y: 10)
        let output = qrCodeImage.transformed(by: transform)

        guard let cgimg = context.createCGImage(output, from: output.extent) else {
            print("QRCodeGenerator: Failed to create CGImage")
            return nil
        }

        let uiImage = UIImage(cgImage: cgimg)
        print("QRCodeGenerator: Successfully generated QR code")
        return uiImage
    }
    
    /// 生成带Logo的二维码
    /// - Parameters:
    ///   - text: 要编码的文本
    ///   - logo: 中心Logo图片
    ///   - size: 二维码尺寸
    ///   - logoSize: Logo尺寸
    /// - Returns: 带Logo的二维码图片
    static func generateQRCodeWithLogo(
        from text: String,
        logo: UIImage,
        size: CGSize = CGSize(width: 200, height: 200),
        logoSize: CGSize = CGSize(width: 40, height: 40)
    ) -> UIImage? {
        
        guard let qrImage = generateQRCode(from: text, size: size) else { return nil }
        
        // 创建图形上下文
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }
        
        // 绘制二维码
        qrImage.draw(in: CGRect(origin: .zero, size: size))
        
        // 计算Logo位置（居中）
        let logoRect = CGRect(
            x: (size.width - logoSize.width) / 2,
            y: (size.height - logoSize.height) / 2,
            width: logoSize.width,
            height: logoSize.height
        )
        
        // 绘制白色背景（为Logo提供背景）
        UIColor.white.setFill()
        let backgroundRect = logoRect.insetBy(dx: -4, dy: -4)
        UIBezierPath(roundedRect: backgroundRect, cornerRadius: 4).fill()
        
        // 绘制Logo
        logo.draw(in: logoRect)
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    /// 验证文本是否适合生成二维码
    /// - Parameter text: 要验证的文本
    /// - Returns: 验证结果
    static func validateText(_ text: String) -> QRValidationResult {
        if text.isEmpty {
            return .invalid("文本不能为空")
        }
        
        if text.count > 2953 {
            return .invalid("文本过长，最多支持2953个字符")
        }
        
        // 简化验证逻辑，大部分字符都可以用于二维码
        return .valid
    }
}

// MARK: - 支持类型

/// 二维码错误纠正级别
enum QRCorrectionLevel: String, CaseIterable {
    case low = "L"      // 约7%的错误纠正能力
    case medium = "M"   // 约15%的错误纠正能力
    case quartile = "Q" // 约25%的错误纠正能力
    case high = "H"     // 约30%的错误纠正能力
    
    var displayName: String {
        switch self {
        case .low: return "低 (7%)"
        case .medium: return "中 (15%)"
        case .quartile: return "高 (25%)"
        case .high: return "最高 (30%)"
        }
    }
}

/// 二维码验证结果
enum QRValidationResult {
    case valid
    case warning(String)
    case invalid(String)
    
    var isValid: Bool {
        switch self {
        case .valid, .warning: return true
        case .invalid: return false
        }
    }
    
    var message: String? {
        switch self {
        case .valid: return nil
        case .warning(let msg), .invalid(let msg): return msg
        }
    }
}

// MARK: - SwiftUI 视图扩展

struct QRCodeView: View {
    let text: String
    let size: CGSize
    let correctionLevel: QRCorrectionLevel
    
    @State private var qrImage: UIImage?
    @State private var isLoading = false
    
    init(text: String, size: CGSize = CGSize(width: 200, height: 200), correctionLevel: QRCorrectionLevel = .medium) {
        self.text = text
        self.size = size
        self.correctionLevel = correctionLevel
    }
    
    var body: some View {
        Group {
            if let image = qrImage {
                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size.width, height: size.height)
            } else if isLoading {
                ProgressView()
                    .frame(width: size.width, height: size.height)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: size.width, height: size.height)
                    .overlay(
                        Text("无法生成二维码")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    )
            }
        }
        .onAppear {
            generateQRCode()
        }
        .onChange(of: text) { _ in
            generateQRCode()
        }
    }
    
    private func generateQRCode() {
        guard !text.isEmpty else {
            qrImage = nil
            isLoading = false
            return
        }

        isLoading = true

        DispatchQueue.global(qos: .userInitiated).async {
            let image = QRCodeGenerator.generateQRCode(
                from: self.text,
                size: self.size,
                correctionLevel: self.correctionLevel
            )

            DispatchQueue.main.async {
                self.qrImage = image
                self.isLoading = false
                print("QR Code generated for text: \(self.text), image: \(image != nil ? "success" : "failed")")
            }
        }
    }
}

// MARK: - 预览

#Preview {
    VStack(spacing: 20) {
        // 测试基础二维码生成
        if let qrImage = QRCodeGenerator.generateBasicQRCode(from: "Hello, World!") {
            Image(uiImage: qrImage)
                .interpolation(.none)
                .frame(width: 150, height: 150)
        } else {
            Text("QR Code generation failed")
        }

        // 测试URL
        if let qrImage = QRCodeGenerator.generateBasicQRCode(from: "https://apple.com") {
            Image(uiImage: qrImage)
                .interpolation(.none)
                .frame(width: 150, height: 150)
        } else {
            Text("URL QR Code generation failed")
        }
    }
    .padding()
}
