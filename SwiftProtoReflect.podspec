Pod::Spec.new do |spec|
  spec.name          = "SwiftProtoReflect"
  spec.version       = "2.0.0"
  spec.summary       = "Dynamic Protocol Buffers for Swift"
  spec.description   = <<-DESC
                       Production-ready library for runtime Protocol Buffers message manipulation without pre-compiled .pb files.
                       Zero code generation, high performance, complete Protocol Buffers specification compliance.
                       DESC

  spec.homepage      = "https://github.com/truewebber/swift-protoreflect"
  spec.license       = { :type => "MIT", :file => "LICENSE" }
  spec.author        = { "truewebber" => "truewebber@users.noreply.github.com" }
  
  spec.swift_versions = ['5.9']
  spec.ios.deployment_target = "15.0"
  spec.osx.deployment_target = "12.0"
  
  spec.source        = { :git => "https://github.com/truewebber/swift-protoreflect.git", :tag => "#{spec.version}" }
  spec.source_files  = "Sources/SwiftProtoReflect/**/*.swift"
  
  spec.dependency "SwiftProtobuf", "~> 1.29"
  spec.dependency "gRPC-Swift", "~> 1.23"
  
  spec.requires_arc = true
end 