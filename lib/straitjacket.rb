class Straitjacket
  class Error < ::RuntimeError
  end
  
  class Proxy
    
    def initialize(inner, table)
      @inner = inner
      @table = table
    end
    
    def method_missing(method)
      @name = method
      self
    end
    
    def deprecated(*names)
      (names << @name).each do |name|
        add_constraint DeprecatedConstraint.new(@table, name)
      end
    end
    
    def check(statement, options = {})
      add_constraint CheckConstraint.new(@table, statement, named(options))
    end

    def foreign_key(column, options = {})
      add_constraint ForeignKeyConstraint.new(@table, nil, named(options).merge(:column => column))
    end
    
  private
    def add_constraint(constraint)
      if @inner.constraints.any?{|c| c.name == constraint.name}
        raise Error, "#{c.name} already exists"
      else
        @inner.constraints << constraint
      end
    end

    def named(hash)
      if @name
        hash = hash.dup
        hash[:name] = @name
        @name = nil
      end
      hash
    end
  end
  
  attr_reader :constraints
  
  def initialize(&block)
    @constraints = []
    @names = {}
    instance_eval(&block) if block
  end
  
  def apply(conn)
    constraints.map{|c| c.apply(conn) }
  end
    
  def on(table, &block)
    proxy = Proxy.new(self, table)
    proxy.instance_eval(&block) if block
    proxy
  end
    
  class Constraint
    attr_accessor :name, :table, :sql, :content, :options, :column
    
    def initialize(table, content, options)
      @column = options[:column]
      @name = (options[:name] || default_name(table, options[:column])).to_s
      @table = table
      @content = content
      @options = options
    end
    
    def apply(conn)
      conn.exec(sql)
    rescue PGError => e
      if e.message =~ /already exists/
        conn.exec(%[ALTER TABLE "#{table}" DROP CONSTRAINT "#{name}"])
        retry
      else
        raise
      end
    end
    
    def sql; raise "abstract"; end
    
  private
    def default_name(table, column)
      [table, column].compact.join("_")
    end
  end
  
  class DeprecatedConstraint < Constraint
    def initialize(table, name)
      @table = table
      @name = name
    end
    
    def sql
      %[ALTER TABLE "#{table}" DROP CONSTRAINT "#{name}"]
    end
    
    def apply(conn)
      conn.exec(sql)
    rescue
      false
    end
  end
  
  class ForeignKeyConstraint < Constraint
    def sql
      more = ""
      if options[:references]
        on = options[:on] ? %[("#{options[:on]}")] : ""
        more = %[REFERENCES "#{options[:references]}"#{on}]
      end
      %[ALTER TABLE "#{table}" ADD CONSTRAINT "#{name}" FOREIGN KEY ("#{column}") #{more} MATCH FULL]
    end
  end
  
  class CheckConstraint < Constraint
    def sql
      %[ALTER TABLE "#{table}" ADD CONSTRAINT "#{name}" CHECK (#{@content})]
    end
  end
end