if defined?(ChefSpec)
  ChefSpec.define_matcher(:rdiff_backup)
  def create_rdiff_backup(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(
      :rdiff_backup,
      :create,
      resource_name
    )
  end
end
