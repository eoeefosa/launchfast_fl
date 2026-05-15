
require 'xcodeproj'
project_path = 'ios/Runner.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Find and remove the Swift Package Reference
package_ref = project.root_object.package_references.find { |ref| ref.repositoryURL == 'https://github.com/firebase/firebase-ios-sdk' }

if package_ref
  puts "Found Firebase SPM reference, removing..."
  
  # Remove product dependencies from all targets
  project.targets.each do |target|
    target.package_product_dependencies.delete_if { |dep| dep.package == package_ref }
  end
  
  # Remove the package reference itself
  project.root_object.package_references.delete(package_ref)
  
  # Also remove from Frameworks build phase
  project.targets.each do |target|
    frameworks_phase = target.frameworks_build_phase
    frameworks_phase.files.delete_if { |file| file.product_ref && file.product_ref.respond_to?(:package) && file.product_ref.package == package_ref }
  end

  project.save
  puts "Successfully removed Firebase SPM reference."
else
  puts "Firebase SPM reference not found."
end
