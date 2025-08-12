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

        guard !text.isEmpty else {
            print("QRCodeGenerator: Empty text provided")
            return nil
        }

        print("QRCodeGenerator: Generating QR code for text: \(text)")

        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()

        // 设置输入数据
        filter.message = Data(text.utf8)

        // 设置错误纠正级别
        filter.correctionLevel = correctionLevel.rawValue

        // 获取生成的二维码图片
        guard let outputImage = filter.outputImage else {
            print("QRCodeGenerator: Failed to generate output image")
            return nil
        }

        // 计算缩放比例
        let scaleX = size.width / outputImage.extent.width
        let scaleY = size.height / outputImage.extent.height
        let scale = min(scaleX, scaleY)

        // 缩放图片
        let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        // 转换为UIImage
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else {
            print("QRCodeGenerator: Failed to create CGImage")
            return nil
        }

        let uiImage = UIImage(cgImage: cgImage)
        print("QRCodeGenerator: Successfully generated QR code image")
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
        QRCodeView(text: "Hello, World!")
        QRCodeView(text: "https://apple.com", size: CGSize(width: 150, height: 150))
    }
    .padding()
}
