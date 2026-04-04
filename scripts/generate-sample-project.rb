#!/usr/bin/env ruby

require 'fileutils'
require 'xcodeproj'

ROOT_DIR = File.expand_path('..', __dir__)
SAMPLE_DIR = File.join(ROOT_DIR, 'Examples', 'MeshKitSample')
PROJECT_PATH = File.join(SAMPLE_DIR, 'MeshKitSample.xcodeproj')
SOURCES_DIR = File.join(SAMPLE_DIR, 'Sources')

FileUtils.rm_rf(PROJECT_PATH)
FileUtils.mkdir_p(SOURCES_DIR)

project = Xcodeproj::Project.new(PROJECT_PATH)
project.root_object.attributes['LastSwiftUpdateCheck'] = '2600'
project.root_object.attributes['LastUpgradeCheck'] = '2600'

sources_group = project.main_group.new_group('Sources', 'Sources')
app_target = project.new_target(:application, 'MeshKitSample', :ios, '14.0', project.products_group, :swift)

# The sample links MeshKit through SwiftPM, so it does not need a hard-coded
# platform SDK framework reference in the Link Binary With Libraries phase.
app_target.frameworks_build_phase.clear

local_package = project.new(Xcodeproj::Project::Object::XCLocalSwiftPackageReference)
local_package.relative_path = '../..'
project.root_object.package_references << local_package

meshkit_product = project.new(Xcodeproj::Project::Object::XCSwiftPackageProductDependency)
meshkit_product.package = local_package
meshkit_product.product_name = 'MeshKit'
app_target.package_product_dependencies << meshkit_product

package_build_file = project.new(Xcodeproj::Project::Object::PBXBuildFile)
package_build_file.product_ref = meshkit_product
app_target.frameworks_build_phase.files << package_build_file

Dir.children(SOURCES_DIR).sort.grep(/\.swift$/).each do |filename|
    file_reference = sources_group.new_file(filename)
    app_target.source_build_phase.add_file_reference(file_reference)
end

project.build_configurations.each do |configuration|
    configuration.build_settings['CLANG_ENABLE_MODULES'] = 'YES'
    configuration.build_settings['PRODUCT_NAME'] = '$(TARGET_NAME)'
    configuration.build_settings['SWIFT_VERSION'] = '5.9'
end

app_target.build_configurations.each do |configuration|
    settings = configuration.build_settings

    settings.delete('ASSETCATALOG_COMPILER_APPICON_NAME')
    settings.delete('ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME')
    settings['CODE_SIGN_STYLE'] = 'Automatic'
    settings['CURRENT_PROJECT_VERSION'] = '1'
    settings['GENERATE_INFOPLIST_FILE'] = 'YES'
    settings['INFOPLIST_KEY_UIApplicationSceneManifest_Generation'] = 'YES'
    settings['INFOPLIST_KEY_UIApplicationSupportsIndirectInputEvents'] = 'YES'
    settings['INFOPLIST_KEY_UILaunchScreen_Generation'] = 'YES'
    settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
    settings['LD_RUNPATH_SEARCH_PATHS'] = [
        '$(inherited)',
        '@executable_path/Frameworks',
        '@loader_path/Frameworks',
    ]
    settings['MACOSX_DEPLOYMENT_TARGET'] = '11.0'
    settings['MARKETING_VERSION'] = '1.0'
    settings['PRODUCT_BUNDLE_IDENTIFIER'] = 'io.meshkit.MeshKitSample'
    settings['PRODUCT_NAME'] = '$(TARGET_NAME)'
    settings['SDKROOT'] = 'auto'
    settings['SUPPORTED_PLATFORMS'] = 'iphoneos iphonesimulator macosx'
    settings['SUPPORTS_MACCATALYST'] = 'YES'
    settings['SWIFT_VERSION'] = '5.9'
    settings['TARGETED_DEVICE_FAMILY'] = '1,2'
end

project.predictabilize_uuids
project.save

pbxproj_path = File.join(PROJECT_PATH, 'project.pbxproj')
pbxproj_contents = File.read(pbxproj_path)

pbxproj_contents.gsub!(/\n\s+DERIVE_MACCATALYST_PRODUCT_BUNDLE_IDENTIFIER = YES;/, '')

File.write(pbxproj_path, pbxproj_contents)
