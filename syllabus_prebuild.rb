#!/usr/bin/env ruby
require 'json'
require 'pathname'
require 'yaml'
require 'liquid'

ROOT = Pathname.new(__dir__).realpath
CONFIG_PATH = ROOT.join('_config.yml')
SYLLABUS_PATH = ROOT.join('syllabus.md')
DEFAULT_OUTPUT_PATH = ROOT.join('syllabus_rendered.md')

def load_structured_file(path)
  case path.extname
  when '.yml', '.yaml'
    YAML.load_file(path, aliases: true)
  when '.json'
    JSON.parse(path.read(encoding: 'UTF-8'))
  else
    nil
  end
end

def load_site_data(root)
  data = {}

  Dir[root.join('_data', '*').to_s].sort.each do |entry|
    path = Pathname.new(entry)
    next unless path.file?

    key = path.basename(path.extname).to_s
    data[key] = load_structured_file(path)
  end

  data
end

def extract_front_matter(content)
  parts = content.split(/^---\s*$/, 3)
  raise 'syllabus.md is missing YAML front matter' if parts.length < 3

  [parts[1], parts[2]]
end

def rewrite_local_asset_paths(rendered, baseurl)
  normalized_baseurl = baseurl.to_s.sub(%r{/\z}, '')
  asset_prefix = normalized_baseurl.empty? ? '/assets/' : "#{normalized_baseurl}/assets/"

  rendered.gsub(asset_prefix, 'assets/')
end

def build_pandoc_metadata(page_data, site_config)
  author = site_config['author']
  author_name = author['name'] if author.is_a?(Hash)

  if author_name.to_s.empty?
    raise '_config.yml author must be a mapping with a non-empty name'
  end

  metadata = page_data.merge('author' => author_name)
  metadata['date'] = site_config['date'] if site_config['date']
  metadata
end

def serialize_front_matter(data)
  YAML.dump(data).sub(/\A---\s*\n/, '').strip
end

output_path = if ARGV[0]
                Pathname.new(ARGV[0]).expand_path(Dir.pwd)
              else
                DEFAULT_OUTPUT_PATH
              end

site_config = YAML.load_file(CONFIG_PATH, aliases: true)
site_data = load_site_data(ROOT)

content = SYLLABUS_PATH.read(encoding: 'UTF-8')
front_matter, body = extract_front_matter(content)
page_data = YAML.safe_load(front_matter, aliases: true) || {}
pandoc_metadata = build_pandoc_metadata(page_data, site_config)

template = Liquid::Template.parse(body)
context = { 'site' => site_config.merge('data' => site_data), 'page' => page_data }
rendered = template.render(context)
rendered = rewrite_local_asset_paths(rendered, site_config['baseurl'])

File.open(output_path, 'w:UTF-8') do |file|
  file.puts '---'
  file.puts serialize_front_matter(pandoc_metadata)
  file.puts '---'
  file.puts rendered
end

puts "Rendered Markdown written to #{output_path}"
