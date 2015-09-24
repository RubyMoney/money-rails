#:nodoc:
module FileHelpers
  def gem_path(name, version)
    gems_dir = File.expand_path("../../data/gems", __FILE__)
    gem_dir = File.join(gems_dir, name)
    File.join(gem_dir, "pkg/#{name}-#{version}.gem")
  end
end
