class Document
  attr_accessor :content, :name

  @@doc_id = 0

  def initialize(content)
    @content = content
    @@doc_id += 1
    @name = "doc" + @@doc_id.to_s
  end
end
