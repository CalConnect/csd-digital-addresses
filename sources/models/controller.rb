require "yaml"
require "fileutils"
require "pp"

require File.expand_path("../plantuml_adaptor.rb", __FILE__)
require File.expand_path("../asciidoc_adaptor.rb", __FILE__)

ADOC_LEVEL = 2

TYPE_MAP = {
  "class" => "classes",
  "enum" => "enums",
}

def for_each_view
  yml_files = Dir.glob(File.expand_path("../views/*.yml", __FILE__))

  yml_files.each do |yml_file|
    yml = YAML.load_file(yml_file)

    view_hash = yml.merge({
      "classes" => {},
      "enums" => {},
      "relations" => [],
    })

    view_hash = yml["imports"].reduce(view_hash) do |acc, (model_name, model_hash)|
      model_yml = YAML.load_file(File.expand_path("../models/#{model_name}.yml", __FILE__))

      modelTypes = TYPE_MAP[model_yml["modelType"]]

      acc[modelTypes] = acc[modelTypes].merge({
        model_yml["name"] => model_yml
      })

      acc
    end

    file_match = yml_file.match(/(?<view_name>[^\/]+)\.yml\Z/)
    view_name = file_match[:view_name]

    yield(view_name, view_hash)
  end
end


def view_to_plantuml(view_name, yml)
  dir_name = File.expand_path("../plantuml", __FILE__)
  FileUtils.mkdir_p(dir_name)

  File.open("#{dir_name}/#{view_name}.wsd", "w") do |file|
    file.write(PlantumlAdaptor.yml_to_plantuml(yml))
  end
end

def view_to_adocs(view_name, yml)
  dir_name = File.expand_path("../adoc", __FILE__)
  FileUtils.mkdir_p(dir_name)

  File.open("#{dir_name}/#{view_name}.adoc", "w") do |file|
    adoc = AsciidocAdaptor.yml_to_asciidoc(
      yml,
      view_name,
      "../plantuml",
      ADOC_LEVEL
    )
    file.write(adoc)
  end
end

for_each_view do |view_name, view_hash|
  view_to_plantuml(view_name, view_hash)
  view_to_adocs(view_name, view_hash)
end
