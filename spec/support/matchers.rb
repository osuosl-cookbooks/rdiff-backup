if defined?(ChefSpec)
  ChefSpec.define_matcher(:rdiff_backup)

  def remove_nrpe_check(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(
      :nrpe_check,
      :remove,
      resource_name
    )
  end

  def add_nrpe_check(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(
      :nrpe_check,
      :add,
      resource_name
    )
  end
end
