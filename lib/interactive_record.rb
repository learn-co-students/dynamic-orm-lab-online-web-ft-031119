require_relative "../config/environment.rb"
require 'active_support/inflector'
require "pry"

class InteractiveRecord
    def self.table_name
        # turns the class name into a lowercase string and pluralizes it
        self.to_s.downcase.pluralize
    end

    def self.column_names
        # makes a query to pull the table information
        sql = "pragma table_info('#{table_name}')"

        table_info = DB[:conn].execute(sql)
        column_names = []

        # iterates through the table info grabbing each of the column names and pushing them into the column_names array
        table_info.each do |row|
            column_names << row["name"]
        end
        
        # removes any empty values from the array
        column_names.compact
    end

    def initialize(options={})
        #  accepts a single argument as a hash with multiple values then iterates through the hash and creates scoped key, value pair associations within the object instance through initialize and self.send
        options.each do |property, value|
            self.send("#{property}=", value)
        end
    end

    def table_name_for_insert
        # returns the pluralized class table name
        self.class.table_name
    end

    def col_names_for_insert
        # takes the column names from the class and deletes the id column then joins them into a comma separated string
        self.class.column_names.delete_if { |col| col == "id"}.join(", ")
    end

    def values_for_insert
        values = []
        # turns each of the class column names into a string and pushes them into values array unless the send value is nil
        self.class.column_names.each do |col_name|

            values << "'#{send(col_name)}'" unless send(col_name).nil?
        end

        # Joins the elements in values array into a comma separated string
        values.join(", ")
    end

    def save
        sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"
        DB[:conn].execute(sql)
        @id = DB[:conn].execute("SELECT last_insert_rowid() FROM #{table_name_for_insert}")[0][0]
    end

    def self.find_by_name(name)
        sql = <<-SQL
            SELECT *
            FROM #{self.table_name}
            WHERE name = '#{name}'
            LIMIT 1
        SQL

        DB[:conn].execute(sql)
    end

    def self.find_by(hash)
        # takes the first value of the hash then assigns the value as a number if it is a number else assigns the value as a string
        # then uses sql to pull any matching database entries using interpolated values: table name, hash keys, and the assigned value from the first step 
        value = hash.values.first
        formatted_value = value.class == Fixnum ? value : "'#{value}'"
        sql = "SELECT * FROM #{self.table_name} WHERE #{hash.keys.first} = #{formatted_value}"
        DB[:conn].execute(sql)
    end
    

end