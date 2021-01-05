require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    return @columns if @columns
    clms = DBConnection.execute2(<<-SQL).first
      SELECT
        *
      FROM
        #{self.table_name}
      LIMIT
        0
    SQL

    #cols.map!(&:to_sym)    ####also possible
    #@columns = cols

    list = []
    clms.each do |clm|
      list << clm.to_sym
    end
    @columns = list
    
  end

  def self.finalize!

    self.columns.each do |column|
      define_method(column) do 
        instance_variable_get("@#{column}") 
          self.attributes[column]
      end

      define_method("#{column}=") do |value|
          self.attributes[column] = value
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name || self.name.underscore.pluralize
  end

  def self.all

    results = DBConnection.execute(<<-SQL)
      SELECT
        #{self.table_name}.*
      FROM
        #{self.table_name}

    SQL
    
    parse_all(results)

  end

  def self.parse_all(results)
    results.map { |result| self.new(result) }
  end

  def self.find(id)

    results = DBConnection.execute(<<-SQL, id)
      SELECT
        #{self.table_name}.*
      FROM
        #{self.table_name}
      WHERE 
        #{self.table_name}.id = ?
    SQL
    parse_all(results).first
  end

  def initialize(params = {})
    
    params.each do |attr_name, value|
      attr_name = attr_name.to_sym
      if self.class.columns.include?(attr_name)
        self.send("#{attr_name}=", value)
      else
        raise "unknown attribute '#{attr_name}'"
      end
    end

  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    #@attributes.values
    self.class.columns.map { |attr| self.send(attr) }
  end

  def insert
    
    columns = self.class.columns.drop(1)
    col_names = columns.map(&:to_s).join(", ")
    n = columns.count
    question_marks = (["?"] * n).join(", ")

    DBConnection.execute(<<-SQL, *attribute_values.drop(1))
      INSERT INTO
        #{self.class.table_name} (#{col_names})
      VALUES
        (#{question_marks})
    SQL

    self.id = DBConnection.last_insert_row_id
  end

  def update
    ######
    set_line = self.class.columns
      .map { |attr_name|  "#{attr_name} = ?"}.join(", ")

    DBConnection.execute(<<-SQL, *attribute_values, id)
      UPDATE
        #{self.class.table_name}
      SET
        #{set_line}
      WHERE
        #{self.class.table_name}.id = ?
    SQL
  end

  def save
    id.nil? ? self.insert : self.update
  end
end
