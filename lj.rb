require 'uri'
require 'net/http'
require 'nokogiri'
require 'date'
require 'pry'

class LJparse
  attr_accessor :root, :k

  def initialize(root)
    @root = root
    @k = 0
  end

  def parse_to_jekyll(subject_link)
    uri = URI(subject_link)
    source = Net::HTTP.get(uri)
    html_doc = Nokogiri::HTML(source)
    datetime = html_doc.xpath("//div[@class='datesubject']/div[@class='date']")
    post_date = DateTime.parse(datetime.text)
    File.open("lj/#{post_date.strftime('%Y-%m-%d-%H-%M-%S')}.markdown", 'w') do |f|
      entry_text = html_doc.xpath("//div[@class='entry_text']")
      subject = html_doc.xpath("//div[@class='datesubject']/div[@class='subject']")
      ljtags = entry_text.xpath("//div[@class='ljtags']")
      tags = entry_text.xpath("//div[@class='ljtags']/a")
      ljtags.first.remove if ljtags.count > 0
      jekyll_tag = tags.map { |el| ", #{el.text}"}.join
      f.write("---
layout: post
title:  \"#{subject.text}\"
date:   #{post_date.strftime('%Y-%m-%d %H:%M:%S')}
categories: lj#{jekyll_tag}
---

#{entry_text}"
)
    end
    @k += 1
    puts(k)
  end

  def iter_years(year)
    (1..12).step do |i|
      uri = URI("#{root}/#{year}/#{'%02d' % i}/")
      source = Net::HTTP.get(uri)
      html_doc = Nokogiri::HTML(source)
      subjects = html_doc.xpath("//div[@class='subcontent']/div/dl/dd/a/@href")
      subjects.each do |subject|
        parse_to_jekyll(subject)
      end
      #break
    end
  end

  def import_lj
    uri = URI("#{root}/calendar")
    source = Net::HTTP.get(uri)
    html_doc = Nokogiri::HTML(source)
    years = html_doc.xpath("//ul[@class='year']/li")

    return "Years cant find " if 0 == years.count
    
    years.each do |year|
      iter_years(year.text)
    end
  end
end

import_tool = LJparse.new('http://vgulaev.livejournal.com')
import_tool.import_lj

puts('hello')