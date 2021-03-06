require "spec_helper"

describe Diaspora::Shareable do
  describe "scopes" do
    describe ".all_public" do
      it "includes all public posts" do
        post1 = FactoryGirl.create(:status_message, author: alice.person, public: true)
        post2 = FactoryGirl.create(:status_message, author: bob.person, public: true)
        post3 = FactoryGirl.create(:status_message, author: eve.person, public: true)
        expect(Post.all_public.map(&:id)).to match_array([post1.id, post2.id, post3.id])
      end

      it "doesn't include any private posts" do
        FactoryGirl.create(:status_message, author: alice.person, public: false)
        FactoryGirl.create(:status_message, author: bob.person, public: false)
        FactoryGirl.create(:status_message, author: eve.person, public: false)
        expect(Post.all_public.map(&:id)).to eq([])
      end
    end

    context "having multiple objects with equal db IDs" do
      before do
        # Determine the next database key ID, free on both Photo and StatusMessage
        id = [Photo, StatusMessage].map {|model| model.maximum(:id).try(:next).to_i }.push(1).max

        alice.post(:status_message, id: id, text: "I'm #{alice.username}", to: alice.aspects.first.id, public: false)
        alice.post(:photo, id: id, user_file: uploaded_photo, to: alice.aspects.first.id, public: false)
        expect(StatusMessage.where(id: id)).to exist
        expect(Photo.where(id: id)).to exist
      end

      {with_visibility: ShareVisibility, with_aspects: AspectVisibility}.each do |method, visibility_class|
        describe ".#{method}" do
          it "includes only object of a right type" do
            [Photo, Post].each do |klass|
              expect(klass.send(method).where(visibility_class.arel_table[:shareable_type].eq(klass.to_s)).count)
                .not_to eq(0)
              expect(klass.send(method).where.not(visibility_class.arel_table[:shareable_type].eq(klass.to_s)).count)
                .to eq(0)
            end
          end
        end
      end
    end
  end
end
