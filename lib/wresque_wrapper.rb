require File.dirname(__FILE__) + '/wrapper/wrapper'

ActiveRecord::Base.extend(WresqueWrapper)
