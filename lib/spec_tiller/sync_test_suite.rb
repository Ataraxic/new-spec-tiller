require 'yaml'
require 'pry'

class TravisYaml 

  def initialize(filepath:)
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


class YamlTransforms
  
  def initialize
    @transforms = {}
  end

  def register_line_transform(key, &func)
    if @transforms[key].nil?
      @transforms[key] = [func]
    else
      @transforms[key] << func
    end
  end

  # this is a bit big.
  def apply_transforms(data)
    data.map do |line|
      line.merge(@transforms.keys.map do |key|
        next if line[key].nil?
        func_list = @transforms[key]
        value = func_list.reduce(line[key]) do |accum, func|
          func.call(accum)
        end
        { key => value}
      end.compact.reduce({}, :merge))
    end
  end

  def flatten_dedup(list:, key:)
    list.reduce([]) do |accum, val|
      value = val[key] ? val[key] : []
      accum + value
    end
  end

  def add_specs(matrix:, specs_by_index:)
    map_by_key_with_index(matrix: matrix, key: 'TEST_SUITE') do |test_suite, i|
      next test_suite if specs_by_index[i].nil?
      test_suite ||= []
      test_suite = test_suite + specs_by_index[i] 
    end
  end

  def remove_specs(matrix:, specs:)
    map_by_key(key: 'TEST_SUITE', matrix: matrix) do |test_suite|
      test_suite - specs
    end
  end

  def rand_specs(specs:, num_builds:)
    specs_to_add_by_index = {}
    specs.each do |spec|
      index = rand(num_builds)
      specs_to_add_by_index[index] ||= []
      specs_to_add_by_index[index] << spec
    end
    specs_to_add_by_index
  end

  def remove_empty_test_suite(matrix)
    matrix.map do |line|
      val = line['TEST_SUITE']
      if val.nil?
        line
      else
        val.empty? ? line.tap { |h| h.delete('TEST_SUITE') } : line
      end
    end
  end

  def remove_empty_hash(matrix)
    matrix.map do |line|
      line unless line.empty?
    end.compact
  end

  def format_matrix(matrix:)
    map_by_key(matrix: matrix, key: 'TEST_SUITE') do |test_suite|
      test_suite.join(' ')
    end.map do |line|
      line.keys.map do |env_var|
        %(#{env_var}="#{line[env_var]}")
      end.join(', ')
    end
  end

  private

  def map_by_key(key:, matrix:, &block)
    matrix.map do |*args|
      line, *rest = *args
      next line if line[key].nil?
      new_line = line.clone
      new_line[key] = block.call(new_line[key].clone, *rest)
      new_line
    end
  end

  def map_by_key_with_index(key:, matrix:, &block)
    map_by_key(matrix: matrix.each_with_index, key: key, &block)
  end
end
