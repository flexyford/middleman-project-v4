require "lib/ember_helpers"

###
# Page options, layouts, aliases and proxies
###

# Per-page layout changes:
#
# With no layout
page '/*.xml', layout: false
page '/*.json', layout: false
page '/*.txt', layout: false

# With alternative layout
# page "/path/to/file.html", layout: :otherlayout

# Proxy pages (http://middlemanapp.com/basics/dynamic-pages/)
# proxy "/this-page-has-no-template.html", "/template-file.html", locals: {
#  which_fake_page: "Rendering a fake page with a local variable" }

###
# Helpers
###

activate :ember

##
# Helpers are available in all template.
#
# Each helper runs in the context of the `Middleman::Application`
helpers do
  ##
  # Generate Ember stylesheet link tags.
  #
  # This consists of the vendor.css and app.css. Call from within a template
  # to bring in all the styles from the ember.
  #
  #   <% content_for :head do %>
  #     <%= ember_stylesheet_link_tags "my-sweet-ember-app" %>
  #   <% end %>
  def ember_stylesheet_link_tags(app_name)
    with_ember_app(app_name) do |ember_app|
      <<-EOS
    <link rel="stylesheet" href="#{url_for ember_app.vendor_css}"/>
    <link rel="stylesheet" href="#{url_for ember_app.app_css}"/>
EOS
    end
  end

  ##
  # Generate Ember stylesheet link tags.
  #
  # This consists of the vendor.css and app.css. Call from within a template
  # bring in all the styles from ember.
  #
  #   <% content_for :foot do %>
  #     <%= ember_stylesheet_link_tags "my-sweet-ember-app" %>
  #   <% end %>
  def ember_javascript_tags(app_name)
    with_ember_app(app_name) do |ember_app|
      <<-EOF
      <script src="#{url_for ember_app.vendor_js}"></script>
      <script src="#{url_for ember_app.app_js}"></script>
EOF
    end
  end

  ##
  # Helpers are mixed into the Middleman::Application class,
  # so we need to provide a way to access the ember app
  # extensions from there.
  def with_ember_app(app_name, &block)
    extensions[:ember].with_ember_app(app_name, &block)
  end
end

activate :blog do |blog|
  # This will add a prefix to all links, template references and source paths
  # blog.prefix = "blog"

  blog.permalink = "{year}/{month}/{day}/{title}.html"
  # Matcher for blog source files
  blog.sources = "{year}-{month}-{day}-{title}.html"
  blog.taglink = "tags/{tag}.html"
  # blog.layout = "layout"
  # blog.summary_separator = /(READMORE)/
  blog.summary_length = 250
  blog.year_link = "{year}.html"
  blog.month_link = "{year}/{month}.html"
  blog.day_link = "{year}/{month}/{day}.html"
  blog.default_extension = ".markdown"

  blog.tag_template = "tag.html"
  blog.calendar_template = "calendar.html"

  # Enable pagination
  # blog.paginate = true
  # blog.per_page = 10
  # blog.page_link = "page/{num}"
end

page "/feed.xml", layout: false
# Reload the browser automatically whenever files change
# configure :development do
#   activate :livereload
# end

# Build-specific configuration
configure :build do
  # Minify CSS on build
  # activate :minify_css

  # Minify Javascript on build
  # activate :minify_javascript
end
