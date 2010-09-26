require File.expand_path(File.dirname(__FILE__) + '/spec_helper')

rebuild_sql
describe "Straitjacket" do
  context "with a sample" do
    before do
      @jacket = Straitjacket.new do
        on :users do
          name_gt_1.check "LENGTH(name) > 1"
          dog1.foreign_key :dog_id, :references => :dogs, :on => :id
          column :dog_id, "dog_id > 0"
        end
      end
    end
    
    it "should have three statements" do
      @jacket.constraints.length.should == 3
    end
    
    it "should have unique names" do
      proc {
        @jacket.on(:users).name_gt_1.check("something else")
      }.should raise_error(Straitjacket::Error)
    end
    
    context "first statement" do
      before do 
        @first = @jacket.constraints.first
      end
      
      it "should be named" do
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
      
      it "should have made stuff work" do
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
