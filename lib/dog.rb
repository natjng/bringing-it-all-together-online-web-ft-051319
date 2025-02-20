require 'pry'

class Dog
    attr_accessor :id, :name, :breed

    def initialize(id: nil, name:, breed:)
        @id = id
        @name = name
        @breed = breed
    end

    def self.create_table
        sql = <<-SQL
        CREATE TABLE IF NOT EXISTS dogs (
            id INTEGER PRIMARY KEY,
            name TEXT, 
            breed TEXT
        );
        SQL
        DB[:conn].execute(sql)
    end

    def self.drop_table
        sql = "DROP TABLE IF EXISTS dogs;"
        DB[:conn].execute(sql)
    end

    def self.new_from_db(row)
        self.new(id: row[0], name: row[1], breed: row[2])
    end

    def self.find_by_name(name)
        sql = "SELECT * FROM dogs WHERE name = ?;"
        DB[:conn].execute(sql, name).map{|row| self.new_from_db(row)}.first
    end

    def save
        if self.id
            self.update
        else
            sql = <<-SQL
            INSERT INTO dogs (name, breed) 
            VALUES (?,?); 
            SQL
            DB[:conn].execute(sql, self.name, self.breed)
            @id = DB[:conn].execute("SELECT last_insert_rowid() FROM dogs;")[0][0]
        end
        self
    end

    def self.create(name:, breed:)
        dog = self.new(name: name, breed: breed)
        dog.save
        dog
    end

    def update
        DB[:conn].execute("UPDATE dogs SET name = ?, breed = ? WHERE id =?;", self.name, self.breed, self.id)
    end

    def self.find_by_id(id)
        row = DB[:conn].execute("SELECT * FROM dogs WHERE id = ?;", id).first
        self.new_from_db(row)
        # self.new(id: row[0], name: row[1], breed: row[2])
    end

    def self.find_or_create_by(name:, breed:)
        dog = DB[:conn].execute("SELECT * FROM dogs WHERE name = ? AND breed =?;", name, breed)
        if !dog.empty?
            dog_data = dog.first
            dog = self.new_from_db(dog_data)
        else
            dog = self.create(name: name, breed: breed)
        end
        dog
    end

end