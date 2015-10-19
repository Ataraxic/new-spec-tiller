require 'yaml'
require 'pry'

class TravisYaml 
  def initialize(filepath:)
    @filepath = filepath
    @yaml = YAML.load(File.open(filepath))
    @build_matrix = generate_matrix(@yaml['env']['matrix'])
    @ignored_specs = get_ignored_specs(@yaml['env']['global'])
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

  def rewrite_matrix(matrix)
    @yaml['env']['matrix'] = matrix
    File.open('another_travis.yml', 'w') { |file| file.write(@yaml.to_yaml(:line_width => -1)) }
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

  def valid_env_var(key, val)
    (key.nil? || key[1].nil? || val.nil? || val[1].nil?) ? false : true
  end
end

