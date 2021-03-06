require File.expand_path(File.join(File.dirname(__FILE__), 'helper'))

class TestBasic < Test::Unit::TestCase

  def test_nil
    assert_nil Dryopteris.sanitize(nil)
  end
  
  def test_empty_string
    assert_equal "", Dryopteris.sanitize("")
  end

  def test_removal_of_illegal_tag
    html = <<-HTML
      following this there should be no jim tag
      <jim>jim</jim>
      was there?
    HTML
    sane = Nokogiri::HTML(Dryopteris.sanitize(html))
    assert sane.xpath("//jim").empty?
  end
  
  def test_removal_of_illegal_attribute
    html = "<p class=bar foo=bar abbr=bar />"
    sane = Nokogiri::HTML(Dryopteris.sanitize(html))
    node = sane.xpath("//p").first
    assert node.attributes['class']
    assert node.attributes['abbr']
    assert_nil node.attributes['foo']
  end
  
  def test_removal_of_illegal_url_in_href
    html = <<-HTML
      <a href='jimbo://jim.jim/'>this link should have its href removed because of illegal url</a>
      <a href='http://jim.jim/'>this link should be fine</a>
    HTML
    sane = Nokogiri::HTML(Dryopteris.sanitize(html))
    nodes = sane.xpath("//a")
    assert_nil nodes.first.attributes['href']
    assert nodes.last.attributes['href']
  end
  
  def test_css_sanitization
    html = "<p style='background-color: url(\"http://foo.com/\") ; background-color: #000 ;' />"
    sane = Nokogiri::HTML(Dryopteris.sanitize(html))
    assert_match(/#000/, sane.inner_html)
    assert_no_match(/foo\.com/, sane.inner_html)
  end

  def test_fragment_with_no_tags
    assert_equal "This fragment has no tags.", Dryopteris.sanitize("This fragment has no tags.")
  end

  def test_fragment_in_p_tag
    assert_equal "<p>This fragment is in a p.</p>", Dryopteris.sanitize("<p>This fragment is in a p.</p>")
  end

  def test_fragment_in_a_nontrivial_p_tag
    assert_equal "  \n<p>This fragment is in a p.</p>", Dryopteris.sanitize("  \n<p foo='bar'>This fragment is in a p.</p>")
  end

  def test_fragment_in_p_tag_plus_stuff
    assert_equal "<p>This fragment is in a p.</p>foo<strong>bar</strong>", Dryopteris.sanitize("<p>This fragment is in a p.</p>foo<strong>bar</strong>")
  end

  def test_fragment_with_text_nodes_leading_and_trailing
    assert_equal "text<p>fragment</p>text", Dryopteris.sanitize("text<p>fragment</p>text")
  end
  
  def test_fragment_with_body_tags
    # ignore second open body tag, use first close body tag, ignore everything after that
    assert_equal "textfragment", Dryopteris.sanitize("text<body>fragment</body>text")
  end

end
