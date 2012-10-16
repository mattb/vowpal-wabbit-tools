require "vowpal-wabbit-tools/version"

module VowpalWabbit
  module TextProcessing
    def self.term_frequencies(examples)
      terms = {}
      terms.default = 0
      for example in examples
        for features in example[:features]
          for feature in features[:features]
            terms[feature[0]] += feature[1]
          end
        end
      end
      return terms
    end
    def self.rare_terms(examples, cutoff=5)
      self.term_frequencies(examples).select { |term, count| count < cutoff }.map { |term,count| term }
    end
    def self.remove_rare_terms(examples, cutoff=5)
      rare_terms = {}
      self.rare_terms(examples, cutoff).each { |term| rare_terms[term] = 1 }
      examples.map { |example|
        result = {}.merge(example)
        result[:features] = example[:features].map { |feature|
          f = {}
          f[:namespace] = feature[:namespace]
          f[:features] = feature[:features].select { |feature| !rare_terms.has_key? feature[0] }
          f
        }
        result
      }
    end
  end
  module Fileformat
    def self.parse_lines(lines)
      lines.map { |line| self.parse_line(line) }
    end

    def self.parse_line(line)
      result = {}
      sections = line.split(/\|/)

      header = sections.shift
      label, importance, tag = header.split(/ /)
      if importance.to_f == 0
        tag = importance
        importance = 1.0
      end
      result[:label] = label
      result[:importance] = importance.to_f
      result[:tag] = tag || ""
      if result[:tag].start_with? "'"
        result[:tag] = result[:tag].slice(1,result[:tag].size)
      end

      result[:features] = sections.map { |features|
        features_result = {}
        tokens = features.split(/ /)
        namespace = tokens.shift
        if namespace.size == 0
          features_result[:namespace] = [nil, 1]
        else
          term, value = namespace.split(/:/)
          if term.to_i.to_s == term
            term = term.to_i
          end
          if value.nil?
            value = 1
          else
            value = value.to_f
          end
          features_result[:namespace] = [term, value]
        end
        features_result[:features] = tokens.map { |token|
          term, value = token.split(/:/)
          if term.to_i.to_s == term
            term = term.to_i
          end
          if value.nil?
            value = 1
          else
            value = value.to_f
          end
          [term, value]
        }
        features_result
      }

      return result
    end

    def self.generate_line(data)
      if data.has_key? :tag
        tag = "'" + data[:tag]
      else
        tag = ""
      end

      line = "#{data[:label]} "
      if !data[:importance].nil? and data[:importance] != 1
        line += "#{data[:importance]} "
      end
      line += tag
      
      for feature in data[:features]
        line += "|"
        if feature[:namespace].nil? or feature[:namespace][0].nil?
          line += " "
        else
          if feature[:namespace][1] == 1
            line += "#{feature[:namespace][0]} "
          else
            line += "#{feature[:namespace][0]}:#{feature[:namespace][1]} "
          end
        end
        line += feature[:features].map { |f| f.join(":") }.join(" ")
        line += " "
      end
      line.strip
    end
  end
end
