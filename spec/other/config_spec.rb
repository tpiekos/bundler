require "spec_helper"

describe ".bundle/config" do
  before :each do
    gemfile <<-G
      source "file://#{gem_repo1}"
      gem "rack", "1.0.0"
    G
  end

  describe "BUNDLE_APP_CONFIG" do
    it "can be moved with an environment variable" do
      ENV['BUNDLE_APP_CONFIG'] = tmp('foo/bar').to_s
      bundle "install --path vendor/bundle"

      expect(bundled_app('.bundle')).not_to exist
      expect(tmp('foo/bar/config')).to exist
      should_be_installed "rack 1.0.0"
    end

    it "can provide a relative path with the environment variable" do
      FileUtils.mkdir_p bundled_app('omg')
      Dir.chdir bundled_app('omg')

      ENV['BUNDLE_APP_CONFIG'] = "../foo"
      bundle "install --path vendor/bundle"

      expect(bundled_app(".bundle")).not_to exist
      expect(bundled_app("../foo/config")).to exist
      should_be_installed "rack 1.0.0"
    end

    it "removes environment.rb from BUNDLE_APP_CONFIG's path" do
      FileUtils.mkdir_p(tmp('foo/bar'))
      ENV['BUNDLE_APP_CONFIG'] = tmp('foo/bar').to_s
      bundle "install"
      FileUtils.touch tmp('foo/bar/environment.rb')
      should_be_installed "rack 1.0.0"
      expect(tmp('foo/bar/environment.rb')).not_to exist
    end
  end

  describe "global" do
    before(:each) { bundle :install }

    it "is the default" do
      bundle "config foo global"
      run "puts Bundler.settings[:foo]"
      expect(out).to eq("global")
    end

    it "can also be set explicitly" do
      bundle "config --global foo global"
      run "puts Bundler.settings[:foo]"
      expect(out).to eq("global")
    end

    it "has lower precedence than local" do
      bundle "config --local  foo local"

      bundle "config --global foo global"
      expect(out).to match(/Your application has set foo to "local"/)

      run "puts Bundler.settings[:foo]"
      expect(out).to eq("local")
    end

    it "has lower precedence than env" do
      begin
        ENV["BUNDLE_FOO"] = "env"

        bundle "config --global foo global"
        expect(out).to match(/You have a bundler environment variable for foo set to "env"/)

        run "puts Bundler.settings[:foo]"
        expect(out).to eq("env")
      ensure
        ENV.delete("BUNDLE_FOO")
      end
    end

    it "can be deleted" do
      bundle "config --global foo global"
      bundle "config --delete foo"

      run "puts Bundler.settings[:foo] == nil"
      expect(out).to eq("true")
    end

    it "warns when overriding" do
      bundle "config --global foo previous"
      bundle "config --global foo global"
      expect(out).to match(/You are replacing the current global value of foo/)

      run "puts Bundler.settings[:foo]"
      expect(out).to eq("global")
    end

    it "expands the path at time of setting" do
      bundle "config --global local.foo .."
      run "puts Bundler.settings['local.foo']"
      expect(out).to eq(File.expand_path(Dir.pwd + "/.."))
    end
  end

  describe "local" do
    before(:each) { bundle :install }

    it "can also be set explicitly" do
      bundle "config --local foo local"
      run "puts Bundler.settings[:foo]"
      expect(out).to eq("local")
    end

    it "has higher precedence than env" do
      begin
        ENV["BUNDLE_FOO"] = "env"
        bundle "config --local foo local"

        run "puts Bundler.settings[:foo]"
        expect(out).to eq("local")
      ensure
        ENV.delete("BUNDLE_FOO")
      end
    end

    it "can be deleted" do
      bundle "config --local foo local"
      bundle "config --delete foo"

      run "puts Bundler.settings[:foo] == nil"
      expect(out).to eq("true")
    end

    it "warns when overriding" do
      bundle "config --local foo previous"
      bundle "config --local foo local"
      expect(out).to match(/You are replacing the current local value of foo/)

      run "puts Bundler.settings[:foo]"
      expect(out).to eq("local")
    end

    it "expands the path at time of setting" do
      bundle "config --local local.foo .."
      run "puts Bundler.settings['local.foo']"
      expect(out).to eq(File.expand_path(Dir.pwd + "/.."))
    end
  end
end
