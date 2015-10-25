

class SpecTiller
  def initialize(travis_path:, spec_dir:)
    @yaml = TravisYaml.new(filepath: travis_path)
    @current_specs = current_specs(glob)
    @working_matrix = @yaml.build_matrix.slice(0..@yaml.num_builds)
    @ignored_lines = @yaml.build_matrix.slice(@yaml.num_builds..-1)
  end
  
  def sync
    Pipe.
      new(@working_matrix).
      pipe(
           lambda do |matrix|
             
           end
          )
    
  end

  def redistribute

  end

  private

  def current_specs(glob)
    Dir.glob(glob).map { |file_path| file_path.slice(/(spec\/\S+$)/) }
  end
end


class Pipe
  def initialize(value)
    @value
  end

  def pipe(func)
    Pipe.new(func.call(@value))
  end
end
