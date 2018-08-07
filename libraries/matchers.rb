if defined?(ChefSpec)
  def create_rdiff_backup(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(
      :rdiff_backup,
      :create,
      resource_name
    )
  end

  def delete_rdiff_backup(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(
      :rdiff_backup,
      :delete,
      resource_name
    )
  end

  def create_sudo(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(
      :sudo,
      :create,
      resource_name
    )
  end
end
