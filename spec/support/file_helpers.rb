#:nodoc:
module FileHelpers
  def file_path(file)
    dir = File.expand_path("../../data", __FILE__)
    File.join(dir, file)
  end
end
