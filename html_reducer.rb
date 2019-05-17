

class HTML_element
  attr_reader :tag
  attr_accessor :attributes, :contents
  
  def initialize(tag_name)
    @tag = tag_name
    @attributes = {}
    @contents = []
  end

  # create an HTML element with attributes from a string
  #  e.g. "<a href='someplace.htm' target='blank'>"
  def self.from_string(str)
    # FIXME
    self.new(
      str.gsub("<","").gsub(">","").split(/\s/).first&.downcase
    )
  end
end


# html_reducer(html_doc)
# html_doc is an HTML document in string form.
# The return value is a data structure which encodes
# the HTML document.
def html_reducer(html_doc)
  html_doc_chars = html_doc.strip.split("")

  self_closing_tags = ["area","base","br","col","embed","hr","img","input","link","meta","param","source","track","wbr","command","keygen","menuitem"]

  element_stack = [] # stack of open elements
  reduction = [] # results array
  buffer = ""

  while html_doc_chars.length > 0
    buffer << html_doc_chars.shift # get another char

    closing_script_regex = /<\/script\s*>\z/i
    closing_script_match = buffer.match(closing_script_regex)

    closing_style_regex = /<\/style\s*>\z/i
    closing_style_match = buffer.match(closing_style_regex)

    self_closing_tag_regex = /<[a-z][^>]*\/\s*>\z/
    self_closing_tag_match = buffer.match(self_closing_tag_regex)

    tag_regex = /<[a-z][^>]*>\z/i
    tag_match = buffer.match(tag_regex)

    closing_tag_regex = /<\/[a-z][^>]*>\z/i
    closing_tag_match = buffer.match(closing_tag_regex)

    doctype_regex = /<!doctype\s*[^>]*>\z/i
    doctype_match = buffer.match(doctype_regex)

    comment_regex = /<!--.*?-->\z/
    comment_match = buffer.match(comment_regex)

    # closing script tag
    if in_script && closing_script_match
      text = buffer.split(closing_script_regex).first.to_s.strip
      if text != ""
        element_stack.last.contents << text
      end
      buffer = ""
      element_stack.pop

    # closing style tag
    elsif in_css && closing_style_match
      text = buffer.split(closing_style_regex).first.to_s.strip
      if text != ""
        element_stack.last.contents << text
      end
      buffer = ""
      element_stack.pop

    # self closing tag containing /> (doesn't get pushed to the stack)
    elsif self_closing_tag_match
      text = buffer.split(self_closing_tag_regex).first.to_s.strip
      contents = (element_stack.last&.contents) || reduction
      if text != ""
        contents << text
      end
      contents << HTML_element.from_string(self_closing_tag_match.to_s)
      buffer = ""
    
    # tag
    elsif tag_match
      text = buffer.split(tag_regex).first.to_s.strip
      contents = (element_stack.last&.contents) || reduction
      if text != ""
        contents << text
      end
      tag = HTML_element.from_string(tag_match.to_s)

      contents << tag

      if !self_closing_tags.include?(tag.tag) # push to the stack
        element_stack.push(tag)
      end

      buffer = ""

    # closing tag
    elsif closing_tag_match
      text = buffer.split(closing_tag_regex).first.to_s.strip
      contents = (element_stack.last&.contents) || reduction
      if text != ""
        contents << text
      end
      element_stack.pop ### FIXME
      buffer = ""

    # doctype (stack must be empty)
    elsif doctype_match
      text = buffer.split(doctype_regex).first.to_s.strip
      if text != ""
        reduction << text
      end
      reduction << doctype_match.to_s
      buffer = ""

    # comment
    elsif comment_match
      contents = (element_stack.last&.contents) || reduction
      text = buffer.split(comment_regex).first.to_s.strip
      if text != ""
        contents << text
      end
      contents << comment_match.to_s

      buffer = ""
    end
  end

  reduction
end