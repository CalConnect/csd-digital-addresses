require "yaml"
require "fileutils"
require "pp"

require File.expand_path("../plantuml_adaptor.rb", __FILE__)
require File.expand_path("../asciidoc_adaptor.rb", __FILE__)

ADOC_LEVEL = 2

def for_each_yml
  yml_files = Dir.glob(File.expand_path("../*.yml", __FILE__))

  yml_files.each do |yml_file|
    file_match = yml_file.match(/(?<model_name>[^\/]+)\.yml\Z/)
    model_name = file_match[:model_name]
    yml = YAML.load_file(yml_file)

    yield(model_name, yml)
  end
end

def yml_to_plantuml(model_name, yml)
  dir_name = File.expand_path("../plantuml", __FILE__)
  FileUtils.mkdir_p(dir_name)

  File.open("#{dir_name}/#{model_name}.wsd", "w") do |file|
    file.write(PlantumlAdaptor.yml_to_plantuml(yml))
  end
end

def yml_to_adocs(model_name, yml)
  dir_name = File.expand_path("../adoc", __FILE__)
  FileUtils.mkdir_p(dir_name)

  File.open("#{dir_name}/#{model_name}.adoc", "w") do |file|
    adoc = AsciidocAdaptor.yml_to_asciidoc(
      yml,
      model_name,
      "../plantuml",
      ADOC_LEVEL
    )
    file.write(adoc)
  end
end

for_each_yml do |model_name, yml|
  yml_to_plantuml(model_name, yml)
  yml_to_adocs(model_name, yml)
end
