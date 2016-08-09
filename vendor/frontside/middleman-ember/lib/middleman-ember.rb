require 'middleman-core'
require 'pathname'
require 'json'

##
# This is our friendly litle ember extension for maintaining
# ember applications that are used within the site. It ensures that the
# ember-cli app is built on deploy, and then provides template helpers so
# that you can include the ember app from pages within the site.
class MiddlemanEmber < ::Middleman::Extension

  ##
  # Hook that is run after middleman is finished with its
  # configuration phase, but before its build phase.
  #
  # Here we ignore most of the ember sources so that file watching remains
  # efficient. Also, we build each ember app if it hasn't been built yet. In
  # development mode, this means that the ember app is only built once, and so
  # if you want to build it again, then you'll have to do so with ember-cli
  # from the command line.
  #
  # In the CI/Production build it will get built every time because it starts
  # with a fresh checkout.
  #
  # @!method after_configuration invoked by middleman after `config.rb` is run
  def after_configuration
    # app.config[:file_watcher_ignore] << %r{^ember-apps/.+/(node_modules|bower_components|app|tests|tmp|public|config)} #
    ember_apps.each do |a|
      puts "#{a.name} is built -  #{a.built?}"
      a.build! unless a.built?
    end
  end

  ##
  # Looks up the instance of `MiddlemanEmber::EmbeApp` correpsonding
  # to `app_name` and yields it.
  #
  # If your ember app is in `ember-apps/my-ember-app`, then you would use it
  # like so:
  #
  #   with_ember_app "my-ember-app" do |ember_app|
  #     # do the fun stuff
  #   end
  # @!method with_ember_app(app_name)
  #   @param app_name [String] base name of the app's directory
  def with_ember_app(app_name)
    app = ember_apps.find { |a| a.dir.basename.to_s == app_name }
    fail "unable to find Ember app in 'ember-apps/#{app_name}'" unless app
    yield app
  end

  ##
  # Adds the ember applications resources to the list of files that form the
  # site.
  #
  # The heart of a middleman app is the Sitemap which is basically a list of
  # `Middleman::Sitemap::Resource` objects that contain information about a file
  # where its source lies on disk, and where it should be placed in the built
  # site along with anything transformations it should undergo before it is
  # placed at its final destination.
  #
  # This method is a hook defined by Middleman that receives the list of
  # resources in the site that can then be added to, or filtered. In this case
  # we add all of the ember resources like vendor.css, vendor.js and friends.
  #
  # @param resources [Array<Middleman::Sitemap::Resource] all site resources
  # @return [Array<Middleman::Sitemap::Resource] site resources augmented with
  #   ember resources.
  def manipulate_resource_list(resources)
    ember_apps.reduce(resources) do |list, ember_app|
      list + ember_app.middleman_resources
    end
  end

  ##
  # All ember apps in the site under the `/ember-apps` directory.
  #
  # @!attribute ember_apps
  #   @return [Array<EmberApp>] list of apps in this site
  def ember_apps
    ember_app_dirs.map { |d| EmberApp.new(@app, d) }
  end

  ##
  # All of the ember app directories in the site
  #
  # @!attribute ember_app_dirs
  #   @return [Array<Pathname>] the directories containing ember apps.
  def ember_app_dirs
    Pathname(@app.root).join("ember-apps").children
  end

  ##
  # Encapsulates an ember-cli app inside the source directory and provides
  # metadata about it, including the application name, directory, and the
  # list of middleman resources that represent the built ember application.
  class EmberApp

    ##
    # @!attribute app
    #  @return [Middleman::Application] the middleman application instance
    attr_reader :app

    ##
    # @!attribute dir
    #   @return [Pathname] the absolute path of the directory in which this
    #     ember app is located. E.g.
    #
    #       /usr/home/ubuntu/frontside.io/ember-apps/my-sweet-ember-app
    attr_reader :dir

    def initialize(app, dir)
      @app = app
      @dir = dir
    end

    ##
    # @!attribute package_json
    #   @return [Hash] the parsed package.json of this ember app
    def package_json
      JSON.parse File.read package_json_path
    end

    ##
    # @!attribute package_json
    #   @return [Pathname] the absolute path of this ember app's package.json
    def package_json_path
      @dir.join('package.json')
    end

    ##
    # The name of the ember application as defined in `package.json`. So, for
    # example, if the ember-apps/my-sweet-ember-app/package.json were to look
    # like:
    #
    #   {
    #     "name": "visualizations",
    #     "version": "1.0.0",
    #     // etc.....
    #   }
    #
    # Then the name would be "visualizations". This name is needed to determine
    # the file path of the app js and app css.
    #
    # @!attribute name
    #   @return [String] package name
    def name
      package_json["name"]
    end

    ##
    # Middleman resource for the application's `vendor.js`
    #
    # @!attribute vendor_js
    #   @return [Middleman::Sitemap::Resource]
    def vendor_js
      dist(/^vendor.*js$/)
    end

    ##
    # Middleman resource for the application's `app.js`. The actual file
    # location depends on the ember app's `name` attribute.
    #
    # @!attribute app_js
    #   @return [Middleman::Sitemap::Resource]
    def app_js
      dist(%r{^#{name}.*js$})
    end

    ##
    # Middleman resource for the application's `vendor.css`
    #
    # @!attribute vendor_css
    #   @return [Middleman::Sitemap::Resource]
    def vendor_css
      dist(/^vendor.*css$/)
    end

    ##
    # Middleman resource for the application's `app.css`. The actual file
    # location depends on the ember app's `name` attribute.
    #
    # @!attribute app_css
    #   @return [Middleman::Sitemap::Resource]
    def app_css
      dist(%r{^#{name}.*css$})
    end


    ##
    # The list of middleman resources that will be copied into place from this
    # ember application whenever the site is built. This includes all of the
    # css and javascript, but does not currently include any other assets like
    # images or sounds.
    #
    # @!attribute middleman_resources
    #   @return [Array<Middleman::Sitemap::Resources] ember app resources
    def middleman_resources
      [vendor_css, app_css, vendor_js, app_js]
    end

    ##
    # Have the distributable assets of this application been built?
    #
    # To find out, it checks if the `dist/assets` directory is created
    # within the ember app dir. If so, it assumes that somebody, somewhere
    # has built this application.
    #
    # @return [Boolean]
    def built?
      @dir.join('dist/assets').exist?
    end

    ##
    # Buld this ember app's distributable assets.
    #
    # This will run a build in production mode, which will fingerprint and
    # compress all of the javascript and css. If you want to make a debug build,
    # then build the application yourself with ember-cli using `ember build`,
    # and then MiddlemanEmber will skip the build on startup and just use the
    # assets that it finds.
    def build!
      puts  "Bulding Ember Application #{name} in #{@dir.basename}"
      Dir.chdir(@dir.to_s) do
        `npm install && bower install && npm run-script build -- -e production`
      end
    end

    private

    def dist(pattern)
      path = @dir.join('dist/assets').entries.find { |e| e.basename.to_s =~ pattern }
      middleman_resource path
    end

    def middleman_resource(path)
      destination_path = "ember-apps/#{@dir.basename}/#{path.basename}"
      source_path = Pathname('ember-apps').join(@dir.basename, 'dist/assets', path)
      source_file = source_path.realpath
      Middleman::Sitemap::Resource.new(@app.sitemap, source_path.to_s, source_file.to_s).tap do |res|
        res.destination_path = destination_path
      end
    end

  end
end

# Register extension with Middleman.
::Middleman::Extensions.register(:ember, MiddlemanEmber)
