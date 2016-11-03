if defined?(ChefSpec)
  ChefSpec.define_matcher(:rdiff_backup)
  def create_rdiff_backup(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(
      :rdiff_backup,
      :create,
      resource_name
    )
  end
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
  def create_ssh_user(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(
      :ssh_user_private_key,
      :create,
      resource_name
    )
  end
end
