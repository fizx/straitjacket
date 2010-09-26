require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

# Note these tests are stateful in the db.
rebuild_sql
describe "Straitjacket" do
  context "with a sample" do
    before do
      @jacket = Straitjacket.new do
        on :users do
          name_gt_1.check "LENGTH(name) > 1"
          dog1.foreign_key :dog_id, :references => :dogs, :on => :id
          deprecated :foo 
          another.deprecated
        end
      end
    end
    
    it "should have correct number of constraints" do
      @jacket.constraints.length.should == 5
    end
    
    it "should have unique names" do
      proc {
        @jacket.on(:users).name_gt_1.check("something else")
      }.should raise_error(Straitjacket::Error)
    end
    
    describe "#apply" do
      it "should apply all" do
        conn = mock
        @jacket.constraints.each do |c|
          c.should_receive(:apply).with(conn)
        end
        @jacket.apply(conn)
      end
    end
    
    context "deprecated" do
      it "should remove a key" do
        conn = mock
        conn.should_receive(:exec).with(%[ALTER TABLE \"users\" DROP CONSTRAINT \"another\"])
        @jacket.constraints.last.apply(conn)
      end
    end
    
    context "foreign key" do
      before do 
        @key = @jacket.constraints[1]
      end
      
      it "should generate sql" do
        @key.sql.should == %[ALTER TABLE "users" ADD CONSTRAINT "dog1" FOREIGN KEY ("dog_id") REFERENCES "dogs"("id") MATCH FULL]
      end
        
      it "should be able to apply sql" do
        @key.apply($conn)
      end

      it "should be able to reapply sql" do
        @key.apply($conn)
      end

    end
    
    context "check constraint" do
      before do 
        @first = @jacket.constraints.first
      end
      
      it "should be named" do
        rebuild_sql
        @first.name.should == "name_gt_1"
      end
      
      it "should be a check" do
        @first.should be_a(Straitjacket::CheckConstraint)
      end
      
      it "should generate sql" do
        @first.sql.should == %[ALTER TABLE "users" ADD CONSTRAINT "name_gt_1" CHECK (LENGTH(name) > 1)]
      end
      
      it "should be able to apply sql" do
        @first.apply($conn)
      end
      
      it "should be enforced" do
        User.create! :name => "Joe", :dog_id => 1
        proc {
          User.create! :name => "e", :dog_id => 1
        }.should raise_error(ActiveRecord::StatementInvalid)
      end
      
      it "should not be applyable to an invalid db" do
        @first.content = "LENGTH(name) > 10"
        proc {
          @first.apply($conn)
        }.should raise_error(PGError)
      end
      
      it "should be reapplyable/adjustable" do
        User.delete_all
        @first.content = "LENGTH(name) > 10"
        @first.apply($conn)
        proc {
          User.create! :name => "Johnny", :dog_id => 1
        }.should raise_error(ActiveRecord::StatementInvalid)
      end
    end
  end
end
