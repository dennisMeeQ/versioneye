class PythonSetupParser < RequirementsParser
  def parse(url)
    response = fetch_response(url)
    doc = response.body
    return nil if doc.nil? or doc.empty? 

    requirements = parse_requirements(doc)
    extras = parse_extras(doc)
    project = Project.new 
    project.dependencies = []

    requirements.each do |requirement|
      requirement = requirement.strip
      next if requirement.nil? or requirement.empty?

      comparator = get_splitter requirement
      package, version = requirement.split(comparator)
          
      key = "pip/#{package}".strip 
      product = Product.find_by_key_case_insensitiv key
      project.unknown_number + 1 if product.nil?

      dependency = Projectdependency.new name: package.strip,
                                         prodkey: key,
                                         version_label: "#{version}".strip,
                                         comperator: comparator,
                                         scope: "compile"
      
      parse_requested_version(comparator, version, dependency, product)
      dependency.update_outdated
  
      project.dependencies << dependency
    end

    project.dep_number = project.dependencies.count
    project.project_type = Project::A_TYPE_PIP
    project.url = url

    project
  end

  def from_file()
    doc_file = File.new "test/files/setup.py"
    doc_file.read
  end
  
  def parse_requirements(doc)
    return nil if doc.nil? or doc.empty?
    req_text = slice_content doc, 'install_requires', '[', ']', false
    req_text.gsub! /[\'|\"]+/, ""
    req_text.split ','
  end

  def parse_extras(doc)
    return nil if doc.nil? or doc.empty?
    extras_txt = slice_content doc, 'extras_require', '{', '}', true 
    extras_txt
  end

  def slice_content(doc, keyword, start_matcher, end_matcher, include_matchers = false)
    return nil if doc.nil? or doc.empty?

    content_pos = doc.index keyword
    start_pos = doc.index start_matcher, content_pos
    end_pos =  doc.index end_matcher, content_pos

    block_length = (end_pos - start_pos) + 1
    if include_matchers 
      req_txt = doc.slice start_pos, block_length
    else
      req_txt = doc.slice(start_pos + 1, block_length - 2)
    end

    #clean up
    req_txt.gsub! /\#.*[^\n]$/, " " #remove python inline commens
    req_txt.gsub! /\s+/, " " #remove redutant spacer

    req_txt
  end

end
