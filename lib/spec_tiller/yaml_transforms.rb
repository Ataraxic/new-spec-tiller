
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
