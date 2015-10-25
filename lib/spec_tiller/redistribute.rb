relative_require 'travis_api'

class Redistribute
  def initialize(yaml)
    @yaml = yaml
  end

  def write_yaml
    @yaml.rewrite_matrix()
  end

  
  def fuzz_times(seed:, spec_list:)
    srand(seed)
    spec_list.map do |spec|
      new_spec = spec.clone
      new_spec[:duration] = rand_duration(new_spec[:duration])
      new_spec
    end.sort_by { |spec| spec[:duration] }
  end

  # spec_list must be sorted by duration
  def distribute(spec_list, num_builds)
    list = spec_list.clone
    time = Array.new(num_builds)
    matrix = Array.new(num_builds).map { |_| [] }
    
    while list.length > 0
      matrix[min_index(matrix)] << list.shift
    end
    matrix
  end

  private

  def min_index(list)
    list.sort { |a,b| b <=> a }
  end

  MOD_PERCENTAGE = 20

  def rand_duration(duration)
    mod_value = (duration * (rand / MOD_PERCENTAGE))
    add = (rand >= 0.5)
    add ? duration + mod_value : duration - mod_value
  end
end

class SpecParser
  def initialize(build_log)
    @spec_list = parse_profile_results(@build_log)
  end

  private

  PROFILE_REGEX = /\s{1}\(([0-9\.]*\s).*\.\/(spec.*):/

  def parse_profile_results(build_log)
    build_log.
      scan(PROFILE_REGEX).
      uniq { |spec| spec.last }.
      map do |spec|
      {
       :duration => spec.first.strip.to_f,
       :filepath => spec.last
      }
    end.sort_by do |spec| spec[:duration] end
  end
end
