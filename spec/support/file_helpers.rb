require "fileutils"

# Helper methods to easily find and manipulate test files.
module FileHelpers
  def gem_path(name, version)
    gems_dir = File.expand_path("../../data/gems", __FILE__)
    gem_dir = File.join(gems_dir, name)
    File.join(gem_dir, "pkg/#{name}-#{version}.gem")
  end

  def bundle_path(name)
    bundles_dir = File.expand_path("../../data/bundles", __FILE__)
    File.join(bundles_dir, name)
  end

  def clean_bundle(name)
    dir = bundle_path(name)
    File.delete File.join(dir, "Gemfile.lock")
    FileUtils.remove_entry File.join(dir, "installed_gems")
  end
end
