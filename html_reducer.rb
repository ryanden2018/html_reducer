

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
    elem = self.new(self.tag_from_string(str))
    elem_attributes = str.gsub("<","")
      .gsub(">","")
      .gsub("/","")
      .strip
      .gsub(/\s*=\s*/,"=") # " = " => "="
      .split(/\s+/)
      .slice(1,str.length)
    elem_attributes.each do |attribute_str|
      quote = attribute_str[attribute_str.length-1]
      if !"'\"".include?(quote)
        quote = ""
      end
      key = attribute_str.split("=").first&.downcase
      value = attribute_str.split("=").last&.gsub(quote,"")
      elem.attributes[key] = value
    end
    elem
  end

  # copy with attributes but no contents
  def self.from_html_element(old_elem)
    elem = self.new(old_elem.tag)
    old_elem.attributes.each do |key,value|
      elem[key] = value
    end
  end

  def self.tag_from_string(str)
    str.gsub("<","")
      .gsub(">","")
      .gsub("/","")
      .split(/\s/)
      .first&.downcase
  end
end

def tag_in_stack(element_stack,tag)
  !!element_stack.map { |e| e.tag }.include?(tag)
end


# html_reducer(html_doc)
# html_doc is an HTML document in string form.
# The return value is a data structure which encodes
# the HTML document.
def html_reducer(html_doc)
  html_doc_chars = html_doc.strip.split("")

  self_closing_tags = ["area","base","br","col","embed","hr","img","input","link","meta","param","source","track","wbr","command","keygen","menuitem"]
  reopenable_tags = ["b","i","a","font","em","h1","h2","h3","h4","h5","h6","pre","strong","u"]
  nestable_tags = ["div"]

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
    if closing_script_match
      text = buffer.split(closing_script_regex).first.to_s.strip
      if text != ""
        element_stack.last.contents << text
      end
      buffer = ""
      element_stack.pop

    # closing style tag
    elsif closing_style_match
      text = buffer.split(closing_style_regex).first.to_s.strip
      if text != ""
        element_stack.last.contents << text
      end
      buffer = ""
      element_stack.pop

    # comment
    elsif comment_match
      contents = (element_stack.last&.contents) || reduction
      text = buffer.split(comment_regex).first.to_s.strip
      if text != ""
        contents << text
      end
      contents << comment_match.to_s

      buffer = ""

    # inside a script
    elsif tag_in_stack(element_stack,"script")
      # do nothing

    elsif tag_in_stack(element_stack,"style")
      # do nothing

    elsif buffer.include?("<!--")
      # do nothing

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
        # check whether nesting is possible
        if tag_in_stack(element_stack,tag.tag) && !nestable_tags.include(tag.tag)
          tmp_stack = []
          while tag_in_stack(element_stack,tag.tag)
            tmp = element_stack.pop
            if reopenable_tags.include?(tmp.tag)
              tmp_stack << tmp
            end
          end
          element_stack.push(tag)
          while tmp_stack.length > 0
            element_stack.push(HTML_element.from_html_element(tmp_stack.pop))
          end
        else
          element_stack.push(tag)
        end
      end

      buffer = ""

    # closing tag
    elsif closing_tag_match
      text = buffer.split(closing_tag_regex).first.to_s.strip
      contents = (element_stack.last&.contents) || reduction
      if text != ""
        contents << text
      end
      tag = HTML_element.tag_from_string(closing_tag_match.to_s)
      if tag_in_stack(element_stack, tag)
        tmp_stack = []
        while tag_in_stack(element_stack,tag)
          tmp = element_stack.pop
          if reopenable_tags.include?(tmp.tag)
            tmp_stack << tmp
          end
        end
        while tmp_stack.length > 0
          element_stack.push(HTML_element.from_html_element(tmp_stack.pop))
        end
      end
      buffer = ""

    # doctype (stack must be empty)
    elsif doctype_match
      text = buffer.split(doctype_regex).first.to_s.strip
      if text != ""
        reduction << text
      end
      reduction << doctype_match.to_s
      buffer = ""
    end
  end

  reduction
end