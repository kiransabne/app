# encoding: utf-8
# frozen_string_literal: true
if Rails.env.development? || Rails.env.test?
  WickedPdf.config = if ENV["TRAVIS_CI"]
                       {
                         exe_path: "/usr/bin/wkhtmltopdf"
                       }
                     else
                       {
                         exe_path: `which wkhtmltopdf`.strip
                       }
                     end
end
