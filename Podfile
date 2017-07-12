platform :ios, '9.0'

target 'RealmTasksTutorial' do
  use_frameworks!

  pod 'RealmSwift'

  target 'RealmTasksTutorialTests' do
    inherit! :search_paths
    # Pods for testing
  end

end

plugin 'cocoapods-keys', {
  :project => 'RealmTasksTutorial',
  :keys => [
    "RealmUsername",
    "RealmPassword"
  ]
}
