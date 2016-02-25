module ProjectsHelper

  def jvm_project? project
    return false if project.nil? || project.language.to_s.empty?

    project.language.eql?( Product::A_LANGUAGE_JAVA ) ||
    project.project_type.to_s.eql?(Project::A_TYPE_MAVEN2) ||
    project.project_type.to_s.eql?(Project::A_TYPE_SBT) ||
    project.project_type.to_s.eql?(Project::A_TYPE_GRADLE)
  end

  def outdated_color project
    return 'red' if project[:out_number_sum].to_i > 0
    'green'
  end

  def unknown_color project
    return 'orange' if project[:unknown_number_sum].to_i > 0
    'green'
  end

  def licenses_red_color project
    return 'red' if project[:licenses_red_sum].to_i > 0
    'green'
  end

  def licenses_color sum
    return 'red' if sum.to_i > 0
    'green'
  end

  def licenses_unknown_color project
    return 'orange' if project[:licenses_unknown_sum].to_i > 0
    'green'
  end

  def subproject_label_color selected_id, sub_id
    return 'success' if selected_id.eql?('summary')
    return 'success' if selected_id.eql?(sub_id)
    'default'
  end

  def subproject_name( project )
    name = project.filename
    if name.to_s.empty?
      name = project.name
    end
    name
  end

  def path_to_stash_file project
    repo = project.scm_fullname.gsub("/", "/repos/")
    branch = URI.encode("refs/heads/#{project.scm_branch}")
    "#{Settings.instance.stash_base_url}/projects/#{repo}/browse/#{project.filename}?at=#{branch}"
  end

  def path_to_bitbucket_branch project
    "https://bitbucket.org/#{project.scm_fullname}/branch/#{project.scm_branch}"
  end

  def path_to_bitbucket_file project
    "https://api.bitbucket.org/1.0/repositories/#{project.scm_fullname}/raw/#{project.scm_revision}/#{project.filename}"
  end

  def path_to_github_branch project
    "#{Settings.instance.github_base_url}/#{project.scm_fullname}/tree/#{project.scm_branch}"
  end

  def path_to_github_file project
    "#{Settings.instance.github_base_url}/#{project.scm_fullname}/blob/#{project.scm_branch}/#{project.filename}"
  end

  def project_member?(project, user)
    return false if project.nil?
    return false if user.nil?

    return true if user.admin == true
    return true if project.user && project.user.ids.eql?( user.ids )
    return true if project.is_collaborator?( user )

    return false
  end

  def add_dependency_classes project
    return nil if project.nil?

    deps = nil
    if project.is_a? Hash
      deps = project[:dependencies]
    else
      deps = project.dependencies
    end
    return project if deps.nil? or deps.empty?

    out_number = 0
    unknown_number = 0

    deps.each do |dep|
      if dep.unknown?
        dep[:status_class] = 'info'
        dep[:status_rank] = 3
        unknown_number += 1
      elsif dep.outdated and dep.release? == false
        dep[:status_class] = 'warning'
        dep[:status_rank] = 2
        out_number += 1
      elsif dep.outdated and dep.release? == true
        dep[:status_class] = 'error'
        dep[:status_rank] = 1
        out_number += 1
      else
        dep[:status_class] = 'success'
        dep[:status_rank] = 4
      end
    end
    project
  end

  def merge_to_projects project
    if project.organisation
      return merge_to_user_or_orga_projects project, project.organisation.projects
    else
      return merge_to_user_or_orga_projects project, current_user.projects
    end
  end

  def merge_to_user_or_orga_projects project, projects
    projs = []
    parents = []
    singles = []
    projects.each do |pro|
      next if pro.id.to_s.eql?(project.id.to_s)
      next if pro.parent_id
      if pro.children.count > 0
        pro.has_kids = 1
        parents << pro
      else
        pro.has_kids = 0
        singles << pro
      end
    end
    parents = parents.sort_by {|obj| obj.name}
    singles = singles.sort_by {|obj| obj.name}
    projs << parents
    projs << singles
    projs.flatten
  end

end
