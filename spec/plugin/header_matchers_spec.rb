require File.expand_path("spec_helper", File.dirname(File.dirname(__FILE__)))

describe "accept matcher" do
  it "should accept mimetypes and set response Content-Type" do
    app(:header_matchers) do |r|
      r.on :accept=>"application/xml" do
        response["Content-Type"]
      end
    end

    body("HTTP_ACCEPT" => "application/xml").must_equal  "application/xml"
    status.must_equal 404
  end
end

describe "header matcher" do
  # RODA3: undeprecate, and switch http-accept to accept
  deprecated "should match if header present" do
    app(:header_matchers) do |r|
      r.on :header=>"http-accept" do
        "bar"
      end
    end

    body("HTTP_ACCEPT" => "application/xml").must_equal  "bar"
    status("HTTP_HTTP_ACCEPT" => "application/xml").must_equal 404
    status.must_equal 404
  end

  it "should yield the header value" do
    app(:header_matchers) do |r|
      r.on :header=>"accept" do |v|
        "bar-#{v}"
      end
    end

    app.opts[:header_matcher_prefix] = true
    body("HTTP_ACCEPT" => "application/xml").must_equal  "bar-application/xml"
    status.must_equal 404
  end

  # RODA3: Remove
  it "should automatically use HTTP prefix for headers if :header_matcher_prefix is set" do
    app(:bare) do
      plugin :header_matchers
      opts[:header_matcher_prefix] = true
      route do |r|
        r.on :header=>"accept" do |v|
          "bar-#{v}"
        end
      end
    end

    body("HTTP_ACCEPT" => "application/xml").must_equal  "bar-application/xml"
    status("ACCEPT"=>"application/xml").must_equal 404
  end
end

describe "host matcher" do
  it "should match a host" do
    app(:header_matchers) do |r|
      r.on :host=>"example.com" do
        "worked"
      end
    end

    body("HTTP_HOST" => "example.com").must_equal 'worked'
    status("HTTP_HOST" => "foo.com").must_equal 404
  end

  # RODA3: switch deprecated to it
  deprecated "should match a host with a regexp" do
    app(:header_matchers) do |r|
      r.on :host=>/example/ do
        "worked"
      end
    end

    body("HTTP_HOST" => "example.com").must_equal 'worked'
    status("HTTP_HOST" => "foo.com").must_equal 404
  end

  it "doesn't yield host if given a string" do
    app(:header_matchers) do |r|
      r.on :host=>"example.com" do |*args|
        args.size.to_s
      end
    end

    body("HTTP_HOST" => "example.com").must_equal '0'
  end

  deprecated "doesn't yield host if passed a regexp" do
    app(:header_matchers) do |r|
      r.on :host=>/\A(.*)\.example\.com\z/ do |*m|
        m.empty? ? '0' : m[0]
      end
    end

    body("HTTP_HOST" => "foo.example.com").must_equal '0'
  end

  # RODA3: Remove :host_matcher_captures setting
  it "yields host if passed a regexp and opts[:host_matcher_captures] is set" do
    app(:header_matchers) do |r|
      r.on :host=>/\A(.*)\.example\.com\z/ do |*m|
        m.empty? ? '0' : m[0]
      end
    end

    app.opts[:host_matcher_captures] = true
    body("HTTP_HOST" => "foo.example.com").must_equal 'foo'
  end

  # RODA3: Remove
  it "doesn't yields host if passed a string and opts[:host_matcher_captures] is set" do
    app(:header_matchers) do |r|
      r.on :host=>'example.com' do |*m|
        m.empty? ? '0' : m[0]
      end
    end

    body("HTTP_HOST" => "example.com").must_equal '0'
    app.opts[:host_matcher_captures] = true
    body("HTTP_HOST" => "example.com").must_equal '0'
  end
end

describe "user_agent matcher" do
  it "should accept pattern and match against user-agent" do
    app(:header_matchers) do |r|
      r.on :user_agent=>/(chrome)(\d+)/ do |agent, num|
        "a-#{agent}-#{num}"
      end
    end

    body("HTTP_USER_AGENT" => "chrome31").must_equal  "a-chrome-31"
    status.must_equal 404
  end
end

