require 'parallel'

require_relative 'document'

class SemanticFieldGenerator
  attr_reader :tf, :tfidf

  def initialize(data_source)
    @data_source = data_source
  end

  def process()
    @tf = Parallel.map(@data_source) do |document|
      tf_map(document)
    end.reduce do |final, current|
      tf_reduce(final, current)
    end

    @tfidf = Parallel.map(@tf) do |word, documents|
      idf = 1 + Math.log10(@tf.size / documents.size)

      tfidf_partial = {}
      tfidf_partial[word] = Hash.new 0.0
      documents.each do |document, score|
        tfidf_partial[word][document] = score * idf
      end

      tfidf_partial
    end.reduce({}) do |final, current|
      final[current.keys.first] = current[current.keys.first]
      final
    end

    p @tfidf

    p cos(@tfidf["test"], @tfidf["tutu"])
  end

  private

  def tokenize(text)
    text.split /[ "'«»;,.:?!\n]/
  end

  def tf_map(document)
    tf_partial = {}

    tokens = tokenize(document.content)

    tokens.each do |token|
      tf_partial[token] ||= Hash.new 0
      tf_partial[token][document.name] += 1.0
    end

    tf_partial.keys.each do |word|
      tf_partial[word][document.name] /= tokens.size
    end

    tf_partial
  end

  def tf_reduce(tf_final, tf_partial)
    tf_partial.each do |word, name|
      tf_final[word] = Hash.new 0 unless tf_final[word]
      tf_final[word].merge! name
    end

    tf_final
  end

  def cos(vec0, vec1)
    docs = vec0.keys | vec1.keys

    scalar = 0.0
    docs.each do |doc|
      scalar += vec0[doc] * vec1[doc]
    end

    vec0_norm = vec0.reduce(0.0) do |f, e|
      f += e[1] ** 2
      f
    end
    vec0_norm = Math.sqrt(vec0_norm)

    vec1_norm = vec1.reduce(0.0) do |f, e|
      f += e[1] ** 2
      f
    end
    vec1_norm = Math.sqrt(vec1_norm)

    scalar / (vec0_norm * vec1_norm)
  end
end

a = []
a << Document.new("bonjour bonjour test titi toto")
a << Document.new("bonjour tata tutu tutu")

i = SemanticFieldGenerator.new a
i.process
p i.tfidf
