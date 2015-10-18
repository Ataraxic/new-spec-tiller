require 'yaml'
require 'pry'

class TravisYaml 

  def initialize(filepath:, spec_dir:)
    require 'yaml'
    @yaml = Yaml::Load(File.open(filepath))
    @build_matrix = generate_matrix(@yaml['env']['matrix'])
    @ignored_specs = get_ignored_specs(@yaml['env']['global'])
    @dir_file_list = files_in_dir(spec_dir)
  end

  def build_matrix 
    @build_matrix
  end

  def num_builds
    @yaml['num_builds']
  end

  def ignored_specs
    @ignored_specs
  end

  private

  def get_ignored_specs(global_vars)
    global_vars.map do |row|
      if row.is_a?(String)
        # Input: IGNORE_SPECS="spec/a.rb spec/b.rb"
        # Output: ['spec/a.rb spec/b.rb']
        matches = row.match(/IGNORE_SPECS="\s*([^"]+)"/)
        matches[1].split(' ') unless matches.nil?
      end
    end.compact.flatten
  end

  def files_in_dir(matcher)
    # what is the reason for this slice?
    Dir.glob(matcher).map { |file_path| file_path.slice(/(spec\/\S+$)/) }
  end

  def generate_matrix(matrix)
    # compact will remove empty lines from the matrix
    matrix.compact.map do |line|
      generate_hash(line)
    end
  end

  def generate_hash(line)
    # ',' is the required separator for env vars
    line.split(',').map do |env_var|
      separate_key_value(env_var)
    end.reduce({}, :merge)
  end

  def separate_key_value(env_var)
    key = /(\w+)=/.match(env_var)
    value = /\w+="(.*)"/.match(env_var)

    valid_env_var(key, value) ? { key[1] => value[1] } : {}
  end
end


class YamlTransforms
  
  def initialize
    @transforms = {}
  end

  def register_line_transform(key, &func)
    transforms = @transforms[key]
    transforms = transforms ? transforms << func : [func]
  end

  def apply_transforms(data)
    data.map do |line|
      @transforms.keys.map do |key, func|
        line[key] = func(line[key])
      end.reduce({}, :merge)
    end
  end
  

  def sync
    10
  end
  
  def self.read_travis_file(filepath)
    YAML::load(File.open(filepath))
  end

  def self.get_current_file_list(matcher)
    Dir.glob(matcher).map { |file_path| file_path.slice(/(spec\/\S+$)/) }
  end

  def self.num_builds(filepath)
    read_travis_file(filepath)['num_builds']
  end

  def self.transform(coll, matcher)
    coll.map(&matcher)
  end

  def self.get_build_matrix(filepath)
    matrix = read_travis_file(filepath)['env']['matrix']
    generate_hash_from_matrix(matrix)
  end

  def self.generate_hash_from_matrix(matrix)
    # compact will remove empty lines from the matrix
    matrix.compact.map do |line|
      generate_hash(line)
    end
  end

  def self.generate_hash(line)
    # ',' is the required separator for env vars
    line.split(',').map do |env_var|
      separate_key_value(env_var)
    end.reduce({}, :merge)
  end

  def self.separate_key_value(env_var)
    key = /(\w+)=/.match(env_var)
    value = /\w+="(.*)"/.match(env_var)

    valid_env_var(key, value) ? { key[1] => value[1] } : {}
  end

  def self.valid_env_var(key, val)
    (key.nil? || key[1].nil? || val.nil? || val[1].nil?) ? false : true
  end

  def self.get_ignored_specs(filepath)
    read_travis_file(filepath)['env']['global'].map do |row|
      if row.is_a?(String)
        # Input: IGNORE_SPECS="spec/a.rb spec/b.rb"
        # Output: ['spec/a.rb spec/b.rb']
        matches = row.match(/IGNORE_SPECS="\s*([^"]+)"/)
        matches[1].split(' ') unless matches.nil?
      end
    end.compact.flatten
  end

  
  
  def error_message()
    
  end
end
