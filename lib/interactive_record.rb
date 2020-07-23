require_relative "../config/environment.rb"
require 'active_support/inflector'
require 'pry'

class InteractiveRecord

  def self.table_name
    self.to_s.downcase.pluralize
  end

  def self.column_names
    DB[:conn].results_as_hash = true
    sql = "PRAGMA table_info('#{table_name}')"
    table_info = DB[:conn].execute(sql)
    column_names = []
    table_info.each{|column| column_names << column["name"]}
    column_names.compact
  end
  # => ***attr_accessor***
  self.column_names.each{|col_name| attr_accessor col_name.to_sym}

  def initialize(attributes={})
    attributes.each{|key,value| self.send("#{key}=",value)}
  end

  def col_names_for_insert
    self.class.column_names.delete_if {|col| col == "id"}.join(", ")
  end

  def values_for_insert
    values = []
    self.class.column_names.each do |col_name|
      values << "'#{send(col_name)}'" unless send(col_name).nil?
    end
    values.join(", ")
  end

  def table_name_for_insert
    self.class.table_name
  end

  def save
    sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"
    DB[:conn].execute(sql)
    @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
  end

  def self.create(attributes)
    obj = self.class.new(attributes)
    obj.save
    obj
  end

  def self.new_from_db(attributes)
    self.new(attributes)
  end

  def self.find_by_name(name)
    sql = <<-SQL
    SELECT * FROM #{table_name} WHERE name = ?
    SQL
    DB[:conn].execute(sql,name)
  end

  def self.find_by(attr_hash)
    key = attr_hash.keys.first
    value = attr_hash.values.first
    formatted_value = value.class == Fixnum ? value : "'#{value}'"
    sql = "SELECT * FROM #{self.table_name} WHERE #{key} = #{formatted_value}"
    DB[:conn].execute(sql)
  end

end
